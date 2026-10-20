package com.bakhi.dropit.t01_lifecycle

import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ProcessLifecycleOwner
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Spike T-01 — kênh native Android.
 * Chỉ dùng tín hiệu của CHÍNH app + trạng thái màn hình (BR-34, NFR-P01).
 * KHÔNG dùng UsageStatsManager / quyền PACKAGE_USAGE_STATS, không cảm biến.
 */
class MainActivity : FlutterActivity() {
    private var sink: EventChannel.EventSink? = null
    private var watching = false
    private val main = Handler(Looper.getMainLooper())

    private val pm by lazy { getSystemService(Context.POWER_SERVICE) as PowerManager }
    private val km by lazy { getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager }

    private fun send(event: String, extra: Map<String, Any?> = emptyMap()) {
        if (!watching) return
        val m = HashMap<String, Any?>()
        m["event"] = event
        m["nativeUptimeMs"] = SystemClock.elapsedRealtime()
        m["nativeWallMs"] = System.currentTimeMillis()
        m["interactive"] = pm.isInteractive
        m["keyguardLocked"] = km.isKeyguardLocked
        m.putAll(extra)
        main.post { sink?.success(m) }
    }

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(c: Context?, i: Intent?) {
            when (i?.action) {
                Intent.ACTION_SCREEN_OFF -> send("screen_off")
                Intent.ACTION_SCREEN_ON -> send("screen_on")
                Intent.ACTION_USER_PRESENT -> send("user_present")
            }
        }
    }

    private val processObserver = object : DefaultLifecycleObserver {
        override fun onStart(owner: LifecycleOwner) = send("process_start")
        override fun onStop(owner: LifecycleOwner) = send("process_stop")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        EventChannel(messenger, "dropit/lifecycle_events").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, events: EventChannel.EventSink?) { sink = events }
                override fun onCancel(args: Any?) { sink = null }
            })
        MethodChannel(messenger, "dropit/lifecycle").setMethodCallHandler { call, result ->
            when (call.method) {
                "startWatching" -> { startWatching(); result.success(true) }
                "stopWatching" -> { stopWatching(); result.success(true) }
                "snapshot" -> result.success(mapOf(
                    "interactive" to pm.isInteractive,
                    "keyguardLocked" to km.isKeyguardLocked))
                else -> result.notImplemented()
            }
        }
    }

    // Chỉ đăng ký khi đang ghi phiên (BR-05, NFR-P02).
    private fun startWatching() {
        if (watching) return
        watching = true
        val f = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        registerReceiver(screenReceiver, f)
        ProcessLifecycleOwner.get().lifecycle.addObserver(processObserver)
        send("watching_started")
    }

    private fun stopWatching() {
        if (!watching) return
        send("watching_stopped")
        watching = false
        try { unregisterReceiver(screenReceiver) } catch (_: Exception) {}
        ProcessLifecycleOwner.get().lifecycle.removeObserver(processObserver)
    }

    override fun onDestroy() {
        stopWatching()
        super.onDestroy()
    }
}

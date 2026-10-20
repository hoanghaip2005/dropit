package com.bakhi.dropit.focus_lifecycle

import android.app.KeyguardManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ProcessLifecycleOwner
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * focus_lifecycle — kênh native Android (tách từ spike T-01).
 * Chỉ dùng tín hiệu của CHÍNH app + trạng thái màn hình (BR-34, NFR-P01).
 * KHÔNG dùng UsageStatsManager / quyền PACKAGE_USAGE_STATS, không cảm biến.
 * Receiver và observer chỉ đăng ký khi phiên đang ghi (NFR-P02).
 */
class FocusLifecyclePlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var context: Context
    private var method: MethodChannel? = null
    private var events: EventChannel? = null
    private var sink: EventChannel.EventSink? = null
    private var watching = false
    private val main = Handler(Looper.getMainLooper())

    private val pm by lazy { context.getSystemService(Context.POWER_SERVICE) as PowerManager }
    private val km by lazy { context.getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        method = MethodChannel(binding.binaryMessenger, "dropit/focus_lifecycle").also {
            it.setMethodCallHandler(this)
        }
        events = EventChannel(binding.binaryMessenger, "dropit/focus_lifecycle/events").also {
            it.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(args: Any?, s: EventChannel.EventSink?) { sink = s }
                override fun onCancel(args: Any?) { sink = null }
            })
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        stopWatching()
        method?.setMethodCallHandler(null)
        events?.setStreamHandler(null)
        method = null
        events = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startWatching" -> { startWatching(); result.success(true) }
            "stopWatching" -> { stopWatching(); result.success(true) }
            "snapshot" -> result.success(mapOf(
                "interactive" to pm.isInteractive,
                "keyguardLocked" to km.isKeyguardLocked))
            else -> result.notImplemented()
        }
    }

    private fun send(event: String) {
        if (!watching) return
        val m = HashMap<String, Any?>()
        m["event"] = event
        m["nativeUptimeMs"] = SystemClock.elapsedRealtime()
        m["interactive"] = pm.isInteractive
        m["keyguardLocked"] = km.isKeyguardLocked
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

    private fun startWatching() {
        if (watching) return
        watching = true
        val f = IntentFilter().apply {
            addAction(Intent.ACTION_SCREEN_OFF)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_USER_PRESENT)
        }
        if (Build.VERSION.SDK_INT >= 33) {
            context.registerReceiver(screenReceiver, f, Context.RECEIVER_NOT_EXPORTED)
        } else {
            context.registerReceiver(screenReceiver, f)
        }
        main.post { ProcessLifecycleOwner.get().lifecycle.addObserver(processObserver) }
        send("watching_started")
    }

    private fun stopWatching() {
        if (!watching) return
        send("watching_stopped")
        watching = false
        try { context.unregisterReceiver(screenReceiver) } catch (_: Exception) {}
        main.post { ProcessLifecycleOwner.get().lifecycle.removeObserver(processObserver) }
    }
}

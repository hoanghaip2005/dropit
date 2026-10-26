package com.bakhi.dropit.dropit

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel("dropit_events", "Thông báo DropIt!", NotificationManager.IMPORTANCE_HIGH)
            channel.description = "Nhắc phiên và cập nhật hoạt động"
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }
}

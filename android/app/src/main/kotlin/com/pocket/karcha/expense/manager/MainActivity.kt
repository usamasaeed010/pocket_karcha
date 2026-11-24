package com.pocket.karcha.expense.manager

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createOrderChannel()
    }

    /** High-importance channel so a new-order push rings and pops up. */
    private fun createOrderChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        val channel = NotificationChannel(
            ORDER_CHANNEL_ID,
            getString(R.string.order_channel_name),
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = getString(R.string.order_channel_description)
        }
        manager.createNotificationChannel(channel)
    }

    private companion object {
        /** Must match the Cloud Function and the manifest default. */
        const val ORDER_CHANNEL_ID = "orders"
    }
}

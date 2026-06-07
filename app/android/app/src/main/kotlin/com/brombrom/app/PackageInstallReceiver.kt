package com.brombrom.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri

class PackageInstallReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_PACKAGE_ADDED) {
            val data: Uri? = intent.data
            val packageName = data?.schemeSpecificPart
            if (packageName == "net.osmand" || packageName == "net.osmand.plus") {
                try {
                    val launchIntent = Intent(context, MainActivity::class.java).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                    }
                    context.startActivity(launchIntent)
                } catch (e: Exception) {
                    // Fallback or log if background activity launch is blocked
                }
            }
        }
    }
}

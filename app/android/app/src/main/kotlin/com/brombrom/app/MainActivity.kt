package com.brombrom.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.pm.PackageManager
import android.content.Intent

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.brombrom.app/package_check"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "isPackageInstalled") {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    val installed = isPackageInstalled(packageName)
                    result.success(installed)
                } else {
                    result.error("BAD_ARGUMENTS", "Package name was null", null)
                }
            } else if (call.method == "openPackage") {
                val packageName = call.argument<String>("packageName")
                if (packageName != null) {
                    val opened = openPackage(packageName)
                    result.success(opened)
                } else {
                    result.error("BAD_ARGUMENTS", "Package name was null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun isPackageInstalled(packageName: String): Boolean {
        return try {
            applicationContext.packageManager.getPackageInfo(packageName, 0)
            true
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun openPackage(packageName: String): Boolean {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        return if (intent != null) {
            startActivity(intent)
            true
        } else {
            false
        }
    }
}

# Flutter R8 / ProGuard Keep Rules

# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Background Downloader
-keep class com.bbflight.background_downloader.** { *; }
-keepclassmembers class com.bbflight.background_downloader.** { *; }

# WorkManager
-keep class androidx.work.** { *; }
-keepclassmembers class androidx.work.** { *; }

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }

# Flutter Play Core Deferred Components (optional)
-dontwarn com.google.android.play.core.**

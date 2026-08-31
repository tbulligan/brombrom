# Flutter Play Core Deferred Components (optional)
-dontwarn com.google.android.play.core.**

# AndroidX WorkManager Worker classes instantiated via reflection by JobScheduler / WorkManager
-keep class * extends androidx.work.ListenableWorker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}
-keep class * extends androidx.work.Worker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}

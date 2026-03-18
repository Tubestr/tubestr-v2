# FFmpegKit can crash during release startup if R8 strips or rewrites
# classes/native bindings it expects to load reflectively.
-keep class com.antonkarpenko.ffmpegkit.** { *; }
-keep class com.arthenica.ffmpegkit.** { *; }
-keepclasseswithmembers class * {
    native <methods>;
}

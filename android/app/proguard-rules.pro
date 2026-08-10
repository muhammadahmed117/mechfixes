# Keep Flutter + speech/permission plugins intact in release builds.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

-keep class com.csdcorp.speech_to_text.** { *; }
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.csdcorp.speech_to_text.**
-dontwarn com.baseflow.permissionhandler.**

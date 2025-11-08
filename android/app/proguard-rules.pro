# Keep image_picker classes
-keep class io.flutter.plugins.imagepicker.** { *; }
-keep class io.flutter.plugins.flutter_plugin_android_lifecycle.** { *; }

# Keep plugin classes
-keep class androidx.core.app.** { *; }
-keep class androidx.lifecycle.** { *; }
-keep class androidx.activity.** { *; }

# Keep Pigeon generated classes
-keep class dev.flutter.pigeon.** { *; }
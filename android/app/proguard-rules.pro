# Flutter specific
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep all PocketVibe classes
-keep class com.pocketvibe.ide.** { *; }

# Keep Kotlin metadata for reflection
-keep class kotlin.Metadata { *; }

# FlutterSecureStorage
-keep class com.it_nomad.flutter_secure_storage.** { *; }

# Play Core (missing from some play-core versions)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

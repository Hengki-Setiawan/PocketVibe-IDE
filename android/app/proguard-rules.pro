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

# General desugaring / R8 compatibility
-dontwarn java.lang.invoke.StringConcatFactory
-dontwarn android.os.Binder
-dontwarn android.os.IBinder
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# AndroidX
-keep class androidx.** { *; }
-dontwarn androidx.**

# Networking (Dio/OkHttp)
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

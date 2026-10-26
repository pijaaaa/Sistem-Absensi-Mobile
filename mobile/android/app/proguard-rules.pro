# Add project specific ProGuard rules here.

# Flutter plugins (camera, google_mlkit_face_detection, ...)
-keep class io.flutter.plugins.** { *; }
-keep class com.arthenica.** { *; }

# Keep FaceService model classes
-keep class mobile.features.face.** { *; }
-keep class mobile.core.models.** { *; }

# Dio / OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-dontwarn kotlin.**
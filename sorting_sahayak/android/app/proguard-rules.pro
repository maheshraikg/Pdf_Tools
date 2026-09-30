# google_mlkit_text_recognition references optional script recognisers.
# Latin (English) and Devanagari (Hindi) are bundled, to keep the APK small,
# so tell R8 the others are intentionally absent.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# ML Kit finds its components (text recogniser, model loaders) by reflection
# through registrars listed in the manifest. R8 full mode strips or renames
# them, which crashes scanning in release builds with a NullPointerException
# ("getClass() on a null object reference"). Keep them intact.
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_common.** { *; }
-keep class com.google.android.gms.internal.mlkit_common.** { *; }
-keep class com.google.firebase.components.** { *; }
-keep class * implements com.google.firebase.components.ComponentRegistrar { *; }
-keep class com.google_mlkit_text_recognition.** { *; }
-keep class com.google_mlkit_commons.** { *; }
-keep class io.flutter.plugins.camera.** { *; }

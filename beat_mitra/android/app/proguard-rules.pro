# ML Kit text recognition: only Latin + Devanagari models are bundled.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
# SQLCipher
-keep class net.zetetic.** { *; }
-keep class net.sqlcipher.** { *; }
# Flutter deferred components (not used)
-dontwarn com.google.android.play.core.**

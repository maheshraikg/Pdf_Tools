# google_mlkit_text_recognition references optional script recognisers.
# Only Latin (English) is bundled, to keep the APK small, so tell R8 the
# others are intentionally absent.
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

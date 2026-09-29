# google_mlkit_text_recognition references the optional Chinese, Japanese and
# Korean recognisers. Only Latin and Devanagari are bundled, so tell R8 the
# others are intentionally absent.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

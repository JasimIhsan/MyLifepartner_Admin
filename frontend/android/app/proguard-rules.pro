# ─── ZEGOCLOUD SDK ─────────────────────────────────────────────────────────────
# Keep all Zego native bridge classes from being obfuscated or removed
-keep class com.zego.** { *; }
-keep class im.zego.** { *; }
-keep class com.zegocloud.** { *; }
-dontwarn com.zego.**
-dontwarn im.zego.**
-dontwarn com.zegocloud.**

# ─── Flutter ────────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**

# ─── App classes ────────────────────────────────────────────────────────────────
-keep class com.premiumglobalcorp.lifepartneragain.** { *; }

# ─── General Android ────────────────────────────────────────────────────────────
# Keep annotations used for reflection
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable

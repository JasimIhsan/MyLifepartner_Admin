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

# ─── Google Sign-In / Credential Manager (google_sign_in_android v7+) ──────────
# R8 strips these at runtime in release builds — required for native Credential Manager flow.
# Without these rules the account picker silently fails on Play Store builds.
-if class androidx.credentials.CredentialManager
-keep class androidx.credentials.playservices.** { *; }

-keep class androidx.credentials.** { *; }
-keep class androidx.credentials.exceptions.** { *; }
-dontwarn androidx.credentials.**

# Google Identity SDK — used by Credential Manager for Sign-In with Google
-keep class com.google.android.libraries.identity.googleid.** { *; }
-dontwarn com.google.android.libraries.identity.googleid.**

# Google Play Services Auth — used by the Credential Manager Play Services bridge
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.**

# Keep Parcelable implementations required for Credential Manager inter-process calls
-keepclassmembers class * implements android.os.Parcelable {
    static ** CREATOR;
}

# ─── Flutter CallKit Incoming & Coil ──────────────────────────────────────────
-keep class com.hiennv.flutter_callkit_incoming.** { *; }
-dontwarn com.hiennv.flutter_callkit_incoming.**
-dontwarn coil.**


# R8/ProGuard keep rules for Project Elite release builds.
#
# Release builds run R8 code shrinking + obfuscation (enabled by default by the
# Flutter Gradle plugin). Several plugins serialize data reflectively and break
# unless their classes and generic signatures are preserved.

# --- Generic signatures (required by Gson / TypeToken) ------------------------
# flutter_local_notifications stores scheduled notifications as JSON via Gson.
# Without -keepattributes Signature, R8 erases the generic type argument and
# pendingNotificationRequests() throws:
#   "TypeToken must be created with a type argument".
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# --- flutter_local_notifications ---------------------------------------------
-keep class com.dexterous.** { *; }
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }

# --- Gson ---------------------------------------------------------------------
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep public class * implements java.lang.reflect.Type
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

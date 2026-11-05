# flutter_local_notifications stores scheduled notifications with Gson and
# reads them back in ScheduledNotificationReceiver / BootReceiver to show and
# reschedule repeating notifications. Without these rules R8 strips the generic
# type info, so the daily reminder fires once (or never) and then stops.
# https://github.com/google/gson/blob/main/examples/android-proguard-example/proguard.cfg

-keep class com.dexterous.** { *; }

-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

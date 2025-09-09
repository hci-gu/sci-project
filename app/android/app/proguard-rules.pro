# Default ProGuard rules for Android apps
-keep class * implements android.os.Parcelable { *; }
-keep class * extends android.app.Activity
-keep class * extends android.app.Service
-keep class * extends android.content.BroadcastReceiver
-keep class * extends android.content.ContentProvider
-keep class * extends android.view.View
-keep class * extends android.app.Fragment
-keep class * extends android.support.v4.app.Fragment
-keep class * extends androidx.fragment.app.Fragment

# Keep Joda-Time classes from being removed by R8
-keepnames class org.joda.convert.** { *; }
-keepnames class org.joda.time.** { *; }
-dontwarn org.joda.convert.FromString
-dontwarn org.joda.convert.ToString

# Keep Gson annotations (harmless even if unused)
-keepattributes *Annotation*,Signature

# Keep the Polar SDK model classes and their member names
-keep class com.polar.sdk.api.model.** { *; }
-keep class com.polar.androidcommunications.api.ble.model.** { *; }  # e.g., DisInfo

# (Optional) If you see enums serialized by .name, keep them too (usually not needed)
-keepclassmembers enum * { *; }
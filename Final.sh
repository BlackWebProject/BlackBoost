#!/usr/bin/env bash
# Final.sh — итоговый проект Black Boost: создаёт ВЕСЬ проект с нуля (или обновляет существующий), настраивает сборку APK в GitHub Actions и пушит.
# Запуск в Codespaces из корня репозитория:   bash Final.sh
set -e
cd "$(dirname "$0")"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || git init -q
echo "▶ Создаю файлы проекта..."
mkdir -p "$(dirname 'settings.gradle.kts')"
cat > 'settings.gradle.kts' <<'BB_FINAL_1'
pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement { repositories { google(); mavenCentral() } }
rootProject.name = "BlackBoost"
include(":app")
BB_FINAL_1
mkdir -p "$(dirname 'build.gradle.kts')"
cat > 'build.gradle.kts' <<'BB_FINAL_2'
plugins {
    id("com.android.application") version "8.5.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
}
BB_FINAL_2
mkdir -p "$(dirname 'gradle.properties')"
cat > 'gradle.properties' <<'BB_FINAL_3'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.nonTransitiveRClass=true
kotlin.code.style=official
BB_FINAL_3
mkdir -p "$(dirname 'gradle/wrapper/gradle-wrapper.properties')"
cat > 'gradle/wrapper/gradle-wrapper.properties' <<'BB_FINAL_4'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.7-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
BB_FINAL_4
mkdir -p "$(dirname 'app/proguard-rules.pro')"
cat > 'app/proguard-rules.pro' <<'BB_FINAL_5'
BB_FINAL_5
mkdir -p "$(dirname 'app/src/main/res/values/strings.xml')"
cat > 'app/src/main/res/values/strings.xml' <<'BB_FINAL_6'
<resources>
    <string name="app_name">Black Boost</string>
</resources>
BB_FINAL_6
mkdir -p "$(dirname 'app/src/main/res/values/colors.xml')"
cat > 'app/src/main/res/values/colors.xml' <<'BB_FINAL_7'
<resources>
    <color name="bb_bg">#FF050505</color>
    <color name="ic_launcher_background">#FF050505</color>
</resources>
BB_FINAL_7
mkdir -p "$(dirname 'app/src/main/res/values/themes.xml')"
cat > 'app/src/main/res/values/themes.xml' <<'BB_FINAL_8'
<resources>
    <style name="Theme.BlackBoost" parent="android:Theme.Material.NoActionBar">
        <item name="android:windowBackground">@color/bb_bg</item>
        <item name="android:statusBarColor">@color/bb_bg</item>
        <item name="android:navigationBarColor">@color/bb_bg</item>
    </style>
</resources>
BB_FINAL_8
mkdir -p "$(dirname 'app/src/main/res/drawable/ic_logo.xml')"
cat > 'app/src/main/res/drawable/ic_logo.xml' <<'BB_FINAL_9'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" xmlns:aapt="http://schemas.android.com/aapt" android:width="64dp" android:height="61dp" android:viewportWidth="636" android:viewportHeight="603"><path android:fillType="evenOdd" android:pathData="M5.2,597.4C4.6,596.3 5.2,592.6 7.2,586.1C11.9,570.6 50.7,450.7 58.5,427.5C60.9,420.4 70.8,390.2 80.5,360.5C102.2,294.2 123.9,228.0 142.0,173.0C149.7,149.7 175.6,70.4 180.2,56.0C185.0,41.1 191.0,26.2 192.5,25.6C194.9,24.7 213.3,23.0 242.5,21.0C278.6,18.5 319.4,15.5 345.5,13.5C519.1,0.2 540.0,0.7 576.0,19.1C640.3,52.0 650.5,139.2 597.7,205.8C582.8,224.6 559.3,245.1 539.8,256.4C533.7,259.8 533.8,260.4 540.2,262.6C592.9,279.7 624.0,322.7 621.7,374.9C618.6,443.9 571.3,507.4 498.0,541.0C453.9,561.2 415.2,569.0 327.0,575.5C315.7,576.3 291.2,578.1 272.5,579.5C253.8,580.9 226.6,582.9 212.0,584.0C183.2,586.2 163.4,587.7 112.0,591.5C93.6,592.9 72.2,594.4 64.5,595.0C51.1,596.0 8.3,599.0 6.8,599.0C6.4,599.0 5.7,598.3 5.2,597.4ZM137.1,530.2C143.0,525.4 155.8,514.8 165.6,506.5C218.0,462.3 210.9,466.7 232.0,465.1C308.1,459.3 375.4,453.8 380.8,453.0C398.2,450.3 409.9,438.8 419.0,415.5C421.2,409.8 423.0,404.6 423.0,403.9C423.0,402.6 410.1,403.0 372.0,405.5C360.2,406.3 342.6,407.4 333.0,408.0C323.4,408.6 310.6,409.5 304.5,410.1C287.6,411.5 280.0,411.3 280.0,409.5C280.0,407.2 313.6,371.4 405.1,275.8C448.8,230.2 451.6,227.2 450.6,226.3C450.0,225.7 434.2,226.3 370.8,229.2C356.1,229.8 343.7,230.1 343.3,229.7C342.0,228.3 345.2,219.9 364.0,175.5C379.3,139.4 382.4,132.0 388.7,116.5C399.6,89.7 402.8,81.5 402.5,81.1C402.0,80.6 379.7,96.7 373.2,102.2C343.5,127.7 317.0,153.1 260.6,210.1C206.1,265.1 171.8,301.2 172.8,302.2C173.2,302.6 188.7,302.1 207.1,301.1C266.9,297.6 267.9,297.6 268.6,299.4C269.1,300.8 263.7,310.3 243.8,342.5C239.7,349.1 223.8,374.8 208.5,399.5C177.1,450.2 163.3,472.7 158.3,481.5C156.4,484.8 153.2,490.2 151.1,493.5C147.5,499.2 145.0,503.4 131.7,526.1C122.3,542.0 122.5,542.2 137.1,530.2Z"><aapt:attr name="android:fillColor"><gradient android:startX="0" android:startY="0" android:endX="636" android:endY="603" android:type="linear"><item android:offset="0" android:color="#FFFFEE00"/><item android:offset="0.5" android:color="#FFFF7A00"/><item android:offset="1" android:color="#FFF00014"/></gradient></aapt:attr></path></vector>
BB_FINAL_9
mkdir -p "$(dirname 'app/src/main/res/drawable/ic_launcher_foreground.xml')"
cat > 'app/src/main/res/drawable/ic_launcher_foreground.xml' <<'BB_FINAL_10'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" xmlns:aapt="http://schemas.android.com/aapt" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108"><group android:scaleX="0.08176" android:scaleY="0.08176" android:translateX="28.0" android:translateY="29.35"><path android:fillType="evenOdd" android:pathData="M5.2,597.4C4.6,596.3 5.2,592.6 7.2,586.1C11.9,570.6 50.7,450.7 58.5,427.5C60.9,420.4 70.8,390.2 80.5,360.5C102.2,294.2 123.9,228.0 142.0,173.0C149.7,149.7 175.6,70.4 180.2,56.0C185.0,41.1 191.0,26.2 192.5,25.6C194.9,24.7 213.3,23.0 242.5,21.0C278.6,18.5 319.4,15.5 345.5,13.5C519.1,0.2 540.0,0.7 576.0,19.1C640.3,52.0 650.5,139.2 597.7,205.8C582.8,224.6 559.3,245.1 539.8,256.4C533.7,259.8 533.8,260.4 540.2,262.6C592.9,279.7 624.0,322.7 621.7,374.9C618.6,443.9 571.3,507.4 498.0,541.0C453.9,561.2 415.2,569.0 327.0,575.5C315.7,576.3 291.2,578.1 272.5,579.5C253.8,580.9 226.6,582.9 212.0,584.0C183.2,586.2 163.4,587.7 112.0,591.5C93.6,592.9 72.2,594.4 64.5,595.0C51.1,596.0 8.3,599.0 6.8,599.0C6.4,599.0 5.7,598.3 5.2,597.4ZM137.1,530.2C143.0,525.4 155.8,514.8 165.6,506.5C218.0,462.3 210.9,466.7 232.0,465.1C308.1,459.3 375.4,453.8 380.8,453.0C398.2,450.3 409.9,438.8 419.0,415.5C421.2,409.8 423.0,404.6 423.0,403.9C423.0,402.6 410.1,403.0 372.0,405.5C360.2,406.3 342.6,407.4 333.0,408.0C323.4,408.6 310.6,409.5 304.5,410.1C287.6,411.5 280.0,411.3 280.0,409.5C280.0,407.2 313.6,371.4 405.1,275.8C448.8,230.2 451.6,227.2 450.6,226.3C450.0,225.7 434.2,226.3 370.8,229.2C356.1,229.8 343.7,230.1 343.3,229.7C342.0,228.3 345.2,219.9 364.0,175.5C379.3,139.4 382.4,132.0 388.7,116.5C399.6,89.7 402.8,81.5 402.5,81.1C402.0,80.6 379.7,96.7 373.2,102.2C343.5,127.7 317.0,153.1 260.6,210.1C206.1,265.1 171.8,301.2 172.8,302.2C173.2,302.6 188.7,302.1 207.1,301.1C266.9,297.6 267.9,297.6 268.6,299.4C269.1,300.8 263.7,310.3 243.8,342.5C239.7,349.1 223.8,374.8 208.5,399.5C177.1,450.2 163.3,472.7 158.3,481.5C156.4,484.8 153.2,490.2 151.1,493.5C147.5,499.2 145.0,503.4 131.7,526.1C122.3,542.0 122.5,542.2 137.1,530.2Z"><aapt:attr name="android:fillColor"><gradient android:startX="0" android:startY="0" android:endX="636" android:endY="603" android:type="linear"><item android:offset="0" android:color="#FFFFEE00"/><item android:offset="0.5" android:color="#FFFF7A00"/><item android:offset="1" android:color="#FFF00014"/></gradient></aapt:attr></path></group></vector>
BB_FINAL_10
mkdir -p "$(dirname 'app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml')"
cat > 'app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml' <<'BB_FINAL_11'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
BB_FINAL_11
mkdir -p "$(dirname 'app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml')"
cat > 'app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml' <<'BB_FINAL_12'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
BB_FINAL_12
mkdir -p "$(dirname 'app/src/main/AndroidManifest.xml')"
cat > 'app/src/main/AndroidManifest.xml' <<'BB_FINAL_13'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" xmlns:tools="http://schemas.android.com/tools">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    <uses-permission android:name="android.permission.KILL_BACKGROUND_PROCESSES" />
    <uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" tools:ignore="ProtectedPermissions" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29" />
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
    <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" tools:ignore="ScopedStorage" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.ACCESS_NOTIFICATION_POLICY" />
    <uses-permission android:name="android.permission.REQUEST_DELETE_PACKAGES" />
    <queries>
        <intent>
            <action android:name="android.intent.action.MAIN" />
            <category android:name="android.intent.category.LAUNCHER" />
        </intent>
    </queries>
    <application
        android:allowBackup="false"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:label="@string/app_name"
        android:requestLegacyExternalStorage="true"
        android:theme="@style/Theme.BlackBoost">
        <activity android:name=".MainActivity" android:exported="true" android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
BB_FINAL_13
mkdir -p "$(dirname 'app/src/main/java/com/blackboost/app/Prefs.kt')"
cat > 'app/src/main/java/com/blackboost/app/Prefs.kt' <<'BB_FINAL_14'
package com.blackboost.app

import android.content.Context

class Prefs(c: Context) {
    private val p = c.getSharedPreferences("bb", Context.MODE_PRIVATE)
    var lang: String
        get() = p.getString("lang", "ru") ?: "ru"
        set(v) = p.edit().putString("lang", v).apply()
    var notif: Boolean
        get() = p.getBoolean("notif", true)
        set(v) = p.edit().putBoolean("notif", v).apply()
    var premium: Boolean
        get() = p.getBoolean("pr", false)
        set(v) = p.edit().putBoolean("pr", v).apply()
    var gameMode: Boolean
        get() = p.getBoolean("gm", false)
        set(v) = p.edit().putBoolean("gm", v).apply()
    var dndPrev: Int
        get() = p.getInt("dnd", -1)
        set(v) = p.edit().putInt("dnd", v).apply()
    var gProf: String
        get() = p.getString("gprof", "perf") ?: "perf"
        set(v) = p.edit().putString("gprof", v).apply()
    var gMode: Int
        get() = p.getInt("gmode", 1)
        set(v) = p.edit().putInt("gmode", v).apply()
    var lastClean: Long
        get() = p.getLong("lastclean", 0L)
        set(v) = p.edit().putLong("lastclean", v).apply()
    var games: Set<String>
        get() = p.getStringSet("games", emptySet())?.toSet() ?: emptySet()
        set(v) = p.edit().putStringSet("games", v).apply()
    private var hist: String
        get() = p.getString("hist", "") ?: ""
        set(v) = p.edit().putString("hist", v).apply()

    /** История очистки: сколько байт освобождено и когда. */
    fun addHist(b: Long) {
        if (b <= 0) return
        val now = System.currentTimeMillis()
        val cut = now - 31L * 86400000
        val l = hist.split(";").filter { it.isNotEmpty() && (it.substringBefore(",").toLongOrNull() ?: 0L) > cut } + "$now,$b"
        hist = l.joinToString(";")
        lastClean = now
    }

    fun histSum(days: Int): Long {
        val cut = System.currentTimeMillis() - days * 86400000L
        return hist.split(";").filter { it.isNotEmpty() }.sumOf {
            val a = it.split(",")
            if ((a[0].toLongOrNull() ?: 0L) >= cut) (a.getOrNull(1)?.toLongOrNull() ?: 0L) else 0L
        }
    }
}
BB_FINAL_14
mkdir -p "$(dirname 'app/src/main/java/com/blackboost/app/Sys.kt')"
cat > 'app/src/main/java/com/blackboost/app/Sys.kt' <<'BB_FINAL_15'
package com.blackboost.app

import android.Manifest
import android.app.ActivityManager
import android.app.AppOpsManager
import android.app.NotificationManager
import android.app.usage.StorageStatsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.PowerManager
import android.os.Process
import android.os.StatFs
import android.os.storage.StorageManager
import android.provider.MediaStore
import android.provider.Settings
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.core.content.ContextCompat
import androidx.core.graphics.drawable.toBitmap
import java.io.File
import kotlin.math.abs

class AppInfo(val pkg: String, val label: String, val icon: ImageBitmap?, val bytes: Long, val cache: Long, val lastUsed: Long, val game: Boolean)
class Bat(val pct: Int, val charging: Boolean, val tempC: Float, val minutes: Int?)
class Stor(val total: Long, val free: Long, val apps: Long, val media: Long, val docs: Long, val cache: Long) {
    val other: Long get() = (total - free - apps - media - docs - cache).coerceAtLeast(0)
}

@Suppress("DEPRECATION")
object Sys {
    fun mem(c: Context): Pair<Long, Long> {
        val mi = ActivityManager.MemoryInfo()
        c.getSystemService(ActivityManager::class.java).getMemoryInfo(mi)
        return mi.availMem to mi.totalMem
    }

    fun storage(): Pair<Long, Long> {
        val s = StatFs(Environment.getDataDirectory().path)
        return s.availableBytes to s.totalBytes
    }

    fun battery(c: Context): Bat {
        val i = c.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        val l = i?.getIntExtra(BatteryManager.EXTRA_LEVEL, 0) ?: 0
        val sc = i?.getIntExtra(BatteryManager.EXTRA_SCALE, 100) ?: 100
        val st = i?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
        val ch = st == BatteryManager.BATTERY_STATUS_CHARGING || st == BatteryManager.BATTERY_STATUS_FULL
        val t = (i?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0) / 10f
        val bm = c.getSystemService(BatteryManager::class.java)
        var min: Int? = null
        if (ch) {
            if (Build.VERSION.SDK_INT >= 28) {
                val ms = bm.computeChargeTimeRemaining()
                if (ms > 0) min = (ms / 60000).toInt()
            }
        } else {
            val cur = abs(bm.getLongProperty(BatteryManager.BATTERY_PROPERTY_CURRENT_NOW))
            val cc = bm.getLongProperty(BatteryManager.BATTERY_PROPERTY_CHARGE_COUNTER)
            if (cur > 0 && cc > 0) {
                var h = cc.toDouble() / cur
                if (h > 200) h = cc.toDouble() / (cur * 1000.0)
                if (h in 0.05..72.0) min = (h * 60).toInt()
            }
        }
        return Bat(l * 100 / sc, ch, t, min)
    }

    fun powerSave(c: Context) = c.getSystemService(PowerManager::class.java).isPowerSaveMode

    fun hasUsage(c: Context): Boolean {
        val o = c.getSystemService(AppOpsManager::class.java)
        val m = if (Build.VERSION.SDK_INT >= 29) o.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), c.packageName)
        else o.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), c.packageName)
        return m == AppOpsManager.MODE_ALLOWED
    }

    fun hasFiles(c: Context) = if (Build.VERSION.SDK_INT >= 30) Environment.isExternalStorageManager()
    else ContextCompat.checkSelfPermission(c, Manifest.permission.WRITE_EXTERNAL_STORAGE) == PackageManager.PERMISSION_GRANTED

    fun hasMedia(c: Context) = ContextCompat.checkSelfPermission(
        c, if (Build.VERSION.SDK_INT >= 33) Manifest.permission.READ_MEDIA_IMAGES else Manifest.permission.READ_EXTERNAL_STORAGE
    ) == PackageManager.PERMISSION_GRANTED

    fun hasDnd(c: Context) = c.getSystemService(NotificationManager::class.java).isNotificationPolicyAccessGranted

    fun pkgs(c: Context): List<String> = c.packageManager
        .queryIntentActivities(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER), 0)
        .map { it.activityInfo.packageName }.distinct().filter { it != c.packageName }

    fun apps(c: Context): List<AppInfo> {
        val pm = c.packageManager
        val usage = hasUsage(c)
        val ssm = c.getSystemService(StorageStatsManager::class.java)
        val now = System.currentTimeMillis()
        val used = if (usage) c.getSystemService(UsageStatsManager::class.java).queryAndAggregateUsageStats(now - 90L * 86400000, now) else emptyMap()
        return pkgs(c).mapNotNull { p ->
            try {
                val ai = pm.getApplicationInfo(p, 0)
                var b = apkSize(ai)
                var ca = 0L
                if (usage) {
                    try {
                        val s = ssm.queryStatsForPackage(StorageManager.UUID_DEFAULT, p, Process.myUserHandle())
                        b = s.appBytes + s.dataBytes
                        ca = s.cacheBytes
                    } catch (e: Exception) { }
                }
                val icon = try { pm.getApplicationIcon(p).toBitmap(96, 96).asImageBitmap() } catch (e: Exception) { null }
                AppInfo(p, pm.getApplicationLabel(ai).toString(), icon, b, ca, used[p]?.lastTimeUsed ?: 0L, ai.category == ApplicationInfo.CATEGORY_GAME)
            } catch (e: Exception) { null }
        }.sortedBy { it.label.lowercase() }
    }

    /** Просит систему завершить фоновые процессы других приложений. Возвращает (освобождено байт, число приложений). */
    fun boostRam(c: Context): Pair<Long, Int> {
        val am = c.getSystemService(ActivityManager::class.java)
        val before = mem(c).first
        val p = pkgs(c)
        p.forEach { am.killBackgroundProcesses(it) }
        Thread.sleep(700)
        return (mem(c).first - before).coerceAtLeast(0) to p.size
    }

    /** Размер установки (APK) — доступен без каких-либо разрешений, в отличие от размера данных и кэша. */
    private fun apkSize(ai: ApplicationInfo): Long {
        var s = try { File(ai.sourceDir).length() } catch (e: Exception) { 0L }
        ai.splitSourceDirs?.forEach { s += try { File(it).length() } catch (e: Exception) { 0L } }
        return s
    }

    private fun rd(p: String): String? = try { File(p).readText().trim() } catch (e: Exception) { null }

    /** Загрузка CPU по отношению текущей частоты ядер к максимальной (если ядро отдаёт данные). */
    fun cpu(): Int? {
        var cur = 0L
        var mx = 0L
        for (i in 0 until Runtime.getRuntime().availableProcessors()) {
            val b = "/sys/devices/system/cpu/cpu$i/cpufreq/"
            val a = rd(b + "scaling_cur_freq")?.toLongOrNull() ?: continue
            val m = rd(b + "cpuinfo_max_freq")?.toLongOrNull() ?: continue
            cur += a
            mx += m
        }
        return if (mx > 0) (cur * 100 / mx).toInt() else null
    }

    /** Загрузка GPU (Adreno / Mali), если устройство разрешает чтение. */
    fun gpu(): Int? {
        rd("/sys/class/kgsl/kgsl-3d0/gpubusy")?.split(" ")?.filter { it.isNotEmpty() }?.let {
            if (it.size >= 2) {
                val b = it[0].toLongOrNull()
                val t = it[1].toLongOrNull()
                if (b != null && t != null && t > 0) return (b * 100 / t).toInt()
            }
        }
        rd("/sys/class/misc/mali0/device/utilization")?.toIntOrNull()?.let { return it }
        return null
    }

    fun stor(c: Context, apps: List<AppInfo>): Stor {
        val (f, t) = storage()
        var m = 0L
        var d = 0L
        try {
            c.contentResolver.query(
                MediaStore.Files.getContentUri("external"),
                arrayOf(MediaStore.Files.FileColumns.SIZE, MediaStore.Files.FileColumns.MEDIA_TYPE), null, null, null
            )?.use { cu ->
                while (cu.moveToNext()) {
                    val z = cu.getLong(0)
                    when (cu.getInt(1)) { 1, 3 -> m += z; 0 -> d += z }
                }
            }
        } catch (e: Exception) { }
        return Stor(t, f, apps.sumOf { it.bytes - it.cache }, m, d, apps.sumOf { it.cache })
    }

    private fun go(c: Context, i: Intent) {
        try { c.startActivity(i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
        catch (e: Exception) { c.startActivity(Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
    }
    fun openUrl(c: Context, u: String) = tryGo(c, Intent(Intent.ACTION_VIEW, Uri.parse(u)))
    fun usageSettings(c: Context) = go(c, Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
    fun filesSettings(c: Context) { if (Build.VERSION.SDK_INT >= 30) go(c, Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION, Uri.parse("package:${c.packageName}"))) }
    fun appInfo(c: Context, p: String) = go(c, Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$p")))
    fun saver(c: Context) = go(c, Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS))
    fun battOpt(c: Context) = go(c, Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
    fun dnd(c: Context) = go(c, Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
    fun uninstall(c: Context, p: String) = go(c, Intent(Intent.ACTION_DELETE, Uri.parse("package:$p")))

    fun model() = Build.MANUFACTURER.replaceFirstChar { it.uppercase() } + " " + Build.MODEL
    fun androidVer() = "Android " + Build.VERSION.RELEASE + " (API " + Build.VERSION.SDK_INT + ")"
    fun thermal(c: Context): Int? = if (Build.VERSION.SDK_INT >= 29) c.getSystemService(PowerManager::class.java).currentThermalStatus else null
    fun display(c: Context) = go(c, Intent(Settings.ACTION_DISPLAY_SETTINGS))

    /** Время на экране за 24 часа (нужен доступ к статистике использования). */
    fun fgUsage(c: Context): Map<String, Long> {
        if (!hasUsage(c)) return emptyMap()
        val now = System.currentTimeMillis()
        return c.getSystemService(UsageStatsManager::class.java).queryAndAggregateUsageStats(now - 86400000L, now).mapValues { it.value.totalTimeInForeground }
    }

    /** Загрузка CPU из /proc/stat. На многих телефонах Android 8+ файл закрыт, тогда вернёт null. */
    class CpuSampler {
        private var prev: LongArray? = null
        fun read(): Int? {
            val l = try { File("/proc/stat").bufferedReader().use { it.readLine() } } catch (e: Exception) { null } ?: return null
            val n = l.trim().split(Regex("\\s+")).drop(1).mapNotNull { it.toLongOrNull() }
            if (n.size < 4) return null
            val idle = n[3] + (n.getOrNull(4) ?: 0L)
            val tot = n.sum()
            val p = prev
            prev = longArrayOf(idle, tot)
            if (p == null) return null
            val dt = tot - p[1]
            return if (dt > 0) (100 * (dt - (idle - p[0])) / dt).toInt().coerceIn(0, 100) else null
        }
    }

    private val SENS = mapOf(
        "android.permission.CAMERA" to "camera", "android.permission.RECORD_AUDIO" to "mic",
        "android.permission.ACCESS_FINE_LOCATION" to "loc", "android.permission.ACCESS_COARSE_LOCATION" to "loc",
        "android.permission.READ_CONTACTS" to "contacts", "android.permission.READ_SMS" to "sms", "android.permission.READ_CALL_LOG" to "calls"
    )

    /** Какие чувствительные разрешения реально выданы приложениям. */
    fun sensitive(c: Context, pkgs: List<String>): Map<String, Set<String>> {
        val pm = c.packageManager
        val out = HashMap<String, Set<String>>()
        for (p in pkgs) {
            try {
                val pi = pm.getPackageInfo(p, PackageManager.GET_PERMISSIONS)
                val rp = pi.requestedPermissions ?: continue
                val fl = pi.requestedPermissionsFlags ?: continue
                val s = HashSet<String>()
                rp.forEachIndexed { i, n ->
                    val k = SENS[n]
                    if (k != null && (fl[i] and android.content.pm.PackageInfo.REQUESTED_PERMISSION_GRANTED) != 0) s.add(k)
                }
                if (s.isNotEmpty()) out[p] = s
            } catch (e: Exception) { }
        }
        return out
    }
}
BB_FINAL_15
mkdir -p "$(dirname 'app/src/main/java/com/blackboost/app/Cleaner.kt')"
cat > 'app/src/main/java/com/blackboost/app/Cleaner.kt' <<'BB_FINAL_16'
package com.blackboost.app

import android.content.Context
import android.os.Environment
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.security.MessageDigest

/** Файл-кандидат на удаление. group > 0 — группа дубликатов, orig — самый старый экземпляр (оригинал). */
class Fi(val file: File, val size: Long, val def: Boolean, val group: Int = 0, val orig: Boolean = false) {
    val path: String get() = file.path
}

class Cat(val id: String, val ru: String, val en: String, val files: List<Fi>) {
    val bytes: Long get() = files.sumOf { it.size }
}

object Cleaner {
    private val tmpExt = setOf("tmp", "temp", "log", "bak", "old", "chk", "dmp")
    private val mediaExt = setOf("jpg", "jpeg", "png", "webp", "heic", "gif", "mp4", "mkv", "mov", "3gp", "avi")

    fun ownFiles(c: Context): List<File> =
        listOfNotNull(c.cacheDir, c.externalCacheDir).flatMap { d -> d.walkBottomUp().filter { it.isFile }.toList() }

    private fun isJunk(n: String, par: String): Boolean {
        val ext = n.substringAfterLast('.', "")
        return n.startsWith(".trashed-") || par == ".thumbnails" || par == "LOST.DIR" || ext in tmpExt || n.startsWith("~")
    }

    private fun sha(f: File): String = try {
        val md = MessageDigest.getInstance("SHA-1")
        f.inputStream().use { s ->
            val buf = ByteArray(65536)
            while (true) { val n = s.read(buf); if (n <= 0) break; md.update(buf, 0, n) }
        }
        md.digest().joinToString("") { "%02x".format(it) }
    } catch (e: Exception) { f.path }

    /** Глубокое сканирование: кэш и временные файлы, старые загрузки, большие файлы, дубликаты фото и видео. Ничего не удаляет. */
    suspend fun scan(c: Context, stage: (String) -> Unit): List<Cat> = withContext(Dispatchers.IO) {
        val root = Environment.getExternalStorageDirectory()
        val dlPrefix = File(root, "Download").path + "/"
        val junk = ArrayList<Fi>()
        val dl = ArrayList<Fi>()
        val big = ArrayList<Fi>()
        val media = ArrayList<File>()
        ownFiles(c).forEach { junk.add(Fi(it, it.length(), true)) }
        stage("files")
        val old = System.currentTimeMillis() - 30L * 86400000
        root.walkTopDown().onEnter { !(it.parentFile == root && it.name == "Android") }.forEach { f ->
            if (!f.isFile) return@forEach
            val n = f.name.lowercase()
            val ext = n.substringAfterLast('.', "")
            val len = f.length()
            if (isJunk(n, f.parentFile?.name ?: "")) junk.add(Fi(f, len, true))
            else if (f.path.startsWith(dlPrefix) && (ext == "apk" || f.lastModified() < old)) dl.add(Fi(f, len, ext == "apk"))
            else if (len >= 100L * 1024 * 1024) big.add(Fi(f, len, false))
            else if (ext in mediaExt && len >= 50 * 1024) media.add(f)
        }
        stage("dups")
        val dup = ArrayList<Fi>()
        var gid = 0
        media.groupBy { it.length() }.values.filter { it.size > 1 }.take(400).forEach { g ->
            g.groupBy { sha(it) }.values.forEach { s ->
                if (s.size > 1) {
                    gid++
                    s.sortedBy { it.lastModified() }.forEachIndexed { i, f -> dup.add(Fi(f, f.length(), i > 0, gid, i == 0)) }
                }
            }
        }
        listOf(
            Cat("junk", "Кэш и временные файлы", "Cache & temp files", junk),
            Cat("dl", "Загрузки", "Downloads", dl),
            Cat("big", "Большие файлы", "Large files", big.sortedByDescending { it.size }),
            Cat("dup", "Дубликаты фото и видео", "Duplicate photos & videos", dup)
        )
    }

    suspend fun delete(list: List<Fi>, progress: (Float) -> Unit): Long = withContext(Dispatchers.IO) {
        var freed = 0L
        list.forEachIndexed { i, x ->
            val l = x.file.length()
            if (x.file.delete()) freed += l
            if (i % 10 == 0) progress((i + 1f) / list.size)
        }
        progress(1f)
        freed
    }

    suspend fun cleanOwn(c: Context): Long = withContext(Dispatchers.IO) {
        var freed = 0L
        ownFiles(c).forEach { val l = it.length(); if (it.delete()) freed += l }
        freed
    }

    /** Быстрая безопасная очистка: собственный кэш + явный мусор (tmp, миниатюры, корзина). Личные файлы не трогает. */
    suspend fun quick(c: Context, all: Boolean): Long = withContext(Dispatchers.IO) {
        var freed = 0L
        ownFiles(c).forEach { val l = it.length(); if (it.delete()) freed += l }
        if (all) {
            val root = Environment.getExternalStorageDirectory()
            root.walkTopDown().onEnter { !(it.parentFile == root && it.name == "Android") }.forEach { f ->
                if (f.isFile && isJunk(f.name.lowercase(), f.parentFile?.name ?: "")) {
                    val l = f.length()
                    if (f.delete()) freed += l
                }
            }
        }
        freed
    }
}
BB_FINAL_16
mkdir -p "$(dirname 'app/src/main/java/com/blackboost/app/Net.kt')"
cat > 'app/src/main/java/com/blackboost/app/Net.kt' <<'BB_FINAL_17'
package com.blackboost.app

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.net.HttpURLConnection
import java.net.InetSocketAddress
import java.net.Socket
import java.net.URL
import kotlin.math.abs

class NetRes(val type: String, val ping: Int?, val jitter: Int?, val loss: Int, val mbps: Float?)

/** Диагностика сети: задержка (TCP), джиттер, потери, скорость загрузки (около 4 МБ трафика). */
object Net {
    suspend fun test(c: Context): NetRes = withContext(Dispatchers.IO) {
        val cm = c.getSystemService(ConnectivityManager::class.java)
        val caps = cm.getNetworkCapabilities(cm.activeNetwork)
        val type = when {
            caps == null -> "none"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "cell"
            else -> "other"
        }
        val times = ArrayList<Long>()
        var lost = 0
        repeat(8) {
            val t0 = System.nanoTime()
            try {
                Socket().use { it.connect(InetSocketAddress("1.1.1.1", 443), 2000) }
                times.add((System.nanoTime() - t0) / 1_000_000)
            } catch (e: Exception) { lost++ }
            Thread.sleep(150)
        }
        val ping = if (times.isNotEmpty()) times.average().toInt() else null
        val jit = if (times.size > 1) times.zipWithNext { a, b -> abs(a - b) }.average().toInt() else null
        var mbps: Float? = null
        if (type != "none") {
            try {
                val t0 = System.nanoTime()
                var n = 0L
                val con = URL("https://speed.cloudflare.com/__down?bytes=4000000").openConnection() as HttpURLConnection
                con.connectTimeout = 4000
                con.readTimeout = 6000
                con.inputStream.use { s ->
                    val b = ByteArray(32768)
                    while (true) { val r = s.read(b); if (r < 0) break; n += r }
                }
                val sec = (System.nanoTime() - t0) / 1e9
                if (sec > 0 && n > 0) mbps = (n * 8 / 1e6 / sec).toFloat()
            } catch (e: Exception) { }
        }
        NetRes(type, ping, jit, lost * 100 / 8, mbps)
    }
}
BB_FINAL_17
mkdir -p "$(dirname 'app/src/main/java/com/blackboost/app/Vm.kt')"
cat > 'app/src/main/java/com/blackboost/app/Vm.kt' <<'BB_FINAL_18'
package com.blackboost.app

import android.app.Activity
import android.app.Application
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.compose.runtime.*
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

enum class Screen { Splash, Home, Clean, Battery, Apps, Storage, Fps, Settings, Monitor, Perms, Net, Faq }
class Explain(val title: String, val text: String, val action: () -> Unit)
class Rep(val text: String, val ok: Boolean, val fix: (() -> Unit)? = null)
class QuickRes(val ram: Long, val files: Long)

class Vm(app: Application) : AndroidViewModel(app) {
    private val c: Context get() = getApplication()
    val prefs = Prefs(app)

    var screen by mutableStateOf(Screen.Splash)
    private val stack = ArrayList<Screen>()
    fun go(s: Screen, tab: Boolean = false) { if (tab) stack.clear() else stack.add(screen); screen = s }
    fun back() {
        if (screen == Screen.Clean && detail != null) { detail = null; return }
        if (stack.isNotEmpty()) screen = stack.removeAt(stack.size - 1)
        else if (screen != Screen.Home) screen = Screen.Home
    }

    var lang by mutableStateOf(prefs.lang)
    var notif by mutableStateOf(prefs.notif)
    var gameMode by mutableStateOf(prefs.gameMode)
    var toast by mutableStateOf<String?>(null)
    var explain by mutableStateOf<Explain?>(null)
    var quickRes by mutableStateOf<QuickRes?>(null)
    fun tt(ru: String, en: String) = if (lang == "en") en else ru

    var ramFree by mutableLongStateOf(0L)
    var ramTotal by mutableLongStateOf(1L)
    var stFree by mutableLongStateOf(0L)
    var stTotal by mutableLongStateOf(1L)
    var bat by mutableStateOf(Sys.battery(app))
    var saver by mutableStateOf(false)
    var usageOk by mutableStateOf(false)
    var filesOk by mutableStateOf(false)
    var mediaOk by mutableStateOf(false)
    var dndOk by mutableStateOf(false)
    var hot by mutableStateOf(false)

    var apps by mutableStateOf<List<AppInfo>>(emptyList())
    var appsLoading by mutableStateOf(false)
    var stor by mutableStateOf<Stor?>(null)
    var fg by mutableStateOf<List<Pair<AppInfo, Long>>>(emptyList())
    var sens by mutableStateOf<Map<String, Set<String>>>(emptyMap())
    var permsBusy by mutableStateOf(false)
    var netRes by mutableStateOf<NetRes?>(null)
    var netBusy by mutableStateOf(false)
    var mon by mutableStateOf<List<Int?>>(listOf(null, null, null, null))
    private val cpuS = Sys.CpuSampler()
    var histVer by mutableIntStateOf(0)

    // ---- очистка ----
    var cats by mutableStateOf<List<Cat>?>(null)
    var selF by mutableStateOf(setOf<String>())
    var detail by mutableStateOf<String?>(null)
    var phase by mutableStateOf("idle") // idle, scanning, found, cleaning, done
    var stage by mutableStateOf("")
    var progress by mutableFloatStateOf(0f)
    var freed by mutableLongStateOf(0L)
    var quickBusy by mutableStateOf(false)
    var legacyAsk: (() -> Unit)? = null

    // ---- игры ----
    var gProf by mutableStateOf(prefs.gProf)
    var gMode by mutableIntStateOf(prefs.gMode)
    var gSel by mutableStateOf<String?>(null)
    var gBusy by mutableStateOf(false)
    var gReady by mutableStateOf(false)
    var report by mutableStateOf<List<Rep>>(emptyList())
    var ramBefore by mutableLongStateOf(0L)
    var ramAfter by mutableLongStateOf(0L)
    private var dndAt = 0L
    private var usagePending = false

    init { Notify.schedule(app, notif); refresh() }

    fun changeLang(l: String) { lang = l; prefs.lang = l }
    fun changeNotif(on: Boolean) { notif = on; prefs.notif = on; Notify.schedule(c, on) }
    fun changeGameMode(on: Boolean) { gameMode = on; prefs.gameMode = on }
    fun changeProf(p: String) { gProf = p; prefs.gProf = p; gReady = false }
    fun changeGMode(m: Int) { gMode = m; prefs.gMode = m; gReady = false }
    fun addGame(pkg: String) { prefs.games = prefs.games + pkg }
    fun userGames(): Set<String> = prefs.games
    fun appOf(pkg: String?) = apps.firstOrNull { it.pkg == pkg }

    fun refresh() {
        Sys.mem(c).let { ramFree = it.first; ramTotal = it.second }
        Sys.storage().let { stFree = it.first; stTotal = it.second }
        bat = Sys.battery(c); saver = Sys.powerSave(c); hot = bat.tempC >= 42f
        usageOk = Sys.hasUsage(c); filesOk = Sys.hasFiles(c); mediaOk = Sys.hasMedia(c); dndOk = Sys.hasDnd(c)
    }

    fun onResume() {
        refresh()
        if (System.currentTimeMillis() - dndAt > 4000) restoreDnd()
        if (usagePending) { usagePending = false; if (!usageOk) restrictedHelp() }
    }

    /** Переключатель серый: Android блокирует «ограниченные настройки» у приложений, установленных из APK. */
    fun restrictedHelp() {
        explain = Explain(
            tt("Переключатель серый?", "Switch is greyed out?"),
            tt("Android блокирует такие доступы у приложений, установленных из APK («ограниченные настройки»). Как разблокировать:\n1. Нажмите «Продолжить» — откроется экран «О приложении» Black Boost.\n2. Нажмите кнопку с тремя точками в правом верхнем углу и выберите «Разрешить ограниченные настройки».\n3. Вернитесь в «Доступ к данным об использовании» и включите переключатель.\n\nЕсли трёх точек нет, один раз нажмите на серый переключатель — пункт появится.",
                "Android blocks such access for apps installed from an APK (“restricted settings”). To unblock:\n1. Tap Continue — the Black Boost app info screen opens.\n2. Tap the three-dot button at the top right and choose “Allow restricted settings”.\n3. Go back to “Usage access” and turn the switch on.\n\nIf there are no three dots, tap the greyed-out switch once and the option will appear.")
        ) { Sys.appInfo(c, c.packageName) }
    }

    /** Оценка 0..100 по реальным показателям. */
    val score: Int
        get() {
            val ram = minOf(35f, ramFree * 100f / ramTotal / 45f * 35f)
            val st = minOf(35f, stFree * 100f / stTotal / 30f * 35f)
            val j = cats?.sumOf { it.bytes }
            val jp = if (j == null) 10f else maxOf(0f, 20f - j / 1_000_000f / 50f)
            val bp = if (bat.tempC < 40f) 10f else if (bat.tempC < 45f) 5f else 0f
            return (ram + st + jp + bp).toInt().coerceIn(0, 100)
        }

    // ---- запросы разрешений с объяснением ----
    fun askFiles() {
        explain = Explain(
            tt("Доступ к файлам", "File access"),
            tt("Нужен, чтобы найти кэш, старые загрузки, большие файлы и дубликаты фото и видео и заранее показать, сколько места освободится. Удаляется только то, что вы отметили.",
                "Needed to find cache, old downloads, large files and duplicate photos/videos and show how much space will be freed. Only what you select is deleted.")
        ) { if (Build.VERSION.SDK_INT >= 30) Sys.filesSettings(c) else legacyAsk?.invoke() }
    }

    fun askUsage() {
        explain = Explain(
            tt("Доступ к статистике использования", "Usage access"),
            tt("Нужен, чтобы показать размер приложений, давно не используемые приложения и время на экране. Данные остаются на телефоне.",
                "Needed to show app sizes, unused apps and screen time. Data stays on your phone.")
        ) { usagePending = true; Sys.usageSettings(c) }
    }

    fun askDnd() {
        explain = Explain(
            tt("Доступ «Не беспокоить»", "Do Not Disturb access"),
            tt("Нужен, чтобы на время игры скрывать уведомления и вернуть прежний режим после неё.",
                "Needed to silence notifications during a game and restore your previous mode afterwards.")
        ) { Sys.dnd(c) }
    }

    // ---- данные ----
    fun loadApps() {
        viewModelScope.launch { appsLoading = true; apps = withContext(Dispatchers.IO) { Sys.apps(c) }; appsLoading = false }
    }

    fun loadStorage() {
        viewModelScope.launch {
            if (apps.isEmpty()) apps = withContext(Dispatchers.IO) { Sys.apps(c) }
            stor = withContext(Dispatchers.IO) { Sys.stor(c, if (usageOk) apps else emptyList()) }
        }
    }

    fun loadFg() {
        viewModelScope.launch {
            if (apps.isEmpty()) apps = withContext(Dispatchers.IO) { Sys.apps(c) }
            val m = withContext(Dispatchers.IO) { Sys.fgUsage(c) }
            fg = apps.mapNotNull { a -> m[a.pkg]?.takeIf { it > 60000L }?.let { a to it } }.sortedByDescending { it.second }.take(6)
        }
    }

    fun loadSens() {
        viewModelScope.launch {
            permsBusy = true
            if (apps.isEmpty()) apps = withContext(Dispatchers.IO) { Sys.apps(c) }
            sens = withContext(Dispatchers.IO) { Sys.sensitive(c, apps.map { it.pkg }) }
            permsBusy = false
        }
    }

    fun runNet() {
        if (netBusy) return
        netBusy = true; netRes = null
        viewModelScope.launch { netRes = Net.test(c); netBusy = false }
    }

    fun pollMon() {
        refresh()
        mon = listOf(cpuS.read() ?: Sys.cpu(), Sys.gpu(), bat.tempC.toInt(), ((ramTotal - ramFree) * 100 / ramTotal).toInt())
    }

    // ---- очистка ----
    fun scanClean() {
        if (phase == "scanning" || phase == "cleaning") return
        if (!filesOk) { askFiles(); return }
        phase = "scanning"; stage = ""
        viewModelScope.launch {
            val r = Cleaner.scan(c) { stage = it }
            cats = r; selF = r.flatMap { it.files }.filter { it.def }.map { it.path }.toSet(); phase = "found"
        }
    }

    fun selBytes(): Long = cats?.sumOf { k -> k.files.filter { it.path in selF }.sumOf { it.size } } ?: 0L
    fun catSelAll(k: Cat) = k.files.isNotEmpty() && k.files.all { it.path in selF }
    fun toggleCat(k: Cat) {
        val paths = k.files.map { it.path }
        selF = if (catSelAll(k)) selF - paths.toSet() else selF + paths
    }
    fun toggleFile(f: Fi) { selF = if (f.path in selF) selF - f.path else selF + f.path }

    fun cleanNow() {
        val all = cats ?: return
        var list = all.flatMap { it.files }.filter { it.path in selF }
        // защита: если выбраны все копии, оригинал остаётся
        val dupTotal = all.firstOrNull { it.id == "dup" }?.files?.groupBy { it.group }?.mapValues { it.value.size } ?: emptyMap()
        val keep = list.filter { it.group > 0 }.groupBy { it.group }
            .filter { (g, l) -> l.size >= (dupTotal[g] ?: Int.MAX_VALUE) }
            .values.mapNotNull { l -> l.firstOrNull { it.orig }?.path }.toSet()
        list = list.filter { it.path !in keep }
        phase = "cleaning"; progress = 0f
        viewModelScope.launch {
            freed = Cleaner.delete(list) { progress = it }
            prefs.addHist(freed); histVer++
            phase = "done"; cats = null; refresh()
        }
    }

    // ---- быстрая оптимизация ----
    fun quick() {
        explain = Explain(
            tt("Быстрая оптимизация", "Quick optimization"),
            tt("Приложение попросит Android завершить фоновые процессы (система может не выполнить запрос) и удалит безопасный мусор: собственный кэш и временные файлы. Личные файлы не затрагиваются.",
                "The app will ask Android to end background processes (the system may ignore it) and delete safe junk: its own cache and temp files. Personal files are not touched.")
        ) { runQuick() }
    }

    private fun runQuick() {
        if (quickBusy) return
        quickBusy = true
        viewModelScope.launch {
            val (f, _) = withContext(Dispatchers.IO) { Sys.boostRam(c) }
            val files = Cleaner.quick(c, filesOk)
            prefs.addHist(files); histVer++
            refresh(); quickBusy = false
            quickRes = QuickRes(f, files)
        }
    }

    // ---- Game Booster ----
    fun prepareGame() {
        val pkg = gSel ?: return
        if (gBusy) return
        gBusy = true; gReady = false; report = emptyList(); ramBefore = Sys.mem(c).first
        viewModelScope.launch {
            val r = ArrayList<Rep>()
            val (f, n) = withContext(Dispatchers.IO) { Sys.boostRam(c) }
            refresh(); ramAfter = ramFree
            r.add(Rep(tt("Запрос на завершение фоновых процессов отправлен ($n прил.). Освобождено: ${f.sz()}. Android может перезапустить часть процессов.",
                "Background process stop request sent ($n apps). Freed: ${f.sz()}. Android may restart some of them."), true))
            if (gMode >= 1) {
                val fr = Cleaner.cleanOwn(c)
                r.add(Rep(tt("Собственный кэш Black Boost очищен: ${fr.sz()}", "Black Boost cache cleared: ${fr.sz()}"), true))
            }
            if (gMode >= 2) {
                if (!gameMode) r.add(Rep(tt("Game Mode+ выключен: включите переключатель ниже", "Game Mode+ is off: turn on the switch below"), false))
                else if (dndOk) r.add(Rep(tt("«Не беспокоить» включится на время игры и вернётся после неё", "Do Not Disturb will turn on for the game and be restored afterwards"), true))
                else r.add(Rep(tt("«Не беспокоить»: нужен доступ, выдайте вручную", "Do Not Disturb: access needed, grant it manually"), false) { askDnd() })
            }
            if (gProf == "perf") {
                if (saver) r.add(Rep(tt("Энергосбережение Android включено и снижает производительность. Отключите вручную.", "Android power saving is on and reduces performance. Turn it off manually."), false) { Sys.saver(c) })
                else r.add(Rep(tt("Энергосбережение Android выключено", "Android power saving is off"), true))
                r.add(Rep(tt("Частота обновления: выберите максимальную (Настройки → Дисплей). Приложение не может менять её само.", "Refresh rate: choose the highest (Settings → Display). The app cannot change it."), false) { Sys.display(c) })
                r.add(Rep(tt("Графика: в настройках самой игры выберите высокий FPS и умеренное качество теней.", "Graphics: in the game's own settings pick high FPS and moderate shadow quality."), false))
            } else {
                if (!saver) r.add(Rep(tt("Включите энергосбережение Android вручную, чтобы сэкономить заряд", "Turn on Android power saving manually to save battery"), false) { Sys.saver(c) })
                else r.add(Rep(tt("Энергосбережение Android включено", "Android power saving is on"), true))
                r.add(Rep(tt("Частота обновления: выберите 60 Гц (Настройки → Дисплей).", "Refresh rate: choose 60 Hz (Settings → Display)."), false) { Sys.display(c) })
                r.add(Rep(tt("Графика: в настройках игры снизьте качество и ограничьте FPS.", "Graphics: in the game's settings lower quality and cap FPS."), false))
            }
            report = r; gBusy = false; gReady = true
        }
    }

    fun launchGame(a: Activity) {
        val pkg = gSel ?: return
        if (gameMode && gMode >= 2 && dndOk) dndOn()
        val i = c.packageManager.getLaunchIntentForPackage(pkg)
        if (i == null) { toast = tt("Не удалось запустить игру", "Could not launch the game"); return }
        a.startActivity(i)
    }

    private fun dndOn() {
        val nm = c.getSystemService(NotificationManager::class.java)
        if (nm.isNotificationPolicyAccessGranted) {
            prefs.dndPrev = nm.currentInterruptionFilter
            nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALARMS)
            dndAt = System.currentTimeMillis()
        }
    }

    private fun restoreDnd() {
        val p = prefs.dndPrev
        if (p >= 0) {
            val nm = c.getSystemService(NotificationManager::class.java)
            if (nm.isNotificationPolicyAccessGranted) nm.setInterruptionFilter(p)
            prefs.dndPrev = -1
        }
    }
}
BB_FINAL_18
mkdir -p "$(dirname 'app/src/main/java/com/blackboost/app/UI.kt')"
cat > 'app/src/main/java/com/blackboost/app/UI.kt' <<'BB_FINAL_19'
@file:OptIn(ExperimentalTextApi::class)

package com.blackboost.app

import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.*
import androidx.compose.foundation.text.BasicText
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.draw.*
import androidx.compose.ui.geometry.*
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.*
import androidx.compose.ui.graphics.vector.*
import androidx.compose.ui.text.*
import androidx.compose.ui.text.font.*
import androidx.compose.ui.text.style.*
import androidx.compose.ui.unit.*
import java.util.Locale

val Bg = Color(0xFF050505); val Sf = Color(0xFF0E0E0E); val Ln = Color(0xFF242120)
val Tx = Color(0xFFF4EFE8); val Mu = Color(0xFF8F8980); val Ink = Color(0xFF150500)
val Em = Color(0xFFFF5A1F); val Am = Color(0xFFFFB347); val Rd = Color(0xFFC1121F)
val Hot = Brush.linearGradient(listOf(Am, Em, Rd))

val Disp = FontFamily(
    Font(R.font.unbounded, FontWeight.Bold, variationSettings = FontVariation.Settings(FontVariation.weight(700))),
    Font(R.font.unbounded, FontWeight.Black, variationSettings = FontVariation.Settings(FontVariation.weight(900)))
)
val Body = FontFamily(
    Font(R.font.manrope, FontWeight.Medium, variationSettings = FontVariation.Settings(FontVariation.weight(500))),
    Font(R.font.manrope, FontWeight.SemiBold, variationSettings = FontVariation.Settings(FontVariation.weight(600))),
    Font(R.font.manrope, FontWeight.Bold, variationSettings = FontVariation.Settings(FontVariation.weight(700)))
)

val LocalLang = compositionLocalOf { "ru" }
@Composable fun t(ru: String, en: String) = if (LocalLang.current == "en") en else ru

fun Long.sz(): String = if (this >= 1_000_000_000L) String.format(Locale.US, "%.1f GB", this / 1e9) else String.format(Locale.US, "%d MB", this / 1_000_000)

fun icon(d: String): ImageVector = ImageVector.Builder(defaultWidth = 24.dp, defaultHeight = 24.dp, viewportWidth = 24f, viewportHeight = 24f).addPath(
    pathData = addPathNodes(d), stroke = SolidColor(Color.White), strokeLineWidth = 1.8f,
    strokeLineCap = StrokeCap.Round, strokeLineJoin = StrokeJoin.Round
).build()

object Ic {
    val home = icon("M3 11L12 4l9 7v9H3z")
    val trash = icon("M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13")
    val battery = icon("M8 5h8a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2zM10 2h4")
    val grid = icon("M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z")
    val gear = icon("M12 9a3 3 0 1 0 0 6 3 3 0 1 0 0-6zM12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M19 5l-2 2M7 17l-2 2")
    val back = icon("M15 5l-7 7 7 7")
    val db = icon("M4 6a8 3 0 1 0 16 0 8 3 0 1 0-16 0M4 6v6c0 1.7 3.6 3 8 3s8-1.3 8-3V6M4 12v6c0 1.7 3.6 3 8 3s8-1.3 8-3v-6")
    val bell = icon("M6 16V11a6 6 0 0 1 12 0v5l2 2H4zM10 21h4")
    val globe = icon("M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0zM3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18")
    val bolt = icon("M13 2L4 14h6l-1 8 9-12h-6z")
    val clock = icon("M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0zM12 7v5l3 2")
    val close = icon("M6 6l12 12M18 6L6 18")
    val play = icon("M5 3l14 9-14 9z")
    val chart = icon("M3 17l5-6 4 4 6-8M3 21h18")
    val info = icon("M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0zM12 11v6M12 7.5v0.01")
    val send = icon("M21 3L3 10.5l7 2.5 2.5 7L21 3zM10 13l5-5")
}

@Composable
fun Txt(
    s: String, size: Int = 15, color: Color = Tx, w: FontWeight = FontWeight.Medium, disp: Boolean = false,
    modifier: Modifier = Modifier, align: TextAlign? = null, brush: Brush? = null, deco: TextDecoration? = null, lines: Int = Int.MAX_VALUE
) {
    val fam = if (disp) Disp else Body
    if (brush != null) BasicText(s, modifier, TextStyle(brush = brush, fontSize = size.sp, fontWeight = w, fontFamily = fam, textAlign = align ?: TextAlign.Unspecified, textDecoration = deco), maxLines = lines, overflow = TextOverflow.Ellipsis)
    else Text(s, modifier, color = color, fontSize = size.sp, fontWeight = w, fontFamily = fam, textAlign = align, textDecoration = deco, maxLines = lines, overflow = TextOverflow.Ellipsis)
}

fun Modifier.card(r: Int = 18): Modifier = this.background(Sf, RoundedCornerShape(r.dp)).border(1.dp, Ln, RoundedCornerShape(r.dp))

@Composable
fun HotBtn(text: String, enabled: Boolean = true, onClick: () -> Unit) {
    Box(
        Modifier.fillMaxWidth().height(54.dp).clip(RoundedCornerShape(16.dp)).background(Hot, alpha = if (enabled) 1f else 0.4f)
            .clickable(enabled = enabled, onClick = onClick), Alignment.Center
    ) { Txt(text, 15, Ink, FontWeight.Bold) }
}

@Composable
fun Item(ic: ImageVector?, title: String, sub: String? = null, trail: (@Composable () -> Unit)? = null, onClick: (() -> Unit)? = null) {
    Row(
        Modifier.fillMaxWidth().card(16).then(if (onClick != null) Modifier.clip(RoundedCornerShape(16.dp)).clickable(onClick = onClick) else Modifier).padding(14.dp, 12.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        if (ic != null) Icon(ic, null, Modifier.size(24.dp), tint = Em)
        Column(Modifier.weight(1f)) { Txt(title, 15, w = FontWeight.SemiBold); if (sub != null) Txt(sub, 12, Mu) }
        trail?.invoke()
    }
}

@Composable
fun Tog(on: Boolean, onChange: (Boolean) -> Unit) {
    val x by animateDpAsState(if (on) 22.dp else 3.dp, label = "tog")
    Box(Modifier.width(46.dp).height(27.dp).clip(RoundedCornerShape(14.dp)).background(if (on) Em else Color(0xFF2A2725)).clickable { onChange(!on) }) {
        Box(Modifier.offset(x, 3.dp).size(21.dp).clip(CircleShape).background(Tx))
    }
}

@Composable
fun Tabs(l: List<String>, s: Int, on: (Int) -> Unit) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        l.forEachIndexed { i, x ->
            Box(
                Modifier.weight(1f).height(40.dp).clip(RoundedCornerShape(20.dp))
                    .then(if (i == s) Modifier.background(Hot) else Modifier.border(1.dp, Ln, RoundedCornerShape(20.dp)))
                    .clickable { on(i) }, Alignment.Center
            ) { Txt(x, 12, if (i == s) Ink else Mu, FontWeight.SemiBold) }
        }
    }
}

@Composable
fun Bar(p: Float) {
    Box(Modifier.fillMaxWidth().height(7.dp).clip(RoundedCornerShape(4.dp)).background(Color(0xFF1C1917))) {
        Box(Modifier.fillMaxWidth(p.coerceIn(0f, 1f)).fillMaxHeight().background(Hot))
    }
}

@Composable
fun Ring(p: Float, size: Dp, anim: Boolean = true, content: @Composable BoxScope.() -> Unit) {
    val a by animateFloatAsState(p.coerceIn(0f, 1f), tween(600), label = "ring")
    val v = if (anim) a else p.coerceIn(0f, 1f)
    Box(Modifier.size(size), Alignment.Center) {
        Canvas(Modifier.fillMaxSize()) {
            val s = this.size.width * 0.06f
            val tl = Offset(s, s)
            val sz = Size(this.size.width - 2 * s, this.size.height - 2 * s)
            drawArc(Color(0xFF1A1816), 0f, 360f, false, tl, sz, style = Stroke(s))
            rotate(-90f) {
                drawArc(Em.copy(alpha = 0.22f), 0f, 360f * v, false, tl, sz, style = Stroke(s * 2f, cap = StrokeCap.Round))
                drawArc(Brush.sweepGradient(listOf(Am, Em, Rd)), 0f, 360f * v, false, tl, sz, style = Stroke(s, cap = StrokeCap.Round))
            }
        }
        content()
    }
}

@Composable
fun Donut(parts: List<Pair<Float, Color>>, size: Dp, content: @Composable BoxScope.() -> Unit) {
    Box(Modifier.size(size), Alignment.Center) {
        Canvas(Modifier.fillMaxSize()) {
            val s = this.size.width * 0.12f
            val tl = Offset(s / 2, s / 2)
            val sz = Size(this.size.width - s, this.size.height - s)
            drawArc(Color(0xFF1C1917), 0f, 360f, false, tl, sz, style = Stroke(s))
            var a = -90f
            parts.forEach { (f, c) ->
                val sw = f * 360f
                if (sw > 1f) drawArc(c, a, sw - 1.5f, false, tl, sz, style = Stroke(s))
                a += sw
            }
        }
        content()
    }
}

/** Ровная галочка: рисуется вертикально, без поворотов. */
@Composable
fun CheckMark(size: Dp, color: Color = Tx) {
    val p = remember { Animatable(0f) }
    LaunchedEffect(Unit) { p.animateTo(1f, tween(500)) }
    Canvas(Modifier.size(size)) {
        val w = this.size.width
        val path = Path().apply { moveTo(w * 0.2f, w * 0.52f); lineTo(w * 0.43f, w * 0.74f); lineTo(w * 0.8f, w * 0.3f) }
        val seg = Path()
        val pm = PathMeasure()
        pm.setPath(path, false)
        pm.getSegment(0f, pm.length * p.value, seg, true)
        drawPath(seg, color, style = Stroke(w * 0.1f, cap = StrokeCap.Round, join = StrokeJoin.Round))
    }
}

@Composable
fun MiniCheck(on: Boolean) {
    Box(
        Modifier.size(22.dp).clip(CircleShape).then(if (on) Modifier.background(Hot) else Modifier.border(2.dp, Color(0xFF4A4540), CircleShape)),
        Alignment.Center
    ) { if (on) CheckMark(14.dp, Ink) }
}

@Composable
fun TopBar(title: String, back: Boolean, onBack: () -> Unit) {
    Row(Modifier.fillMaxWidth().padding(20.dp, 16.dp, 20.dp, 8.dp), verticalAlignment = Alignment.CenterVertically) {
        if (back) Box(Modifier.size(40.dp).clip(CircleShape).background(Sf).border(1.dp, Ln, CircleShape).clickable(onClick = onBack), Alignment.Center) { Icon(Ic.back, null, Modifier.size(20.dp), tint = Tx) }
        else Spacer(Modifier.size(40.dp))
        Txt(title, 19, disp = true, w = FontWeight.Bold, modifier = Modifier.weight(1f), align = TextAlign.Center)
        Spacer(Modifier.size(40.dp))
    }
}

@Composable
fun NavBar(cur: Screen, go: (Screen) -> Unit) {
    val items = listOf(
        Triple(Screen.Home, Ic.home, t("Главная", "Home")), Triple(Screen.Clean, Ic.trash, t("Очистка", "Cleaner")),
        Triple(Screen.Battery, Ic.battery, t("Батарея", "Battery")), Triple(Screen.Apps, Ic.grid, t("Приложения", "Apps")),
        Triple(Screen.Settings, Ic.gear, t("Настройки", "Settings"))
    )
    Row(Modifier.fillMaxWidth().background(Color(0xFF070707)).navigationBarsPadding().padding(4.dp, 8.dp)) {
        items.forEach { (s, i, l) ->
            Column(Modifier.weight(1f).clickable { go(s) }.padding(vertical = 6.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(4.dp)) {
                val c = if (s == cur) Em else Mu
                Icon(i, null, Modifier.size(22.dp), tint = c)
                Txt(l, 10, c, FontWeight.SemiBold, align = TextAlign.Center)
            }
        }
    }
}

val Ok = Color(0xFF3DDC84); val Warn = Color(0xFFFFC107); val Off = Color(0xFF8F8980); val Bad = Color(0xFFFF5252)

@Composable
fun Dot(c: Color) { Box(Modifier.size(9.dp).clip(CircleShape).background(c)) }
BB_FINAL_19
mkdir -p "$(dirname 'app/src/main/java/com/blackboost/app/Screens.kt')"
cat > 'app/src/main/java/com/blackboost/app/Screens.kt' <<'BB_FINAL_20'
@file:Suppress("DEPRECATION")

package com.blackboost.app

import android.Manifest
import android.app.Activity
import android.content.Context
import android.os.Build
import android.os.PowerManager
import android.view.WindowManager
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.*
import androidx.compose.material3.Icon
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.draw.*
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.*
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.core.content.ContextCompat
import kotlinx.coroutines.*

@Composable
fun App(vm: Vm, act: Activity) {
    BackHandler(enabled = vm.screen != Screen.Home && vm.screen != Screen.Splash) { vm.back() }
    Box(Modifier.fillMaxSize().background(Bg)) {
        when (vm.screen) {
            Screen.Splash -> SplashS(vm)
            Screen.Home -> HomeS(vm)
            Screen.Clean -> CleanS(vm)
            Screen.Battery -> BatteryS(vm)
            Screen.Apps -> AppsS(vm)
            Screen.Storage -> StorageS(vm)
            Screen.Fps -> GameS(vm, act)
            Screen.Settings -> SettingsS(vm)
            Screen.Monitor -> MonitorS(vm)
            Screen.Perms -> PermsS(vm)
            Screen.Net -> NetS(vm)
            Screen.Faq -> FaqS(vm)
        }
        vm.toast?.let {
            Box(Modifier.align(Alignment.BottomCenter).padding(24.dp, 0.dp, 24.dp, 100.dp).clip(RoundedCornerShape(14.dp)).background(Color(0xFF1A1512)).padding(16.dp, 12.dp)) {
                Txt(it, 13, w = androidx.compose.ui.text.font.FontWeight.SemiBold, align = TextAlign.Center)
            }
            LaunchedEffect(it) { delay(2800); vm.toast = null }
        }
        vm.explain?.let { e ->
            Dialog(onDismissRequest = { vm.explain = null }) {
                Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(24.dp)).background(Bg).border(1.dp, Ln, RoundedCornerShape(24.dp)).padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    Txt(e.title, 18, w = FontWeight.Bold)
                    Txt(e.text, 14, Mu)
                    HotBtn(t("Продолжить", "Continue")) { vm.explain = null; e.action() }
                    Txt(t("Отмена", "Cancel"), 14, Mu, modifier = Modifier.fillMaxWidth().clickable { vm.explain = null }.padding(8.dp), align = TextAlign.Center)
                }
            }
        }
        vm.quickRes?.let { r ->
            Dialog(onDismissRequest = { vm.quickRes = null }) {
                Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(24.dp)).background(Bg).border(1.dp, Ln, RoundedCornerShape(24.dp)).padding(20.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Txt(t("Оптимизация завершена", "Optimization complete"), 18, w = FontWeight.Bold)
                    Item(Ic.chart, t("ОЗУ освобождено", "RAM freed"), if (r.ram > 0) r.ram.sz() else t("Android не освободил заметный объём. Это нормально.", "Android did not free a noticeable amount. That is normal."))
                    Item(Ic.trash, t("Мусор удалён", "Junk deleted"), if (r.files > 0) r.files.sz() else t("Безопасного мусора не найдено", "No safe junk found"))
                    Txt(t("Советы", "Tips"), 14, w = FontWeight.Bold)
                    tips(vm).take(3).forEach { Txt("• $it", 12, Mu) }
                    HotBtn("OK") { vm.quickRes = null }
                }
            }
        }
    }
}

@Composable
fun Page(vm: Vm, cur: Screen?, title: String?, back: Boolean = false, bottom: (@Composable () -> Unit)? = null, content: @Composable ColumnScope.() -> Unit) {
    Column(Modifier.fillMaxSize().statusBarsPadding()) {
        if (title != null) TopBar(title, back) { vm.back() }
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(20.dp, 8.dp), verticalArrangement = Arrangement.spacedBy(12.dp), content = content)
        if (bottom != null) Box(Modifier.padding(20.dp, 4.dp, 20.dp, 12.dp)) { bottom() }
        if (cur != null) NavBar(cur) { vm.go(it, true) }
    }
}

@Composable
fun SplashS(vm: Vm) {
    val p = remember { Animatable(0f) }
    val sc = remember { Animatable(0.6f) }
    val glow by rememberInfiniteTransition(label = "g").animateFloat(0.25f, 0.6f, infiniteRepeatable(tween(1000), RepeatMode.Reverse), label = "g")
    LaunchedEffect(Unit) {
        launch { sc.animateTo(1f, tween(700)) }
        p.animateTo(1f, tween(2000, easing = LinearEasing))
        vm.go(Screen.Home, true)
    }
    Column(Modifier.fillMaxSize().padding(32.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Spacer(Modifier.weight(1f))
        Box(contentAlignment = Alignment.Center) {
            Box(Modifier.size(280.dp).background(Brush.radialGradient(listOf(Em.copy(alpha = glow), Color.Transparent))))
            Image(painterResource(R.drawable.ic_logo), null, Modifier.height(130.dp).aspectRatio(636f / 603f).scale(sc.value))
        }
        Spacer(Modifier.height(20.dp))
        Txt("Black", 50, disp = true, w = androidx.compose.ui.text.font.FontWeight.Black)
        Txt("Boost", 50, disp = true, w = androidx.compose.ui.text.font.FontWeight.Black, brush = Hot)
        Spacer(Modifier.weight(1f))
        Box(Modifier.width(200.dp)) { Bar(p.value) }
        Spacer(Modifier.height(12.dp))
        Txt(t("Загрузка...", "Loading..."), 12, Mu)
    }
}

@Composable
fun RowScope.Tile(i: ImageVector, l: String, v: String, on: () -> Unit) =
    Column(Modifier.weight(1f).fillMaxHeight().clip(RoundedCornerShape(18.dp)).card().clickable(onClick = on).padding(16.dp), verticalArrangement = Arrangement.SpaceBetween) {
        Icon(i, null, Modifier.size(26.dp), tint = Em)
        Column { Txt(l, 14, w = FontWeight.SemiBold, lines = 1); Txt(v, if (v.length > 8) 13 else 17, Am, FontWeight.Bold, true, lines = 1) }
    }

@Composable
fun StorageS(vm: Vm) {
    val ctx = LocalContext.current
    val perm = rememberLauncherForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) { vm.refresh(); vm.loadStorage() }
    LaunchedEffect(vm.usageOk, vm.mediaOk) { vm.loadStorage() }
    val s = vm.stor
    val tot = (s?.total ?: vm.stTotal).toFloat()
    val used = tot - vm.stFree
    val parts = s?.let { listOf(it.apps to Em, it.media to Am, it.docs to Color(0xFFE8DCCB), it.cache to Rd, it.other to Color(0xFF4A4540)) } ?: emptyList()
    val names = listOf(t("Приложения", "Apps"), t("Фото и видео", "Photos & video"), t("Документы", "Documents"), t("Кэш", "Cache"), t("Система и другое", "System & other"))
    val bold = androidx.compose.ui.text.font.FontWeight.Bold
    Page(vm, null, t("Хранилище", "Storage"), true, bottom = { HotBtn(t("Очистить мусор", "Clean junk")) { vm.go(Screen.Clean) } }) {
        Box(Modifier.fillMaxWidth(), Alignment.Center) {
            Donut(parts.map { it.first / tot to it.second }, 220.dp) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Txt("${(used / tot * 100).toInt()}%", 40, disp = true, w = androidx.compose.ui.text.font.FontWeight.Black)
                    Txt(t("Занято", "Used"), 13, Mu)
                }
            }
        }
        Column(Modifier.fillMaxWidth().card().padding(16.dp, 8.dp)) {
            parts.forEachIndexed { i, (v, c) ->
                Row(Modifier.padding(vertical = 8.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Box(Modifier.size(10.dp).clip(CircleShape).background(c))
                    Txt(names[i], 14, modifier = Modifier.weight(1f)); Txt(v.sz(), 14, w = bold)
                }
            }
        }
        if (!vm.usageOk) Item(Ic.grid, t("Доступ к статистике", "Usage access"), t("Нужен для размера приложений и кэша", "Needed for app sizes and cache"),
            trail = { Txt(t("Дать", "Grant"), 13, Am, bold) }) { Sys.usageSettings(ctx) }
        if (!vm.mediaOk) Item(Ic.db, t("Доступ к фото и видео", "Photos & video access"), t("Нужен для подсчёта медиа", "Needed to count media"),
            trail = { Txt(t("Дать", "Grant"), 13, Am, bold) }) {
            perm.launch(if (Build.VERSION.SDK_INT >= 33) arrayOf(Manifest.permission.READ_MEDIA_IMAGES, Manifest.permission.READ_MEDIA_VIDEO) else arrayOf(Manifest.permission.READ_EXTERNAL_STORAGE))
        }
        Column(Modifier.fillMaxWidth().card().padding(16.dp)) {
            Txt(t("Свободно места", "Free space"), 12, Mu)
            Txt(vm.stFree.sz(), 20, Am, bold, true)
            Spacer(Modifier.height(10.dp)); Bar(vm.stFree / tot)
        }
    }
}

@Composable
fun SettingsS(vm: Vm) {
    val ctx = LocalContext.current
    val perm = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { ok -> vm.changeNotif(ok) }
    val bold = androidx.compose.ui.text.font.FontWeight.Bold
    Page(vm, Screen.Settings, t("Настройки", "Settings")) {
        Column(Modifier.fillMaxWidth().card().padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                Icon(Ic.globe, null, Modifier.size(24.dp), tint = Em); Txt(t("Язык", "Language"), 15, w = bold)
            }
            Tabs(listOf("Русский", "English"), if (vm.lang == "en") 1 else 0) { vm.changeLang(if (it == 1) "en" else "ru") }
        }
        Item(Ic.bell, t("Уведомления", "Notifications"), t("Напоминания: мало места, перегрев", "Reminders: low storage, overheating"), trail = {
            Tog(vm.notif) { on ->
                if (on && Build.VERSION.SDK_INT >= 33 && ContextCompat.checkSelfPermission(ctx, Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED)
                    perm.launch(Manifest.permission.POST_NOTIFICATIONS)
                else vm.changeNotif(on)
            }
        })
        Item(Ic.info, t("Ответы на часто задаваемые вопросы", "Frequently asked questions"), t("Доступы, предупреждения, как всё работает", "Permissions, warnings, how it all works"),
            trail = { Txt("›", 22, Mu) }) { vm.go(Screen.Faq) }
        Item(Ic.send, t("Наш Telegram", "Our Telegram"), "t.me/blackboostoff",
            trail = { Txt("›", 22, Mu) }) { Sys.openUrl(ctx, "https://t.me/blackboostoff") }
        Spacer(Modifier.height(8.dp))
        Txt("Сделано проектом \"BlackWeb Project\". @blackwebproject", 10, Mu, modifier = Modifier.fillMaxWidth(), align = TextAlign.Center)
    }
}


@Composable
fun HomeS(vm: Vm) {
    LaunchedEffect(Unit) { while (true) { vm.refresh(); delay(3000) } }
    LaunchedEffect(vm.usageOk) { vm.loadApps() }
    val bold = FontWeight.Bold
    val junk = vm.cats?.sumOf { it.bytes }
    Page(vm, Screen.Home, null) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Image(painterResource(R.drawable.ic_logo), null, Modifier.height(26.dp).aspectRatio(636f / 603f))
            Txt("Black Boost", 19, disp = true, w = bold)
        }
        Box(Modifier.fillMaxWidth(), Alignment.Center) {
            Ring(vm.score / 100f, 230.dp) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Txt("${vm.score}", 52, disp = true, w = FontWeight.Black)
                    Txt(t("Состояние", "Status"), 13, Mu)
                }
            }
        }
        Txt(
            if (vm.hot) t("Телефон нагрелся: ${vm.bat.tempC}°C", "Phone is hot: ${vm.bat.tempC}°C")
            else if (vm.score >= 80) t("Устройство в хорошем состоянии", "Device is in good shape") else t("Есть что оптимизировать", "There is room to optimize"),
            14, if (vm.hot) Bad else Mu, modifier = Modifier.fillMaxWidth(), align = TextAlign.Center
        )
        HotBtn(if (vm.quickBusy) t("Оптимизируем...", "Optimizing...") else t("Оптимизировать сейчас", "Optimize now"), !vm.quickBusy) { vm.quick() }
        Row(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(Brush.horizontalGradient(listOf(Color(0xFF2A1208), Sf)))
                .border(1.dp, Color(0xFF5A2C1A), RoundedCornerShape(18.dp)).clickable { vm.go(Screen.Fps) }.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Icon(Ic.bolt, null, Modifier.size(26.dp), tint = Em)
            Column(Modifier.weight(1f)) {
                Txt("FPS Boost", 16, disp = true, w = bold)
                Txt(t("Игры, профили и запуск", "Games, profiles and launch"), 12, Mu)
            }
            Txt("›", 22, Am)
        }
        Row(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).card().clickable { vm.go(Screen.Monitor) }.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Icon(Ic.chart, null, Modifier.size(26.dp), tint = Em)
            Column(Modifier.weight(1f)) {
                Txt(t("Мониторинг устройства", "Device monitor"), 16, w = bold)
                Txt(t("RAM, CPU, температура, сеть, разрешения", "RAM, CPU, temperature, network, permissions"), 12, Mu)
            }
            Txt("›", 22, Am)
        }
        Row(Modifier.fillMaxWidth().height(IntrinsicSize.Max), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Tile(Ic.trash, t("Очистка", "Cleaner"), junk?.sz() ?: t("Сканировать", "Scan")) { vm.go(Screen.Clean, true) }
            Tile(Ic.battery, t("Батарея", "Battery"), "${vm.bat.pct}%") { vm.go(Screen.Battery, true) }
        }
        Row(Modifier.fillMaxWidth().height(IntrinsicSize.Max), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Tile(Ic.grid, t("Кэш приложений", "App cache"), if (vm.usageOk) vm.apps.sumOf { it.cache }.sz() else "—") { vm.go(Screen.Apps, true) }
            Tile(Ic.db, t("Свободно", "Free"), vm.stFree.sz()) { vm.go(Screen.Storage) }
        }
    }
}

@Composable
fun CleanS(vm: Vm) {
    val perm = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { vm.refresh() }
    SideEffect { vm.legacyAsk = { perm.launch(Manifest.permission.WRITE_EXTERNAL_STORAGE) } }
    LaunchedEffect(Unit) { if (vm.phase == "done") vm.phase = "idle"; vm.detail = null }
    val inf by rememberInfiniteTransition(label = "s").animateFloat(0f, 1f, infiniteRepeatable(tween(1400, easing = LinearEasing)), label = "s")
    val cats = vm.cats
    val tot = cats?.sumOf { it.bytes } ?: 0L
    val selB = vm.selBytes()
    val det = vm.detail?.let { id -> cats?.firstOrNull { it.id == id } }
    val bold = FontWeight.Bold
    Page(vm, Screen.Clean, if (det != null) t(det.ru, det.en) else t("Очистка", "Cleaner"), back = det != null, bottom = {
        when {
            vm.phase == "done" -> HotBtn(t("Готово", "Done")) { vm.go(Screen.Home, true) }
            vm.phase == "scanning" -> HotBtn(t("Сканируем...", "Scanning..."), false) {}
            vm.phase == "cleaning" -> HotBtn(t("Идёт очистка...", "Cleaning..."), false) {}
            det != null -> HotBtn(t("Готово · ", "Done · ") + selB.sz()) { vm.detail = null }
            cats != null && tot > 0 -> HotBtn(t("Очистить ", "Clean ") + selB.sz(), selB > 0) { vm.cleanNow() }
            else -> HotBtn(t("СКАНИРОВАТЬ УСТРОЙСТВО", "SCAN DEVICE")) { vm.scanClean() }
        }
    }) {
        if (det != null) {
            Txt(t("Отметьте файлы, которые хотите удалить.", "Select the files you want to delete."), 12, Mu)
            if (det.id == "dup") Txt(t("Оригинал (самая старая копия) по умолчанию остаётся. Если выбрать все копии, оригинал всё равно сохранится.", "The original (oldest copy) stays by default. If every copy is selected, the original is still kept."), 11, Mu)
            det.files.take(200).forEach { f ->
                Item(null, f.file.name, (if (f.orig) t("оригинал · ", "original · ") else "") + f.file.parent?.removePrefix("/storage/emulated/0")?.ifEmpty { "/" },
                    trail = { Txt(f.size.sz(), 12, Am, bold); Spacer(Modifier.width(10.dp)); MiniCheck(f.path in vm.selF) }) { vm.toggleFile(f) }
            }
            if (det.files.size > 200) Txt(t("Показаны первые 200 файлов", "Showing the first 200 files"), 11, Mu)
        } else {
            Box(Modifier.fillMaxWidth(), Alignment.Center) {
                val rp = when (vm.phase) { "scanning" -> inf; "cleaning" -> vm.progress; "done" -> 1f; else -> if (cats != null && tot == 0L) 1f else 0f }
                Ring(rp, 220.dp, anim = vm.phase != "scanning") {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        when {
                            vm.phase == "done" -> { CheckMark(70.dp); Txt(vm.freed.sz(), 22, disp = true, w = bold); Txt(t("Освобождено", "Freed"), 12, Mu) }
                            vm.phase == "scanning" -> { Txt(t("Сканируем...", "Scanning..."), 15, Mu); Txt(if (vm.stage == "dups") t("ищем дубликаты", "finding duplicates") else t("ищем файлы", "finding files"), 11, Mu) }
                            vm.phase == "cleaning" -> Txt("${(vm.progress * 100).toInt()}%", 40, disp = true, w = FontWeight.Black)
                            cats == null -> { Txt(t("Устройство готово", "Device ready"), 14, Mu); Txt(t("к проверке", "to be scanned"), 14, Mu) }
                            tot > 0 -> { Txt(tot.sz(), 32, disp = true, w = FontWeight.Black); Txt(t("можно найти", "found"), 12, Mu) }
                            else -> { CheckMark(70.dp); Txt(t("Очищать нечего", "Nothing to clean"), 13, Mu) }
                        }
                    }
                }
            }
            if (cats != null && vm.phase == "found" && tot > 0) Txt(t("Освободится: ", "Will free: ") + selB.sz(), 15, Am, bold, modifier = Modifier.fillMaxWidth(), align = TextAlign.Center)
            if (!vm.filesOk) Item(Ic.db, t("Нужен доступ к файлам", "File access needed"), t("Без него сканирование недоступно", "Scanning is unavailable without it"),
                trail = { Txt(t("Дать", "Grant"), 13, Am, bold) }) { vm.askFiles() }
            if (vm.phase == "found") cats?.forEach { k ->
                Item(null, t(k.ru, k.en), "${k.files.size} " + t("файлов", "files") + " · " + k.bytes.sz(), trail = {
                    if (k.files.isNotEmpty()) {
                        MiniCheck(vm.catSelAll(k))
                        Box(Modifier.clickable { vm.detail = k.id }.padding(start = 10.dp, top = 6.dp, bottom = 6.dp)) { Txt("›", 22, Mu) }
                    }
                }) { if (k.files.isNotEmpty()) vm.toggleCat(k) }
            }
            if (vm.phase != "scanning" && vm.phase != "cleaning") {
                Txt(t("История очистки", "Cleaning history"), 16, w = bold, modifier = Modifier.padding(top = 6.dp))
                val v = vm.histVer
                Column(Modifier.fillMaxWidth().card().padding(16.dp, 8.dp)) {
                    listOf(1 to t("Сегодня", "Today"), 7 to t("7 дней", "7 days"), 30 to t("30 дней", "30 days")).forEach { (d, n) ->
                        Row(Modifier.padding(vertical = 8.dp)) { Txt(n, 14, modifier = Modifier.weight(1f)); Txt(vm.prefs.histSum(d + v * 0).sz(), 14, Am, bold) }
                    }
                }
            }
        }
    }
}

@Composable
fun BatteryS(vm: Vm) {
    val ctx = LocalContext.current
    val b = vm.bat
    val bold = FontWeight.Bold
    LaunchedEffect(vm.usageOk) { vm.loadFg() }
    LaunchedEffect(Unit) { while (true) { vm.refresh(); delay(3000) } }
    Page(vm, Screen.Battery, t("Батарея", "Battery")) {
        Column(Modifier.fillMaxWidth().card().padding(20.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(20.dp)) {
                Row(verticalAlignment = Alignment.Bottom) {
                    Txt("${b.pct}", 48, disp = true, w = FontWeight.Black)
                    Txt("%", 20, Mu, modifier = Modifier.padding(bottom = 6.dp))
                }
                Column {
                    Txt(if (b.charging) t("До полной зарядки", "Until full") else t("Осталось (оценка)", "Remaining (estimate)"), 12, Mu)
                    Txt(b.minutes?.let { "${it / 60} ${t("ч", "h")} ${it % 60} ${t("мин", "min")}" } ?: "—", 19, Am, bold, true)
                }
            }
            Spacer(Modifier.height(16.dp)); Bar(b.pct / 100f)
        }
        Item(Ic.chart, t("Температура батареи", "Battery temperature"),
            if (vm.hot) t("Перегрев: закройте тяжёлые приложения", "Overheating: close heavy apps") else if (b.charging) t("Идёт зарядка", "Charging") else t("В норме", "Normal"),
            trail = { Txt("${b.tempC}°C", 15, if (vm.hot) Bad else Am, bold); Spacer(Modifier.width(8.dp)); Dot(if (vm.hot) Bad else Ok) })
        Item(Ic.battery, t("Энергосбережение Android", "Android power saving"), if (vm.saver) t("Включено", "On") else t("Выключено", "Off"),
            trail = { Tog(vm.saver) { Sys.saver(ctx) } }) { Sys.saver(ctx) }
        Item(Ic.clock, t("Фоновая активность", "Background activity"), t("Системный список оптимизации батареи", "System battery optimization list"),
            trail = { Txt("›", 22, Mu) }) { Sys.battOpt(ctx) }
        Txt(t("Приложения с высоким энергопотреблением", "High energy-use apps"), 16, w = bold, modifier = Modifier.padding(top = 6.dp))
        if (!vm.usageOk) Item(Ic.grid, t("Нужен доступ к статистике", "Usage access needed"), t("Покажет, какие приложения дольше всего были на экране", "Shows which apps were on screen longest"),
            trail = { Txt(t("Дать", "Grant"), 13, Am, bold) }) { vm.askUsage() }
        else if (vm.fg.isEmpty()) Txt(t("Пока нет данных за последние 24 часа.", "No data for the last 24 hours yet."), 12, Mu)
        else vm.fg.forEach { (a, ms) ->
            Row(Modifier.fillMaxWidth().card(16).padding(12.dp, 10.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                a.icon?.let { Image(it, null, Modifier.size(36.dp)) }
                Txt(a.label, 14, w = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                Txt("${ms / 60000} ${t("мин", "min")}", 13, Am, bold)
            }
        }
        Txt(t("Android не отдаёт точный расход батареи по приложениям, поэтому показано время на экране за 24 часа: это косвенный признак.", "Android does not expose exact per-app battery use, so screen time over 24 hours is shown as an indirect sign."), 11, Mu)
        Txt(t("Советы по экономии", "Saving tips"), 16, w = bold, modifier = Modifier.padding(top = 6.dp))
        tips(vm).forEach { Txt("• $it", 13, Mu) }
    }
}

@Composable
fun AppsS(vm: Vm) {
    val ctx = LocalContext.current
    var tab by remember { mutableIntStateOf(0) }
    var sel by remember { mutableStateOf<AppInfo?>(null) }
    LaunchedEffect(vm.usageOk) { vm.loadApps() }
    val now = System.currentTimeMillis()
    val list = when (tab) {
        1 -> vm.apps.sortedByDescending { it.bytes }
        2 -> vm.apps.filter { vm.usageOk && (it.lastUsed == 0L || now - it.lastUsed > 30L * 86400000) }.sortedByDescending { it.bytes }
        else -> vm.apps
    }
    val bold = FontWeight.Bold
    Page(vm, Screen.Apps, t("Приложения", "Apps")) {
        Tabs(listOf(t("По имени", "By name"), t("По размеру", "By size"), t("Давно не нужны", "Unused")), tab) { tab = it }
        if (!vm.usageOk) Item(Ic.grid, t("Нужен доступ к статистике", "Usage access needed"),
            t("Покажет размер, кэш и давность запуска", "Shows size, cache and last use"),
            trail = { Txt(t("Дать", "Grant"), 13, Am, bold) }) { vm.askUsage() }
        if (!vm.usageOk) Txt(t("Переключатель серый? Нажмите сюда", "Switch greyed out? Tap here"), 12, Am, modifier = Modifier.clickable { vm.restrictedHelp() }.padding(vertical = 4.dp))
        if (tab == 2 && !vm.usageOk) Txt(t("Поиск неиспользуемых приложений работает только с доступом к статистике.", "Finding unused apps works only with usage access."), 12, Mu)
        if (tab == 2 && vm.usageOk) Txt(t("Не запускались больше 30 дней.", "Not opened for more than 30 days."), 12, Mu)
        if (vm.appsLoading && vm.apps.isEmpty()) Txt(t("Загрузка...", "Loading..."), 13, Mu)
        list.forEach { a ->
            Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).card(16).clickable { sel = a }.padding(12.dp, 10.dp),
                verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                a.icon?.let { Image(it, null, Modifier.size(40.dp)) }
                Column(Modifier.weight(1f)) {
                    Txt(a.label, 15, w = FontWeight.SemiBold)
                    Txt(if (vm.usageOk) a.bytes.sz() + " · " + t("кэш ", "cache ") + a.cache.sz() else a.bytes.sz() + " · " + t("размер установки", "install size"), 12, Mu)
                }
                Txt("›", 20, Mu)
            }
        }
    }
    sel?.let { a ->
        Dialog(onDismissRequest = { sel = null }) {
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(24.dp)).background(Bg).border(1.dp, Ln, RoundedCornerShape(24.dp)).padding(18.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Txt(a.label, 18, w = bold)
                Item(Ic.gear, t("Настройки приложения", "App settings"), t("Системный экран: кэш, права, остановка", "System screen: cache, permissions, stop")) { Sys.appInfo(ctx, a.pkg); sel = null }
                Item(Ic.close, t("Остановить", "Stop"), t("Запрос на завершение фоновых процессов", "Request to end background processes")) {
                    ctx.getSystemService(android.app.ActivityManager::class.java).killBackgroundProcesses(a.pkg)
                    vm.toast = vm.tt("Запрос отправлен", "Request sent"); sel = null
                }
                Item(Ic.trash, t("Удалить", "Uninstall"), t("С подтверждением системы", "With system confirmation")) { Sys.uninstall(ctx, a.pkg); sel = null }
            }
        }
    }
}

@Composable
fun GameS(vm: Vm, act: Activity) {
    val ctx = LocalContext.current
    var add by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { vm.loadApps(); vm.refresh() }
    LaunchedEffect(Unit) { while (true) { vm.pollMon(); delay(1000) } }
    val games = vm.apps.filter { it.game || it.pkg in vm.userGames() }
    val sel = vm.appOf(vm.gSel)
    val bold = FontWeight.Bold
    Page(vm, null, "FPS Boost", true, bottom = {
        HotBtn(
            when { vm.gBusy -> t("Проверяем...", "Checking..."); vm.gReady -> t("ЗАПУСТИТЬ ИГРУ", "LAUNCH GAME"); else -> t("Проверить и подготовить", "Check and prepare") },
            sel != null && !vm.gBusy
        ) { if (vm.gReady) vm.launchGame(act) else vm.prepareGame() }
    }) {
        Box(Modifier.fillMaxWidth(), Alignment.Center) {
            Ring(vm.ramFree.toFloat() / vm.ramTotal, 190.dp) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Txt(vm.ramFree.sz(), 26, disp = true, w = FontWeight.Black)
                    Txt(t("свободно ОЗУ", "free RAM"), 12, Mu)
                }
            }
        }
        if (vm.gReady) Txt("RAM: ${vm.ramBefore.sz()} → ${vm.ramAfter.sz()}", 13, Am, bold, modifier = Modifier.fillMaxWidth(), align = TextAlign.Center)
        Tabs(listOf(t("Производительность", "Performance"), t("Экономия", "Saving")), if (vm.gProf == "perf") 0 else 1) { vm.changeProf(if (it == 0) "perf" else "save") }
        Tabs(listOf(t("Базовый", "Basic"), t("Высокий", "High"), t("Максимальный", "Maximum")), vm.gMode) { i ->
            if (vm.gBusy) return@Tabs
            vm.changeGMode(i)
        }
        Txt(t("Выберите игру", "Choose a game"), 14, w = bold)
        if (games.isEmpty()) Txt(t("Система не определила игры. Добавьте приложение вручную.", "The system found no games. Add an app manually."), 12, Mu)
        Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            games.forEach { a ->
                Column(
                    Modifier.width(76.dp).clip(RoundedCornerShape(14.dp))
                        .then(if (a.pkg == vm.gSel) Modifier.border(2.dp, Em, RoundedCornerShape(14.dp)) else Modifier)
                        .clickable { vm.gSel = a.pkg; vm.gReady = false; vm.report = emptyList() }.padding(6.dp),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    a.icon?.let { Image(it, null, Modifier.size(52.dp)) }
                    Txt(a.label, 11, Mu, align = TextAlign.Center)
                }
            }
            Column(Modifier.width(76.dp).clip(RoundedCornerShape(14.dp)).clickable { add = true }.padding(6.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                Box(Modifier.size(52.dp).clip(RoundedCornerShape(12.dp)).card(12), Alignment.Center) { Txt("+", 26, Am) }
                Txt(t("Добавить", "Add"), 11, Mu)
            }
        }
        if (vm.report.isNotEmpty()) {
            Txt(t("Что сделано", "What was done"), 14, w = bold)
            vm.report.forEach { r ->
                Item(null, if (r.ok) t("Применено", "Applied") else t("Нужно вручную", "Manual step"), r.text, trail = { Dot(if (r.ok) Ok else Warn) }) { r.fix?.invoke() }
            }
        } else Txt(t("После проверки здесь будет честный список: что приложение применило само, а что нужно изменить вручную.", "After the check you will see an honest list: what the app applied and what you must change manually."), 12, Mu)
        if (true) {
            val names = listOf("CPU", "GPU", t("Темп.", "Temp"), "RAM")
            val shown = vm.mon.indices.filter { vm.mon[it] != null }
            Column(Modifier.fillMaxWidth().card().padding(16.dp)) {
                Txt("Performance Monitor", 14, w = bold)
                Txt(t("Только данные, которые отдаёт ваше устройство", "Only data your device exposes"), 11, Mu)
                Spacer(Modifier.height(10.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    shown.forEach { i ->
                        Column(Modifier.weight(1f)) {
                            Txt(names[i], 11, Mu)
                            Txt("${vm.mon[i]}" + if (i == 2) "°" else "%", 17, Am, bold, true)
                            Spacer(Modifier.height(6.dp)); Bar((vm.mon[i] ?: 0) / (if (i == 2) 60f else 100f))
                        }
                    }
                }
            }
            Item(Ic.bolt, "Game Mode+", t("«Не беспокоить» на время игры (режим «Максимальный»)", "Do Not Disturb during the game (Maximum mode)"),
                trail = { Tog(vm.gameMode) { on -> vm.changeGameMode(on); if (on && !vm.dndOk) vm.askDnd() } })
        }
        Txt(t("Как настроить вручную", "Manual setup"), 14, w = bold, modifier = Modifier.padding(top = 4.dp))
        Txt(t("1. Частота обновления: Настройки → Дисплей → Частота обновления. Для игр выберите максимальную, для экономии 60 Гц.\n2. Графика: откройте настройки самой игры и выберите качество и лимит FPS под ваш телефон.\n3. Если телефон греется, снизьте качество графики и яркость.",
            "1. Refresh rate: Settings → Display → Refresh rate. Choose the highest for gaming, 60 Hz for saving.\n2. Graphics: open the game's own settings and pick quality and FPS cap for your phone.\n3. If the phone gets hot, lower graphics quality and brightness."), 12, Mu)
        Item(Ic.gear, t("Открыть настройки дисплея", "Open display settings"), null, trail = { Txt("›", 22, Mu) }) { Sys.display(ctx) }
    }
    if (add) Dialog(onDismissRequest = { add = false }) {
        Column(Modifier.fillMaxWidth().heightIn(max = 520.dp).clip(RoundedCornerShape(24.dp)).background(Bg).border(1.dp, Ln, RoundedCornerShape(24.dp)).verticalScroll(rememberScrollState()).padding(18.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Txt(t("Добавить как игру", "Add as a game"), 18, w = bold)
            vm.apps.filter { !(it.game || it.pkg in vm.userGames()) }.forEach { a ->
                Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp)).clickable { vm.addGame(a.pkg); vm.gSel = a.pkg; add = false }.padding(8.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                    a.icon?.let { Image(it, null, Modifier.size(34.dp)) }
                    Txt(a.label, 14, w = FontWeight.SemiBold)
                }
            }
        }
    }
}

@Composable
fun thermalName(s: Int?): String = when (s) {
    null -> "—"
    0 -> t("Норма", "Normal")
    1 -> t("Лёгкий нагрев", "Light")
    2 -> t("Умеренный нагрев", "Moderate")
    3 -> t("Сильный нагрев", "Severe")
    else -> t("Критический", "Critical")
}

@Composable
fun MonitorS(vm: Vm) {
    val ctx = LocalContext.current
    LaunchedEffect(Unit) { while (true) { vm.pollMon(); delay(1000) } }
    val th = Sys.thermal(ctx)
    val ramPct = (vm.ramFree * 100 / vm.ramTotal).toInt()
    val stPct = (vm.stFree * 100 / vm.stTotal).toInt()
    val bad = ramPct < 15 || stPct < 15 || vm.hot || (th ?: 0) >= 2
    val bold = FontWeight.Bold
    Page(vm, null, t("Мониторинг", "Monitor"), true) {
        Row(Modifier.fillMaxWidth().card().padding(16.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Dot(if (bad) Warn else Ok)
            Column {
                Txt(t("Сводка", "Summary"), 12, Mu)
                Txt(if (bad) t("Есть рекомендации", "There are recommendations") else t("Всё в порядке", "Everything is fine"), 16, w = bold)
            }
        }
        Column(Modifier.fillMaxWidth().card().padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            listOf(
                t("Модель", "Model") to Sys.model(),
                t("Система", "System") to Sys.androidVer(),
                "RAM" to vm.ramTotal.sz() + " · " + t("свободно ", "free ") + vm.ramFree.sz(),
                t("Накопитель", "Storage") to vm.stTotal.sz() + " · " + t("свободно ", "free ") + vm.stFree.sz(),
                t("Батарея", "Battery") to "${vm.bat.pct}% · ${vm.bat.tempC}°C",
                t("Тепловой статус", "Thermal status") to thermalName(th)
            ).forEach { (k, v) -> Row { Txt(k, 13, Mu, modifier = Modifier.weight(0.45f)); Txt(v, 13, w = FontWeight.SemiBold, modifier = Modifier.weight(0.55f)) } }
        }
        Column(Modifier.fillMaxWidth().card().padding(16.dp)) {
            Txt(t("Нагрузка сейчас", "Load now"), 14, w = bold)
            Spacer(Modifier.height(10.dp))
            val names = listOf("CPU", "GPU", t("Темп.", "Temp"), "RAM")
            val shown = vm.mon.indices.filter { vm.mon[it] != null }
            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                shown.forEach { i ->
                    Column(Modifier.weight(1f)) {
                        Txt(names[i], 11, Mu)
                        Txt("${vm.mon[i]}" + if (i == 2) "°" else "%", 17, Am, bold, true)
                        Spacer(Modifier.height(6.dp)); Bar((vm.mon[i] ?: 0) / (if (i == 2) 60f else 100f))
                    }
                }
            }
            if (vm.mon[0] == null) Txt(t("Загрузка CPU недоступна на этом устройстве: Android закрывает эти данные от приложений.", "CPU load is unavailable on this device: Android hides it from apps."), 11, Mu, modifier = Modifier.padding(top = 8.dp))
        }
        Txt(t("Рекомендации", "Recommendations"), 16, w = bold)
        tips(vm).take(4).forEach { Txt("• $it", 13, Mu) }
        Item(Ic.gear, t("Проверка разрешений", "Permission check"), t("Приложения с доступом к камере, микрофону, геолокации", "Apps with camera, microphone, location access"), trail = { Txt("›", 22, Mu) }) { vm.go(Screen.Perms) }
        Item(Ic.chart, t("Диагностика сети", "Network diagnostics"), t("Задержка, потери, скорость", "Latency, loss, speed"), trail = { Txt("›", 22, Mu) }) { vm.go(Screen.Net) }
    }
}

@Composable
fun permName(k: String): String = when (k) {
    "camera" -> t("Камера", "Camera")
    "mic" -> t("Микрофон", "Microphone")
    "loc" -> t("Геолокация", "Location")
    "contacts" -> t("Контакты", "Contacts")
    "sms" -> "SMS"
    else -> t("Звонки", "Calls")
}

@Composable
fun PermsS(vm: Vm) {
    val ctx = LocalContext.current
    LaunchedEffect(Unit) { vm.loadSens() }
    val list = vm.apps.filter { it.pkg in vm.sens }.sortedByDescending { vm.sens[it.pkg]?.size ?: 0 }
    Page(vm, null, t("Проверка разрешений", "Permission check"), true) {
        Txt(t("Показаны приложения, которым выдан доступ к чувствительным данным. Нажмите, чтобы открыть их настройки.", "Apps that were granted access to sensitive data. Tap to open their settings."), 12, Mu)
        if (vm.permsBusy) Txt(t("Проверяем...", "Checking..."), 13, Mu)
        else if (list.isEmpty()) Txt(t("Приложений с такими разрешениями не найдено.", "No apps with such permissions found."), 13, Mu)
        list.forEach { a ->
            Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).card(16).clickable { Sys.appInfo(ctx, a.pkg) }.padding(12.dp, 10.dp),
                verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                a.icon?.let { Image(it, null, Modifier.size(38.dp)) }
                Column(Modifier.weight(1f)) {
                    Txt(a.label, 15, w = FontWeight.SemiBold)
                    Txt((vm.sens[a.pkg] ?: emptySet()).map { permName(it) }.joinToString(", "), 12, Mu)
                }
                Txt("›", 20, Mu)
            }
        }
    }
}

@Composable
fun NetS(vm: Vm) {
    val r = vm.netRes
    val bold = FontWeight.Bold
    Page(vm, null, t("Диагностика сети", "Network diagnostics"), true, bottom = {
        HotBtn(if (vm.netBusy) t("Проверяем...", "Testing...") else t("Проверить сеть", "Test network"), !vm.netBusy) { vm.runNet() }
    }) {
        Txt(t("Тест использует около 4 МБ трафика и несколько секунд.", "The test uses about 4 MB of data and takes a few seconds."), 12, Mu)
        if (r != null) {
            val type = when (r.type) { "wifi" -> "Wi-Fi"; "cell" -> t("Мобильная сеть", "Mobile"); "none" -> t("Нет сети", "No network"); else -> t("Другое", "Other") }
            Item(null, t("Тип сети", "Network type"), type)
            Item(null, t("Задержка", "Latency"), r.ping?.let { "$it ms" } ?: "—", trail = { Dot(if ((r.ping ?: 999) < 80) Ok else if ((r.ping ?: 999) < 150) Warn else Bad) })
            Item(null, t("Джиттер", "Jitter"), r.jitter?.let { "$it ms" } ?: "—")
            Item(null, t("Потери пакетов", "Packet loss"), "${r.loss}%", trail = { Dot(if (r.loss == 0) Ok else if (r.loss < 25) Warn else Bad) })
            Item(null, t("Скорость загрузки", "Download speed"), r.mbps?.let { String.format(java.util.Locale.US, "%.1f Mbit/s", it) } ?: "—")
            Txt(
                if (r.loss == 0 && (r.jitter ?: 0) < 30 && (r.ping ?: 999) < 100) t("Соединение стабильное.", "The connection is stable.")
                else t("Соединение нестабильное: попробуйте другую сеть или подойдите ближе к роутеру.", "The connection is unstable: try another network or move closer to the router."),
                14, w = bold
            )
        }
    }
}


@Composable
fun FaqS(vm: Vm) {
    val ctx = LocalContext.current
    var open by remember { mutableIntStateOf(-1) }
    val qa = listOf(
        t("Не получается дать доступ: переключатель серый", "Cannot grant access: the switch is greyed out") to t(
            "Это защита Android для приложений, установленных из APK, а не из магазина («ограниченные настройки»). Что сделать:\n1. Откройте «О приложении» Black Boost (кнопка внизу).\n2. Нажмите три точки справа сверху и выберите «Разрешить ограниченные настройки».\n3. Вернитесь и включите нужный доступ.\nЕсли трёх точек нет, один раз нажмите на серый переключатель: пункт появится.",
            "This is Android protection for apps installed from an APK instead of a store (“restricted settings”). What to do:\n1. Open the Black Boost app info screen (button below).\n2. Tap the three dots at the top right and choose “Allow restricted settings”.\n3. Come back and turn the access on.\nIf there are no three dots, tap the greyed-out switch once and the option will appear."),
        t("При скачивании пишет, что приложение опасное", "The download says the app is dangerous") to t(
            "Приложение распространяется напрямую, а не через Google Play, поэтому Chrome и Play Protect не знают разработчика и показывают предупреждение. Данные остаются на телефоне, рекламы нет. Нажмите «Подробнее» и «Всё равно установить». Если Play Protect предлагает проверку, выберите «Отправить на проверку».",
            "The app is distributed directly, not through Google Play, so Chrome and Play Protect do not know the developer and show a warning. Data stays on your phone and there are no ads. Tap “Details” and “Install anyway”. If Play Protect offers a scan, choose “Send for scanning”."),
        t("Зачем нужен доступ ко всем файлам?", "Why is all files access needed?") to t(
            "Чтобы найти кэш, временные файлы, старые загрузки, большие файлы и дубликаты фото и видео и заранее показать, сколько места освободится. Удаляется только то, что вы отметили. Без доступа сканирование недоступно, остальное приложение работает.",
            "To find cache, temp files, old downloads, large files and duplicate photos and videos and show in advance how much space will be freed. Only what you select is deleted. Without it scanning is unavailable; the rest of the app works."),
        t("Зачем нужен доступ к статистике использования?", "Why is usage access needed?") to t(
            "Чтобы показать размер данных и кэш приложений, давно не используемые приложения и время на экране за сутки. Данные остаются на телефоне. Без доступа показывается только размер установки.",
            "To show app data size and cache, unused apps and screen time over 24 hours. Data stays on your phone. Without it only the install size is shown."),
        t("Почему после оптимизации память почти не освободилась?", "Why did memory barely change after optimizing?") to t(
            "Android сам управляет памятью и может перезапускать процессы. Приложение лишь просит систему завершить фоновые процессы и честно показывает результат. Закрывать всё подряд бессмысленно: это не ускоряет телефон.",
            "Android manages memory itself and may restart processes. The app only asks the system to end background processes and shows the real result. Closing everything is pointless: it does not speed the phone up."),
        t("Почему нет загрузки CPU или GPU?", "Why is there no CPU or GPU load?") to t(
            "На многих телефонах Android закрывает эти данные от приложений. Мониторинг показывает только то, что отдаёт ваше устройство.",
            "On many phones Android hides this data from apps. The monitor shows only what your device exposes."),
        t("Увеличивает ли приложение FPS в играх?", "Does the app increase FPS in games?") to t(
            "Нет. Android не разрешает обычному приложению разгонять процессор и видеочип или повышать FPS. FPS Boost освобождает память, чистит свой кэш, может включить «Не беспокоить» на время игры и подсказывает, что настроить вручную: частоту экрана и графику в игре.",
            "No. Android does not let a regular app overclock the CPU or GPU or raise FPS. FPS Boost frees memory, clears its own cache, can turn on Do Not Disturb during a game and tells you what to set manually: refresh rate and in-game graphics."),
        t("Как работает Game Mode+ («Не беспокоить»)?", "How does Game Mode+ (Do Not Disturb) work?") to t(
            "Нужен доступ «Не беспокоить». Перед запуском игры из приложения режим включается, а когда вы возвращаетесь в Black Boost, прежний режим восстанавливается.",
            "It needs Do Not Disturb access. Before the game launches from the app the mode is turned on, and when you return to Black Boost your previous mode is restored."),
        t("Что приложение отправляет в интернет?", "What does the app send to the internet?") to t(
            "Ничего, кроме теста сети (около 4 МБ скачивания с серверов Cloudflare). Аккаунтов нет, настройки и история очистки хранятся только на телефоне.",
            "Nothing except the network test (about 4 MB downloaded from Cloudflare servers). There are no accounts; settings and cleaning history are stored only on your phone."),
        t("Почему не показывается время работы батареи?", "Why is the battery time not shown?") to t(
            "Оценка считается по току разряда, который отдают не все телефоны. Если данных нет, показывается прочерк.",
            "The estimate uses the discharge current, which not all phones expose. If there is no data a dash is shown."),
        t("Игры не видны в списке", "My games are not listed") to t(
            "Игры определяет сама система. Если ваша игра не показана, нажмите «Добавить» в разделе FPS Boost и выберите её вручную.",
            "The system itself detects games. If yours is missing, tap “Add” in FPS Boost and pick it manually."),
        t("Как удалить данные приложения?", "How do I delete the app data?") to t(
            "Настройки → Приложения → Black Boost → Хранилище → Очистить данные. Или просто удалите приложение.",
            "Settings → Apps → Black Boost → Storage → Clear data. Or simply uninstall the app.")
    )
    Page(vm, null, t("Частые вопросы", "FAQ"), true) {
        qa.forEachIndexed { i, (q, a) ->
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).card(16).clickable { open = if (open == i) -1 else i }.padding(16.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    Txt(q, 15, w = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                    Txt(if (open == i) "−" else "+", 22, Am)
                }
                if (open == i) { Spacer(Modifier.height(8.dp)); Txt(a, 13, Mu) }
            }
        }
        Item(Ic.gear, t("Открыть настройки Black Boost", "Open Black Boost settings"), t("Ограниченные настройки и разрешения", "Restricted settings and permissions"),
            trail = { Txt("›", 22, Mu) }) { Sys.appInfo(ctx, ctx.packageName) }
        Item(Ic.send, t("Не нашли ответ? Наш Telegram", "No answer? Our Telegram"), "t.me/blackboostoff",
            trail = { Txt("›", 22, Mu) }) { Sys.openUrl(ctx, "https://t.me/blackboostoff") }
    }
}
BB_FINAL_20
mkdir -p "$(dirname 'app/src/main/java/com/blackboost/app/Notify.kt')"
cat > 'app/src/main/java/com/blackboost/app/Notify.kt' <<'BB_FINAL_21'
package com.blackboost.app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.ContextCompat
import androidx.work.*
import java.util.concurrent.TimeUnit

object Notify {
    private const val CH = "bb"

    fun post(c: Context, title: String, text: String) {
        if (Build.VERSION.SDK_INT >= 33 && ContextCompat.checkSelfPermission(c, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) return
        val nm = c.getSystemService(NotificationManager::class.java)
        nm.createNotificationChannel(NotificationChannel(CH, "Black Boost", NotificationManager.IMPORTANCE_DEFAULT))
        nm.notify(title.hashCode(), Notification.Builder(c, CH).setSmallIcon(android.R.drawable.stat_notify_more).setContentTitle(title).setContentText(text).setAutoCancel(true).build())
    }

    fun schedule(c: Context, on: Boolean) {
        val wm = WorkManager.getInstance(c)
        if (on) wm.enqueueUniquePeriodicWork("health", ExistingPeriodicWorkPolicy.UPDATE, PeriodicWorkRequestBuilder<HealthWorker>(6, TimeUnit.HOURS).build())
        else wm.cancelUniqueWork("health")
    }
}

class HealthWorker(c: Context, p: WorkerParameters) : Worker(c, p) {
    override fun doWork(): Result {
        val en = Prefs(applicationContext).lang == "en"
        val s = Sys.storage()
        if (s.first * 100 / s.second < 15) Notify.post(applicationContext, if (en) "Low storage" else "Мало места", if (en) "Less than 15% free. Open Black Boost to clean up." else "Свободно меньше 15%. Откройте Black Boost для очистки.")
        if (Sys.battery(applicationContext).tempC >= 43f) Notify.post(applicationContext, if (en) "Phone is hot" else "Телефон нагрелся", if (en) "Battery temperature is high. Close heavy apps." else "Температура батареи высокая. Закройте тяжёлые приложения.")
        val last = Prefs(applicationContext).lastClean
        if (System.currentTimeMillis() - last > 7 * 86400000L && s.first * 100 / s.second < 40)
            Notify.post(applicationContext, if (en) "Time to check storage" else "Пора проверить хранилище", if (en) "No cleanup for a week. Open Black Boost and run a scan." else "Неделю не было очистки. Откройте Black Boost и запустите сканирование.")
        return Result.success()
    }
}
BB_FINAL_21
mkdir -p "$(dirname 'app/src/main/java/com/blackboost/app/MainActivity.kt')"
cat > 'app/src/main/java/com/blackboost/app/MainActivity.kt' <<'BB_FINAL_22'
package com.blackboost.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.runtime.CompositionLocalProvider
import androidx.core.view.WindowCompat

class MainActivity : ComponentActivity() {
    private val vm: Vm by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.getInsetsController(window, window.decorView).isAppearanceLightStatusBars = false
        setContent { CompositionLocalProvider(LocalLang provides vm.lang) { App(vm, this) } }
    }

    override fun onResume() {
        super.onResume()
        vm.onResume()
    }
}
BB_FINAL_22
mkdir -p "$(dirname 'app/build.gradle.kts')"
cat > 'app/build.gradle.kts' <<'BB_FINAL_23'
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}
android {
    namespace = "com.blackboost.app"
    compileSdk = 34
    defaultConfig {
        applicationId = "com.blackboost.app"
        minSdk = 26
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
    }
    buildTypes { release { isMinifyEnabled = false } }
    compileOptions { sourceCompatibility = JavaVersion.VERSION_17; targetCompatibility = JavaVersion.VERSION_17 }
    kotlinOptions { jvmTarget = "17" }
    buildFeatures { compose = true; buildConfig = true }
    composeOptions { kotlinCompilerExtensionVersion = "1.5.14" }
}
dependencies {
    implementation(platform("androidx.compose:compose-bom:2024.06.00"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.activity:activity-compose:1.9.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.8.3")
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.work:work-runtime-ktx:2.9.0")
}
BB_FINAL_23
mkdir -p "$(dirname '.github/workflows/build.yml')"
cat > '.github/workflows/build.yml' <<'BB_FINAL_24'
name: Build APK

on:
  push:
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: 17
      - uses: gradle/actions/setup-gradle@v4
        with:
          gradle-version: 8.7
      - name: Build debug APK
        run: gradle :app:assembleDebug --no-daemon --console=plain > build.log 2>&1
      - name: Show errors
        if: failure()
        run: |
          grep -E "^e: |error:|What went wrong|Execution failed|Manifest merger|AAPT" -A4 build.log | head -70 || true
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: black-boost-debug-apk
          path: app/build/outputs/apk/debug/*.apk
          if-no-files-found: error
BB_FINAL_24
mkdir -p "$(dirname '.gitignore')"
cat > '.gitignore' <<'BB_FINAL_25'
build/
.gradle/
.idea/
local.properties
*.iml
BB_FINAL_25
echo "▶ Убираю устаревшие файлы (Premium/Billing)..."
rm -f app/src/main/java/com/blackboost/app/Billing.kt app/src/main/res/drawable/ic_crown.xml
echo "▶ Скачиваю шрифты..."
F=app/src/main/res/font; mkdir -p $F; U="https://raw.githubusercontent.com/google/fonts/main/ofl"
curl -fsSL "$U/unbounded/Unbounded%5Bwght%5D.ttf" -o $F/unbounded.ttf
curl -fsSL "$U/manrope/Manrope%5Bwght%5D.ttf" -o $F/manrope.ttf
echo "▶ Коммит..."
git add -A
GN="$(git config user.name || echo BlackBoost)"; GE="$(git config user.email || echo bb@example.com)"
git -c user.name="$GN" -c user.email="$GE" commit -q -m "Black Boost: final project" || echo "(нечего коммитить)"
if git remote | grep -q .; then git push -u origin HEAD && echo "✅ Готово. Открой Actions → Build APK → Artifacts → black-boost-debug-apk"; else echo "⚠ Нет remote: git remote add origin <URL> && git push -u origin HEAD"; fi

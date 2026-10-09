#!/usr/bin/env bash
# Restore.sh: возвращает прежнее красивое приложение Black Boost (логотип, кольцо, вкладки, FPS Boost, Premium) с реальными функциями.
# Запуск в Codespaces из корня репозитория:  bash Restore.sh
set -e
cd "$(dirname "$0")"
[ -f app/build.gradle.kts ] || { echo "❌ Не найден проект. Сначала выполните setup.sh"; exit 1; }
echo "▶ Возвращаю прежнее приложение..."
cat > 'app/build.gradle.kts' <<'BB_OLD_1'
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
    implementation("com.android.billingclient:billing:7.0.0")
}
BB_OLD_1
cat > 'app/src/main/AndroidManifest.xml' <<'BB_OLD_2'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" xmlns:tools="http://schemas.android.com/tools">
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
BB_OLD_2
cat > 'app/src/main/java/com/blackboost/app/Prefs.kt' <<'BB_OLD_3'
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
}
BB_OLD_3
cat > 'app/src/main/java/com/blackboost/app/Sys.kt' <<'BB_OLD_4'
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
                var b = 0L
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
    fun usageSettings(c: Context) = go(c, Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
    fun filesSettings(c: Context) { if (Build.VERSION.SDK_INT >= 30) go(c, Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION, Uri.parse("package:${c.packageName}"))) }
    fun appInfo(c: Context, p: String) = go(c, Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$p")))
    fun saver(c: Context) = go(c, Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS))
    fun battOpt(c: Context) = go(c, Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
    fun dnd(c: Context) = go(c, Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
    fun uninstall(c: Context, p: String) = go(c, Intent(Intent.ACTION_DELETE, Uri.parse("package:$p")))
}
BB_OLD_4
cat > 'app/src/main/java/com/blackboost/app/Cleaner.kt' <<'BB_OLD_5'
package com.blackboost.app

import android.content.Context
import android.os.Environment
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.security.MessageDigest

class Junk(val id: String, val ru: String, val en: String, val files: List<File>, val bytes: Long)

object Cleaner {
    private val tmpExt = setOf("tmp", "temp", "log", "bak", "old", "chk", "dmp")

    fun ownCache(c: Context): List<File> =
        listOfNotNull(c.cacheDir, c.externalCacheDir).flatMap { d -> d.walkBottomUp().filter { it.isFile }.toList() }

    private fun sha(f: File): String = try {
        val md = MessageDigest.getInstance("SHA-1")
        f.inputStream().use { s ->
            val buf = ByteArray(65536)
            while (true) { val n = s.read(buf); if (n <= 0) break; md.update(buf, 0, n) }
        }
        md.digest().joinToString("") { "%02x".format(it) }
    } catch (e: Exception) { f.path }

    /** Сканирует память. Если нет доступа ко всем файлам, ищет только кэш самого приложения. */
    suspend fun scan(c: Context, all: Boolean): List<Junk> = withContext(Dispatchers.IO) {
        val tmp = ArrayList<File>(); val apk = ArrayList<File>(); val sys = ArrayList<File>(); val big = ArrayList<File>()
        if (all) {
            val root = Environment.getExternalStorageDirectory()
            root.walkTopDown().onEnter { !(it.parentFile == root && it.name == "Android") }.forEach { f ->
                if (f.isFile) {
                    val n = f.name.lowercase()
                    val ext = n.substringAfterLast('.', "")
                    val par = f.parentFile?.name ?: ""
                    when {
                        n.startsWith(".trashed-") || par == ".thumbnails" || par == "LOST.DIR" -> sys += f
                        ext in tmpExt || n.startsWith("~") -> tmp += f
                        ext == "apk" -> apk += f
                        f.length() >= 100 * 1024 && !n.startsWith(".") -> big += f
                    }
                }
            }
        }
        val dup = ArrayList<File>()
        big.groupBy { it.length() }.values.filter { it.size > 1 }.take(300).forEach { g ->
            g.groupBy { sha(it) }.values.forEach { s -> if (s.size > 1) dup += s.sortedBy { it.lastModified() }.drop(1) }
        }
        fun j(id: String, ru: String, en: String, l: List<File>) = Junk(id, ru, en, l, l.sumOf { it.length() })
        listOf(
            j("cache", "Кэш приложений", "App cache", ownCache(c)),
            j("tmp", "Временные файлы", "Temp files", tmp),
            j("left", "Остаточные файлы", "Leftover files", apk),
            j("dup", "Дубликаты файлов", "Duplicate files", dup),
            j("sys", "Системный мусор", "System junk", sys)
        )
    }

    suspend fun clean(items: List<Junk>, progress: (Float) -> Unit): Long = withContext(Dispatchers.IO) {
        val all = items.flatMap { it.files }
        var freed = 0L
        all.forEachIndexed { i, f ->
            val l = f.length()
            if (f.delete()) freed += l
            if (i % 20 == 0) progress((i + 1f) / all.size)
        }
        progress(1f)
        freed
    }
}
BB_OLD_5
cat > 'app/src/main/java/com/blackboost/app/Vm.kt' <<'BB_OLD_6'
package com.blackboost.app

import android.app.Activity
import android.app.Application
import android.app.NotificationManager
import android.content.Context
import androidx.compose.runtime.*
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

enum class Screen { Splash, Home, Clean, Battery, Apps, Storage, Fps, Settings }

class Vm(app: Application) : AndroidViewModel(app) {
    private val c: Context get() = getApplication()
    val prefs = Prefs(app)

    var screen by mutableStateOf(Screen.Splash)
    private val stack = ArrayList<Screen>()
    fun go(s: Screen, tab: Boolean = false) { if (tab) stack.clear() else stack.add(screen); screen = s }
    fun back() {
        if (stack.isNotEmpty()) screen = stack.removeAt(stack.size - 1)
        else if (screen != Screen.Home) screen = Screen.Home
    }

    var lang by mutableStateOf(prefs.lang)
    var notif by mutableStateOf(prefs.notif)
    var premium by mutableStateOf(prefs.premium)
    var gameMode by mutableStateOf(prefs.gameMode)
    var paywall by mutableStateOf(false)
    var toast by mutableStateOf<String?>(null)
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

    var apps by mutableStateOf<List<AppInfo>>(emptyList())
    var appsLoading by mutableStateOf(false)
    var stor by mutableStateOf<Stor?>(null)
    var junk by mutableStateOf<List<Junk>?>(null)
    var sel by mutableStateOf(setOf<String>())
    var phase by mutableStateOf("idle") // idle, scanning, found, cleaning, done
    var progress by mutableFloatStateOf(0f)
    var freed by mutableLongStateOf(0L)
    var busy by mutableStateOf(false)
    var mon by mutableStateOf<List<Int?>>(listOf(null, null, null, null))
    private var dndAt = 0L

    val billing = Billing(app) { grantPremium() }

    init { Notify.schedule(app, notif); refresh() }

    fun grantPremium() { premium = true; prefs.premium = true }
    fun changeLang(l: String) { lang = l; prefs.lang = l }
    fun changeNotif(on: Boolean) { notif = on; prefs.notif = on; Notify.schedule(c, on) }
    fun changeGameMode(on: Boolean) { gameMode = on; prefs.gameMode = on }

    fun refresh() {
        Sys.mem(c).let { ramFree = it.first; ramTotal = it.second }
        Sys.storage().let { stFree = it.first; stTotal = it.second }
        bat = Sys.battery(c); saver = Sys.powerSave(c)
        usageOk = Sys.hasUsage(c); filesOk = Sys.hasFiles(c); mediaOk = Sys.hasMedia(c); dndOk = Sys.hasDnd(c)
    }

    fun onResume() {
        refresh()
        if (System.currentTimeMillis() - dndAt > 4000) restoreDnd()
    }

    /** Оценка 0..100 по реальным показателям: свободная ОЗУ, место, мусор, температура батареи. */
    val score: Int
        get() {
            val ram = minOf(35f, ramFree * 100f / ramTotal / 45f * 35f)
            val st = minOf(35f, stFree * 100f / stTotal / 30f * 35f)
            val j = junk?.sumOf { it.bytes }
            val jp = if (j == null) 10f else maxOf(0f, 20f - j / 1_000_000f / 50f)
            val bp = if (bat.tempC < 40f) 10f else if (bat.tempC < 45f) 5f else 0f
            return (ram + st + jp + bp).toInt().coerceIn(0, 100)
        }

    fun loadApps() {
        viewModelScope.launch { appsLoading = true; apps = withContext(Dispatchers.IO) { Sys.apps(c) }; appsLoading = false }
    }

    fun loadStorage() {
        viewModelScope.launch {
            if (apps.isEmpty()) apps = withContext(Dispatchers.IO) { Sys.apps(c) }
            stor = withContext(Dispatchers.IO) { Sys.stor(c, apps) }
        }
    }

    fun scan() {
        if (phase == "scanning" || phase == "cleaning") return
        phase = "scanning"
        viewModelScope.launch {
            val r = Cleaner.scan(c, filesOk)
            junk = r; sel = r.filter { it.bytes > 0 }.map { it.id }.toSet(); phase = "found"
        }
    }

    fun toggle(id: String) { sel = if (id in sel) sel - id else sel + id }

    fun cleanNow() {
        val items = junk?.filter { it.id in sel && it.bytes > 0 } ?: return
        phase = "cleaning"; progress = 0f
        viewModelScope.launch {
            freed = Cleaner.clean(items) { progress = it }
            phase = "done"; junk = null; refresh()
        }
    }

    fun boost() {
        if (busy) return
        busy = true
        viewModelScope.launch {
            val (f, n) = withContext(Dispatchers.IO) { Sys.boostRam(c) }
            refresh(); busy = false
            toast = tt("Освобождено ${f / 1_000_000} MB ОЗУ · приложений: $n", "Freed ${f / 1_000_000} MB RAM · apps: $n")
        }
    }

    suspend fun stepRam(): String {
        val (f, _) = withContext(Dispatchers.IO) { Sys.boostRam(c) }
        refresh(); return "+${f / 1_000_000} MB"
    }

    suspend fun stepJunk(): String = withContext(Dispatchers.IO) {
        val items = Cleaner.scan(c, filesOk).filter { it.id == "cache" || it.id == "tmp" || it.id == "sys" }
        "+" + Cleaner.clean(items) {}.sz()
    }

    fun pollMon() {
        refresh()
        mon = listOf(Sys.cpu(), Sys.gpu(), bat.tempC.toInt(), ((ramTotal - ramFree) * 100 / ramTotal).toInt())
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

    /** Запуск игры: сначала освобождаем ОЗУ, при Game Mode+ включаем «Не беспокоить» на время игры. */
    fun launchGame(a: Activity, pkg: String) {
        viewModelScope.launch {
            withContext(Dispatchers.IO) { Sys.boostRam(c) }
            if (premium && gameMode && dndOk) dndOn()
            a.packageManager.getLaunchIntentForPackage(pkg)?.let { a.startActivity(it) }
        }
    }
}
BB_OLD_6
cat > 'app/src/main/java/com/blackboost/app/UI.kt' <<'BB_OLD_7'
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
}

@Composable
fun Txt(
    s: String, size: Int = 15, color: Color = Tx, w: FontWeight = FontWeight.Medium, disp: Boolean = false,
    modifier: Modifier = Modifier, align: TextAlign? = null, brush: Brush? = null, deco: TextDecoration? = null
) {
    val fam = if (disp) Disp else Body
    if (brush != null) BasicText(s, modifier, TextStyle(brush = brush, fontSize = size.sp, fontWeight = w, fontFamily = fam, textAlign = align ?: TextAlign.Unspecified, textDecoration = deco))
    else Text(s, modifier, color = color, fontSize = size.sp, fontWeight = w, fontFamily = fam, textAlign = align, textDecoration = deco)
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
BB_OLD_7
cat > 'app/src/main/java/com/blackboost/app/Screens.kt' <<'BB_OLD_8'
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
            Screen.Fps -> FpsS(vm, act)
            Screen.Settings -> SettingsS(vm)
        }
        vm.toast?.let {
            Box(Modifier.align(Alignment.BottomCenter).padding(24.dp, 0.dp, 24.dp, 100.dp).clip(RoundedCornerShape(14.dp)).background(Color(0xFF1A1512)).padding(16.dp, 12.dp)) {
                Txt(it, 13, w = androidx.compose.ui.text.font.FontWeight.SemiBold, align = TextAlign.Center)
            }
            LaunchedEffect(it) { delay(2800); vm.toast = null }
        }
        if (vm.paywall) Paywall(vm, act)
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
    Column(Modifier.weight(1f).clip(RoundedCornerShape(18.dp)).card().clickable(onClick = on).padding(16.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
        Icon(i, null, Modifier.size(26.dp), tint = Em)
        Column { Txt(l, 14, w = androidx.compose.ui.text.font.FontWeight.SemiBold); Txt(v, 17, Am, androidx.compose.ui.text.font.FontWeight.Bold, true) }
    }

@Composable
fun HomeS(vm: Vm) {
    LaunchedEffect(Unit) { while (true) { vm.refresh(); delay(3000) } }
    LaunchedEffect(vm.usageOk) { vm.loadApps() }
    LaunchedEffect(vm.filesOk) { if (vm.junk == null && vm.phase == "idle") vm.scan() }
    val ctx = LocalContext.current
    val ju = vm.junk?.sumOf { it.bytes }
    Page(vm, Screen.Home, null) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Image(painterResource(R.drawable.ic_logo), null, Modifier.height(26.dp).aspectRatio(636f / 603f))
            Txt("Black Boost", 19, disp = true, w = androidx.compose.ui.text.font.FontWeight.Bold)
        }
        Box(Modifier.fillMaxWidth(), Alignment.Center) {
            Ring(vm.score / 100f, 230.dp) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Txt("${vm.score}", 52, disp = true, w = androidx.compose.ui.text.font.FontWeight.Black)
                    Txt(t("Оптимизация", "Optimization"), 13, Mu)
                }
            }
        }
        HotBtn(if (vm.busy) t("Ускоряем...", "Boosting...") else t("Ускорить сейчас", "Boost now"), !vm.busy) { vm.boost() }
        Row(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(Brush.horizontalGradient(listOf(Color(0xFF2A1208), Sf)))
                .border(1.dp, Color(0xFF5A2C1A), RoundedCornerShape(18.dp)).clickable { vm.go(Screen.Fps) }.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Icon(Ic.bolt, null, Modifier.size(26.dp), tint = Em)
            Column(Modifier.weight(1f)) {
                Txt("FPS Boost", 16, disp = true, w = androidx.compose.ui.text.font.FontWeight.Bold)
                Txt(t("Полная оптимизация для игр", "Full optimization for games"), 12, Mu)
            }
            Txt("›", 22, Am)
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Tile(Ic.trash, t("Очистка", "Cleaner"), ju?.sz() ?: "…") { vm.go(Screen.Clean) }
            Tile(Ic.battery, t("Батарея", "Battery"), "${vm.bat.pct}%") { vm.go(Screen.Battery) }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Tile(Ic.grid, t("Кэш приложений", "App cache"), if (vm.usageOk) vm.apps.sumOf { it.cache }.sz() else "—") { vm.go(Screen.Apps) }
            Tile(Ic.db, t("Свободно", "Free"), vm.stFree.sz()) { vm.go(Screen.Storage) }
        }
    }
}

@Composable
fun CleanS(vm: Vm) {
    val ctx = LocalContext.current
    val perm = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { vm.refresh() }
    LaunchedEffect(Unit) {
        if (vm.phase == "done") vm.phase = "idle"
        if (vm.junk == null && vm.phase == "idle") vm.scan()
    }
    val inf by rememberInfiniteTransition(label = "s").animateFloat(0f, 1f, infiniteRepeatable(tween(1400, easing = LinearEasing)), label = "s")
    val j = vm.junk
    val tot = j?.sumOf { it.bytes } ?: 0L
    val selB = j?.filter { it.id in vm.sel }?.sumOf { it.bytes } ?: 0L
    val bold = androidx.compose.ui.text.font.FontWeight.Bold
    val black = androidx.compose.ui.text.font.FontWeight.Black
    Page(vm, Screen.Clean, t("Очистка", "Cleaner"), bottom = {
        when {
            vm.phase == "done" -> HotBtn(t("Готово", "Done")) { vm.go(Screen.Home, true) }
            vm.phase == "scanning" -> HotBtn(t("Сканируем...", "Scanning..."), false) {}
            vm.phase == "cleaning" -> HotBtn(t("Идёт очистка...", "Cleaning..."), false) {}
            j != null && tot > 0 -> HotBtn(t("Очистить ", "Clean ") + selB.sz(), selB > 0) { vm.cleanNow() }
            else -> HotBtn(t("Сканировать", "Scan")) { vm.scan() }
        }
    }) {
        Box(Modifier.fillMaxWidth(), Alignment.Center) {
            val rp = when (vm.phase) { "scanning" -> inf; "cleaning" -> vm.progress; "done" -> 1f; else -> if (tot > 0) 0f else 1f }
            Ring(rp, 230.dp, anim = vm.phase != "scanning") {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    when {
                        vm.phase == "done" -> { CheckMark(72.dp); Txt(vm.freed.sz(), 22, disp = true, w = bold); Txt(t("Освобождено", "Freed"), 12, Mu) }
                        vm.phase == "scanning" -> Txt(t("Сканируем...", "Scanning..."), 15, Mu)
                        vm.phase == "cleaning" -> Txt("${(vm.progress * 100).toInt()}%", 40, disp = true, w = black)
                        j == null -> Txt("…", 30, Mu)
                        tot > 0 -> { Txt(tot.sz(), 32, disp = true, w = black); Txt(t("мусора найдено", "junk found"), 12, Mu) }
                        else -> { CheckMark(72.dp); Txt(t("Всё чисто", "All clean"), 13, Mu) }
                    }
                }
            }
        }
        if (!vm.filesOk) Item(Ic.db, t("Нужен доступ ко всем файлам", "All files access needed"),
            t("Без него ищется только кэш Black Boost", "Without it only Black Boost cache is scanned"),
            trail = { Txt(t("Дать", "Grant"), 13, Am, bold) }) {
            if (Build.VERSION.SDK_INT >= 30) Sys.filesSettings(ctx) else perm.launch(Manifest.permission.WRITE_EXTERNAL_STORAGE)
        }
        if (vm.phase == "found") j?.forEach { x ->
            Item(null, t(x.ru, x.en), null, trail = {
                Txt(x.bytes.sz(), 13, Am, bold); Spacer(Modifier.width(10.dp)); MiniCheck(x.id in vm.sel)
            }) { if (x.bytes > 0) vm.toggle(x.id) }
        }
    }
}

@Composable
fun BatteryS(vm: Vm) {
    val ctx = LocalContext.current
    val b = vm.bat
    LaunchedEffect(Unit) { while (true) { vm.refresh(); delay(3000) } }
    Page(vm, Screen.Battery, t("Батарея", "Battery")) {
        Column(Modifier.fillMaxWidth().card().padding(20.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(20.dp)) {
                Row(verticalAlignment = Alignment.Bottom) {
                    Txt("${b.pct}", 48, disp = true, w = androidx.compose.ui.text.font.FontWeight.Black)
                    Txt("%", 20, Mu, modifier = Modifier.padding(bottom = 6.dp))
                }
                Column {
                    Txt(if (b.charging) t("До полной зарядки", "Until full") else t("Осталось", "Remaining"), 12, Mu)
                    Txt(b.minutes?.let { "${it / 60} ${t("ч", "h")} ${it % 60} ${t("мин", "min")}" } ?: "—", 19, Am, androidx.compose.ui.text.font.FontWeight.Bold, true)
                }
            }
            Spacer(Modifier.height(16.dp)); Bar(b.pct / 100f); Spacer(Modifier.height(16.dp))
            HotBtn(t("Оптимизировать", "Optimize"), !vm.busy) { vm.boost(); if (!vm.saver) Sys.saver(ctx) }
        }
        Item(Ic.battery, t("Энергосбережение", "Power saving"), if (vm.saver) t("Включено", "On") else t("Выключено", "Off"),
            trail = { Tog(vm.saver) { Sys.saver(ctx) } }) { Sys.saver(ctx) }
        Item(Ic.clock, t("Фоновая активность", "Background activity"), t("Оптимизация расхода в фоне", "Background usage optimization"),
            trail = { Txt("›", 20, Mu) }) { Sys.battOpt(ctx) }
        Item(Ic.chart, t("Температура батареи", "Battery temperature"), if (b.charging) t("Идёт зарядка", "Charging") else t("Не заряжается", "Not charging"),
            trail = { Txt("${b.tempC}°C", 15, Am, androidx.compose.ui.text.font.FontWeight.Bold) })
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
        1 -> vm.apps.sortedByDescending { it.bytes }.take(15)
        2 -> vm.apps.filter { vm.usageOk && now - it.lastUsed > 30L * 86400000 }.sortedByDescending { it.bytes }
        else -> vm.apps
    }
    val semi = androidx.compose.ui.text.font.FontWeight.SemiBold
    Page(vm, Screen.Apps, t("Приложения", "Apps")) {
        Tabs(listOf(t("Все", "All"), t("Крупные", "Large"), t("Неиспользуемые", "Unused")), tab) { tab = it }
        if (!vm.usageOk) Item(Ic.grid, t("Нужен доступ к статистике", "Usage access needed"),
            t("Покажет размер, кэш и давность запуска", "Shows size, cache and last use"),
            trail = { Txt(t("Дать", "Grant"), 13, Am, androidx.compose.ui.text.font.FontWeight.Bold) }) { Sys.usageSettings(ctx) }
        if (vm.appsLoading && vm.apps.isEmpty()) Txt(t("Загрузка...", "Loading..."), 13, Mu)
        list.forEach { a ->
            Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).card(16).clickable { sel = a }.padding(12.dp, 10.dp),
                verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                a.icon?.let { Image(it, null, Modifier.size(40.dp)) }
                Column(Modifier.weight(1f)) {
                    Txt(a.label, 15, w = semi)
                    if (vm.usageOk) Txt(t("Кэш ", "Cache ") + a.cache.sz() + " · " + a.bytes.sz(), 12, Mu)
                }
                Txt("›", 20, Mu)
            }
        }
    }
    sel?.let { a ->
        Dialog(onDismissRequest = { sel = null }) {
            Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(24.dp)).background(Bg).border(1.dp, Ln, RoundedCornerShape(24.dp)).padding(18.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Txt(a.label, 18, w = androidx.compose.ui.text.font.FontWeight.Bold)
                Item(Ic.trash, t("Очистить кэш", "Clear cache"), t("Откроется экран приложения → Хранилище", "Opens app info → Storage")) { Sys.appInfo(ctx, a.pkg); sel = null }
                Item(Ic.close, t("Остановить", "Stop"), t("Завершить фоновые процессы", "End background processes")) {
                    ctx.getSystemService(android.app.ActivityManager::class.java).killBackgroundProcesses(a.pkg)
                    vm.toast = vm.tt("Запрос на остановку отправлен", "Stop request sent"); sel = null
                }
                Item(Ic.trash, t("Удалить", "Uninstall"), t("Системный диалог удаления", "System uninstall dialog")) { Sys.uninstall(ctx, a.pkg); sel = null }
            }
        }
    }
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

suspend fun measureFps(ms: Long): Float {
    var t0 = 0L
    withFrameNanos { t0 = it }
    var last = t0
    var n = 0
    while ((last - t0) / 1_000_000 < ms) { last = withFrameNanos { it }; n++ }
    return n * 1e9f / (last - t0)
}

@Composable
fun FpsS(vm: Vm, act: Activity) {
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    var mode by remember { mutableIntStateOf(1) }
    var fps by remember { mutableFloatStateOf(0f) }
    var res by remember { mutableStateOf<String?>(null) }
    var run by remember { mutableStateOf(false) }
    val steps = remember { mutableStateListOf<String?>(null, null, null, null, null) }
    val disp = remember { (act.getSystemService(Context.WINDOW_SERVICE) as WindowManager).defaultDisplay }
    val bold = androidx.compose.ui.text.font.FontWeight.Bold
    LaunchedEffect(Unit) { vm.loadApps(); fps = measureFps(1000) }
    LaunchedEffect(vm.premium) { while (vm.premium) { vm.pollMon(); delay(1000) } }
    val names = listOf(t("Очистка ОЗУ", "RAM cleanup"), t("Мусор и кэш", "Junk & cache"), t("Режим производительности", "Performance mode"), t("Частота обновления", "Refresh rate"), t("Game Mode+", "Game Mode+"))
    val games = vm.apps.filter { it.game }.ifEmpty { vm.apps.take(8) }

    fun start() {
        if (run) return
        run = true; res = null
        for (i in steps.indices) steps[i] = null
        scope.launch {
            val before = measureFps(1200)
            val skip = "—"
            steps[0] = vm.stepRam(); delay(250)
            steps[1] = if (mode >= 1) vm.stepJunk() else skip; delay(250)
            steps[2] = if (mode >= 1) {
                val pm = act.getSystemService(PowerManager::class.java)
                if (pm.isSustainedPerformanceModeSupported) { act.window.setSustainedPerformanceMode(true); vm.tt("Вкл", "On") } else vm.tt("Нет", "N/A")
            } else skip
            delay(250)
            steps[3] = if (mode >= 2) {
                val cur = disp.mode
                val best = disp.supportedModes.filter { it.physicalWidth == cur.physicalWidth && it.physicalHeight == cur.physicalHeight }.maxByOrNull { it.refreshRate }
                if (best != null) {
                    val lp = act.window.attributes; lp.preferredDisplayModeId = best.modeId; act.window.attributes = lp
                    "${best.refreshRate.toInt()} Hz"
                } else skip
            } else skip
            delay(250)
            steps[4] = if (mode >= 2 && vm.premium && vm.gameMode) { if (vm.dndOk) "DND" else { Sys.dnd(ctx); "?" } } else skip
            delay(300)
            val after = measureFps(1200)
            fps = after; res = "${before.toInt()} → ${after.toInt()} FPS"; run = false
        }
    }

    Page(vm, null, "FPS Boost", true, bottom = { HotBtn(if (run) t("Оптимизируем...", "Optimizing...") else t("Запустить FPS Boost", "Start FPS Boost"), !run) { start() } }) {
        Box(Modifier.fillMaxWidth(), Alignment.Center) {
            Ring(fps / 120f, 200.dp) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Txt("${fps.toInt()}", 48, disp = true, w = androidx.compose.ui.text.font.FontWeight.Black)
                    Txt("FPS", 12, Mu)
                }
            }
        }
        Txt(res?.let { t("Замер до и после: ", "Measured before / after: ") + it } ?: t("Экран: ", "Display: ") + "${disp.refreshRate.toInt()} Hz · max ${disp.supportedModes.maxOf { it.refreshRate }.toInt()} Hz",
            13, Mu, modifier = Modifier.fillMaxWidth(), align = TextAlign.Center)
        Tabs(listOf(t("Базовый", "Basic"), t("Высокий", "High"), t("Максимальный", "Maximum")), mode) { i ->
            if (run) return@Tabs
            if (i == 2 && !vm.premium) vm.paywall = true else mode = i
        }
        if (!vm.premium) Txt(t("Максимальный режим доступен в Premium", "Maximum mode requires Premium"), 11, Mu, modifier = Modifier.fillMaxWidth(), align = TextAlign.Center)
        steps.forEachIndexed { i, v ->
            Item(null, names[i], null, trail = {
                if (v != null) Txt(v, 13, Am, bold)
                else if (run) Txt("…", 13, Mu)
            })
        }
        if (vm.premium) {
            Column(Modifier.fillMaxWidth().card().padding(16.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Txt("Performance Monitor", 14, w = bold, modifier = Modifier.weight(1f))
                    Txt("Live", 12, Mu)
                }
                Spacer(Modifier.height(12.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    listOf("CPU" to 0, "GPU" to 1, t("Темп.", "Temp") to 2, "RAM" to 3).forEach { (n, i) ->
                        Column(Modifier.weight(1f)) {
                            Txt(n, 11, Mu)
                            Txt(vm.mon[i]?.let { "$it" + if (i == 2) "°" else "%" } ?: "—", 17, Am, bold, true)
                            Spacer(Modifier.height(6.dp)); Bar((vm.mon[i] ?: 0) / (if (i == 2) 60f else 100f))
                        }
                    }
                }
            }
            Item(Ic.bolt, "Game Mode+", t("Не беспокоить на время игры", "Do Not Disturb while gaming"),
                trail = { Tog(vm.gameMode) { on -> vm.changeGameMode(on); if (on && !vm.dndOk) Sys.dnd(ctx) } })
        } else Row(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(Brush.horizontalGradient(listOf(Color(0xFF2A1208), Sf)))
                .border(1.dp, Color(0xFF5A2C1A), RoundedCornerShape(16.dp)).clickable { vm.paywall = true }.padding(14.dp),
            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Image(painterResource(R.drawable.ic_crown), null, Modifier.height(28.dp).aspectRatio(828f / 545f))
            Column(Modifier.weight(1f)) {
                Txt("Premium Boost", 15, w = bold, disp = true)
                Txt(t("Монитор, Game Mode+ и максимальный режим", "Monitor, Game Mode+ and Maximum mode"), 12, Mu)
            }
        }
        Txt(t("Запуск игры с Boost", "Launch game with Boost"), 14, w = bold)
        if (games.isEmpty()) Txt(t("Приложения не найдены", "No apps found"), 12, Mu)
        Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            games.forEach { a ->
                Column(Modifier.width(72.dp).clip(RoundedCornerShape(14.dp)).clickable { vm.launchGame(act, a.pkg) }, horizontalAlignment = Alignment.CenterHorizontally) {
                    a.icon?.let { Image(it, null, Modifier.size(52.dp)) }
                    Txt(a.label, 11, Mu, align = TextAlign.Center)
                }
            }
        }
    }
}

@Composable
fun SettingsS(vm: Vm) {
    val ctx = LocalContext.current
    val perm = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { ok -> vm.changeNotif(ok) }
    val bold = androidx.compose.ui.text.font.FontWeight.Bold
    Page(vm, Screen.Settings, t("Настройки", "Settings")) {
        Row(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(Brush.horizontalGradient(listOf(Color(0xFF2A1208), Sf)))
                .border(1.dp, Color(0xFF5A2C1A), RoundedCornerShape(18.dp)).clickable { vm.paywall = true }.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Image(painterResource(R.drawable.ic_crown), null, Modifier.height(30.dp).aspectRatio(828f / 545f))
            Column(Modifier.weight(1f)) {
                Txt("Premium Boost", 16, disp = true, w = bold)
                Txt(if (vm.premium) t("Активен навсегда", "Active forever") else t("Получить Premium", "Get Premium"), 12, Mu)
            }
            Txt(if (vm.premium) t("Активен", "Active") else "›", 15, Am, bold, true)
        }
        Column(Modifier.fillMaxWidth().card().padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                Icon(Ic.globe, null, Modifier.size(24.dp), tint = Em); Txt(t("Язык", "Language"), 15, w = bold)
            }
            Tabs(listOf("Русский", "English"), if (vm.lang == "en") 1 else 0) { vm.changeLang(if (it == 1) "en" else "ru") }
        }
        Item(Ic.bell, t("Уведомления", "Notifications"), t("Включить оповещения", "Turn on alerts"), trail = {
            Tog(vm.notif) { on ->
                if (on && Build.VERSION.SDK_INT >= 33 && ContextCompat.checkSelfPermission(ctx, Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED)
                    perm.launch(Manifest.permission.POST_NOTIFICATIONS)
                else vm.changeNotif(on)
            }
        })
    }
}

@Composable
fun Paywall(vm: Vm, act: Activity) {
    val bold = androidx.compose.ui.text.font.FontWeight.Bold
    Dialog(onDismissRequest = { vm.paywall = false }, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Box(Modifier.padding(16.dp)) {
            Column(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(28.dp)).background(Brush.verticalGradient(listOf(Color(0xFF2A1208), Color(0xFF0B0B0B))))
                    .border(1.dp, Color(0xFF5A2C1A), RoundedCornerShape(28.dp)).verticalScroll(rememberScrollState()).padding(22.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Image(painterResource(R.drawable.ic_crown), null, Modifier.height(90.dp).aspectRatio(828f / 545f))
                Spacer(Modifier.height(10.dp))
                Txt("Premium Boost", 26, disp = true, w = androidx.compose.ui.text.font.FontWeight.Black, brush = Hot)
                Spacer(Modifier.height(6.dp))
                if (vm.premium) {
                    Txt(t("Premium активирован", "Premium activated"), 16, w = bold)
                    Txt(t("Все функции открыты. Спасибо!", "All features unlocked. Thank you!"), 13, Mu)
                    Spacer(Modifier.height(20.dp))
                    HotBtn(t("Продолжить", "Continue")) { vm.paywall = false }
                } else {
                    Txt(t("Получи максимум с Premium", "Get the most with Premium"), 15, w = androidx.compose.ui.text.font.FontWeight.SemiBold)
                    Spacer(Modifier.height(16.dp))
                    Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(Color(0xAA0E0E0E)).border(1.dp, Ln, RoundedCornerShape(16.dp)).padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Txt(t("Premium включает:", "Premium includes:"), 13, w = bold)
                        listOf(
                            "Performance Monitor" to t("Нагрузка CPU, GPU и температура в реальном времени.", "CPU and GPU load and temperature in real time."),
                            "Game Mode+" to t("Идеальный режим для запуска игр", "The perfect mode for launching games"),
                            null to t("Разблокировка Максимального режима FPS Boost", "Unlocks Maximum mode in FPS Boost")
                        ).forEach { (h, d) ->
                            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                                Box(Modifier.padding(top = 6.dp).size(8.dp).clip(CircleShape).background(Hot))
                                Column {
                                    if (h != null) Txt(h, 13, w = bold)
                                    Txt(d, 12, if (h != null) Mu else Tx)
                                }
                            }
                        }
                    }
                    Spacer(Modifier.height(16.dp))
                    Txt(t("Навсегда", "Forever"), 12, Mu)
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Txt(vm.billing.price ?: "49 ₽", 38, disp = true, w = androidx.compose.ui.text.font.FontWeight.Black)
                        Txt("99 ₽", 20, Mu, deco = TextDecoration.LineThrough)
                        Box(Modifier.rotate(-4f).clip(RoundedCornerShape(50)).background(Hot).padding(10.dp, 5.dp)) { Txt("−50%", 13, Ink, androidx.compose.ui.text.font.FontWeight.ExtraBold) }
                    }
                    Spacer(Modifier.height(16.dp))
                    HotBtn(t("Оплатить", "Pay")) {
                        if (!vm.billing.buy(act)) {
                            if (BuildConfig.DEBUG) vm.grantPremium() else vm.toast = vm.tt("Google Play недоступен", "Google Play unavailable")
                        }
                    }
                    Spacer(Modifier.height(10.dp))
                    Txt(t("Восстановить покупки", "Restore purchases"), 12, Mu, modifier = Modifier.clickable { vm.billing.restore() }.padding(8.dp))
                }
            }
        }
    }
}
BB_OLD_8
cat > 'app/src/main/java/com/blackboost/app/Billing.kt' <<'BB_OLD_9'
package com.blackboost.app

import android.app.Activity
import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.android.billingclient.api.*

/** Разовая покупка Premium через Google Play Billing. ID товара создайте в Play Console. */
class Billing(c: Context, private val onPremium: () -> Unit) : PurchasesUpdatedListener {
    companion object { const val ID = "premium_forever" }
    private val client = BillingClient.newBuilder(c).setListener(this).enablePendingPurchases().build()
    private var details: ProductDetails? = null
    var price by mutableStateOf<String?>(null)

    fun start() {
        client.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(r: BillingResult) {
                if (r.responseCode == BillingClient.BillingResponseCode.OK) { query(); restore() }
            }
            override fun onBillingServiceDisconnected() {}
        })
    }

    private fun query() {
        val p = QueryProductDetailsParams.newBuilder().setProductList(
            listOf(QueryProductDetailsParams.Product.newBuilder().setProductId(ID).setProductType(BillingClient.ProductType.INAPP).build())
        ).build()
        client.queryProductDetailsAsync(p) { _, list ->
            details = list.firstOrNull()
            price = details?.oneTimePurchaseOfferDetails?.formattedPrice
        }
    }

    fun restore() {
        if (!client.isReady) { start(); return }
        client.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.INAPP).build()) { _, l -> handle(l) }
    }

    fun buy(a: Activity): Boolean {
        val d = details ?: return false
        val pd = BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(d).build()
        client.launchBillingFlow(a, BillingFlowParams.newBuilder().setProductDetailsParamsList(listOf(pd)).build())
        return true
    }

    override fun onPurchasesUpdated(r: BillingResult, l: MutableList<Purchase>?) {
        if (r.responseCode == BillingClient.BillingResponseCode.OK && l != null) handle(l)
    }

    private fun handle(l: List<Purchase>) {
        for (p in l) {
            if (p.products.contains(ID) && p.purchaseState == Purchase.PurchaseState.PURCHASED) {
                if (!p.isAcknowledged) client.acknowledgePurchase(AcknowledgePurchaseParams.newBuilder().setPurchaseToken(p.purchaseToken).build()) {}
                onPremium()
            }
        }
    }
}
BB_OLD_9
cat > 'app/src/main/java/com/blackboost/app/Notify.kt' <<'BB_OLD_10'
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
        return Result.success()
    }
}
BB_OLD_10
cat > 'app/src/main/java/com/blackboost/app/MainActivity.kt' <<'BB_OLD_11'
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
        vm.billing.start()
        setContent { CompositionLocalProvider(LocalLang provides vm.lang) { App(vm, this) } }
    }

    override fun onResume() {
        super.onResume()
        vm.onResume()
    }
}
BB_OLD_11
echo "▶ Коммит..."
git add -A
GN="$(git config user.name || echo BlackBoost)"; GE="$(git config user.email || echo bb@example.com)"
git -c user.name="$GN" -c user.email="$GE" commit -q -m "Restore Black Boost classic UI with real functions" || echo "(нечего коммитить)"
if git remote | grep -q .; then git push -u origin HEAD && echo "✅ Готово. Открой Actions → Build APK → Artifacts"; else echo "⚠ Нет remote: git remote add origin <URL> && git push -u origin HEAD"; fi

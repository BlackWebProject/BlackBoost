#!/usr/bin/env bash
# NewCreate.sh: обновляет Black Boost по новой спецификации FPS Boost (игры, профили, Game Mode, честная очистка).
# Запуск в Codespaces из корня репозитория:  bash NewCreate.sh
set -e
cd "$(dirname "$0")"
[ -f app/build.gradle.kts ] || { echo "❌ Не найден проект. Сначала выполните setup.sh"; exit 1; }
echo "▶ Обновляю файлы проекта..."
cat > 'app/build.gradle.kts' <<'BB_NEW_1'
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
    implementation("androidx.documentfile:documentfile:1.0.1")
}
BB_NEW_1
cat > 'app/src/main/AndroidManifest.xml' <<'BB_NEW_2'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Только необходимое. Нет доступа ко всем файлам, камере, микрофону, контактам, геолокации, overlay и accessibility. -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.ACCESS_NOTIFICATION_POLICY" />
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
        android:theme="@style/Theme.BlackBoost">
        <activity android:name=".MainActivity" android:exported="true" android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
BB_NEW_2
cat > 'app/src/main/java/com/blackboost/app/Prefs.kt' <<'BB_NEW_3'
package com.blackboost.app

import android.content.Context

class Prof(val mode: String, val clean: Boolean, val dnd: Boolean) {
    fun enc() = "$mode|$clean|$dnd"
    companion object {
        fun dec(s: String?): Prof? {
            val p = s?.split("|") ?: return null
            return if (p.size >= 3) Prof(p[0], p[1] == "true", p[2] == "true") else null
        }
    }
}

class Prefs(c: Context) {
    private val p = c.getSharedPreferences("bb", Context.MODE_PRIVATE)
    var lang: String
        get() = p.getString("lang", "ru") ?: "ru"
        set(v) = p.edit().putString("lang", v).apply()
    var notif: Boolean
        get() = p.getBoolean("notif", false)
        set(v) = p.edit().putBoolean("notif", v).apply()
    var premium: Boolean
        get() = p.getBoolean("pr", false)
        set(v) = p.edit().putBoolean("pr", v).apply()
    var onboarded: Boolean
        get() = p.getBoolean("onb", false)
        set(v) = p.edit().putBoolean("onb", v).apply()
    var treeUri: String?
        get() = p.getString("tree", null)
        set(v) = p.edit().putString("tree", v).apply()
    var dndPrev: Int
        get() = p.getInt("dnd", -1)
        set(v) = p.edit().putInt("dnd", v).apply()
    var energy: String
        get() = p.getString("energy", "bal") ?: "bal"
        set(v) = p.edit().putString("energy", v).apply()
    var defProf: Prof
        get() = Prof.dec(p.getString("def", null)) ?: Prof("perf", true, false)
        set(v) = p.edit().putString("def", v.enc()).apply()
    var games: Set<String>
        get() = p.getStringSet("games", emptySet())?.toSet() ?: emptySet()
        set(v) = p.edit().putStringSet("games", v).apply()
    fun prof(pkg: String): Prof = Prof.dec(p.getString("p_$pkg", null)) ?: defProf
    fun setProf(pkg: String, v: Prof) = p.edit().putString("p_$pkg", v.enc()).apply()
}
BB_NEW_3
cat > 'app/src/main/java/com/blackboost/app/Sys.kt' <<'BB_NEW_4'
package com.blackboost.app

import android.Manifest
import android.app.ActivityManager
import android.app.NotificationManager
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
import android.os.StatFs
import android.os.storage.StorageManager
import android.provider.Settings
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.core.content.ContextCompat
import androidx.core.graphics.drawable.toBitmap
import java.io.File
import kotlin.math.abs

class AppInfo(val pkg: String, val label: String, val icon: ImageBitmap?, val game: Boolean)
class Bat(val pct: Int, val charging: Boolean, val tempC: Float, val minutes: Int?)

/** Только то, что обычному приложению разрешает Android: без доступа ко всем файлам и без слежки за чужими приложениями. */
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
    fun hasDnd(c: Context) = c.getSystemService(NotificationManager::class.java).isNotificationPolicyAccessGranted
    fun hasNotif(c: Context) = Build.VERSION.SDK_INT < 33 || ContextCompat.checkSelfPermission(c, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED
    fun gameModeSupported() = Build.VERSION.SDK_INT >= 31
    fun canLaunch(c: Context, pkg: String) = c.packageManager.getLaunchIntentForPackage(pkg) != null

    fun apps(c: Context): List<AppInfo> {
        val pm = c.packageManager
        return pm.queryIntentActivities(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER), 0)
            .map { it.activityInfo.packageName }.distinct().filter { it != c.packageName }
            .mapNotNull { p ->
                try {
                    val ai = pm.getApplicationInfo(p, 0)
                    val icon = try { pm.getApplicationIcon(p).toBitmap(96, 96).asImageBitmap() } catch (e: Exception) { null }
                    AppInfo(p, pm.getApplicationLabel(ai).toString(), icon, ai.category == ApplicationInfo.CATEGORY_GAME)
                } catch (e: Exception) { null }
            }.sortedBy { it.label.lowercase() }
    }

    private fun rd(p: String): String? = try { File(p).readText().trim() } catch (e: Exception) { null }

    /** Частота ядер относительно максимальной. Если ядро не отдаёт данные, вернёт null. */
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

    private fun tryGo(c: Context, i: Intent): Boolean = try { c.startActivity(i.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)); true } catch (e: Exception) { false }
    private fun go(c: Context, i: Intent) { if (!tryGo(c, i)) tryGo(c, Intent(Settings.ACTION_SETTINGS)) }

    fun appInfo(c: Context, p: String) = go(c, Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$p")))
    fun saver(c: Context) = go(c, Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS))
    fun battOpt(c: Context) = go(c, Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
    fun dnd(c: Context) = go(c, Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
    fun notifSettings(c: Context) = go(c, Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).putExtra(Settings.EXTRA_APP_PACKAGE, c.packageName))
    fun manageStorage(c: Context) { if (!tryGo(c, Intent(StorageManager.ACTION_MANAGE_STORAGE))) go(c, Intent(Settings.ACTION_INTERNAL_STORAGE_SETTINGS)) }

    /** Системный Game Mode / Game Dashboard (Android 12+) или фирменный игровой режим производителя, если он есть. */
    fun gameSettings(c: Context): Boolean {
        val list = listOf(
            Intent("android.settings.GAME_DASHBOARD_SETTINGS"),
            Intent().setClassName("com.miui.securitycenter", "com.miui.gamebooster.ui.GameBoosterRealMainActivity"),
            c.packageManager.getLaunchIntentForPackage("com.samsung.android.game.gamehome")
        )
        for (i in list) if (i != null && tryGo(c, i)) return true
        return false
    }
}
BB_NEW_4
cat > 'app/src/main/java/com/blackboost/app/Cleaner.kt' <<'BB_NEW_5'
package com.blackboost.app

import android.content.Context
import android.net.Uri
import androidx.documentfile.provider.DocumentFile
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

class Del(val size: Long, val del: () -> Boolean)
class Junk(val id: String, val ru: String, val en: String, val items: List<Del>) {
    val bytes: Long get() = items.sumOf { it.size }
}

/**
 * Удаляет только то, к чему у приложения есть законный доступ:
 * 1) собственный кэш Black Boost; 2) файлы в папке, которую пользователь сам выбрал в системном выборе файлов (SAF).
 */
object Cleaner {
    private val tmpExt = setOf("tmp", "temp", "log", "bak", "old", "chk", "dmp")

    fun ownFiles(c: Context): List<File> =
        listOfNotNull(c.cacheDir, c.externalCacheDir).flatMap { d -> d.walkBottomUp().filter { it.isFile }.toList() }

    private fun fileItem(f: File) = Del(f.length()) { f.delete() }

    suspend fun cleanOwn(c: Context): Long = withContext(Dispatchers.IO) {
        var freed = 0L
        ownFiles(c).forEach { val l = it.length(); if (it.delete()) freed += l }
        freed
    }

    private fun walk(d: DocumentFile, depth: Int, tmp: MutableList<Del>, other: MutableList<Del>, cnt: IntArray) {
        if (depth > 6 || cnt[0] > 20000) return
        for (f in d.listFiles()) {
            cnt[0]++
            if (f.isDirectory) { walk(f, depth + 1, tmp, other, cnt); continue }
            val n = (f.name ?: "").lowercase()
            val ext = n.substringAfterLast('.', "")
            val it = Del(f.length()) { f.delete() }
            if (ext in tmpExt || n.startsWith("~")) tmp.add(it)
            else if (ext == "apk" || n.startsWith(".trashed-")) other.add(it)
        }
    }

    suspend fun scan(c: Context, tree: Uri?): List<Junk> = withContext(Dispatchers.IO) {
        val tmp = ArrayList<Del>()
        val other = ArrayList<Del>()
        if (tree != null) {
            try {
                DocumentFile.fromTreeUri(c, tree)?.let { walk(it, 0, tmp, other, IntArray(1)) }
            } catch (e: Exception) { }
        }
        listOf(
            Junk("cache", "Кэш Black Boost", "Black Boost cache", ownFiles(c).map { fileItem(it) }),
            Junk("tmp", "Временные файлы", "Temp files", tmp),
            Junk("other", "Остальное", "Other", other)
        )
    }

    suspend fun clean(items: List<Del>, progress: (Float) -> Unit): Long = withContext(Dispatchers.IO) {
        var freed = 0L
        items.forEachIndexed { i, x ->
            if (x.del()) freed += x.size
            if (i % 10 == 0) progress((i + 1f) / items.size)
        }
        progress(1f)
        freed
    }
}
BB_NEW_5
cat > 'app/src/main/java/com/blackboost/app/Vm.kt' <<'BB_NEW_6'
package com.blackboost.app

import android.app.Activity
import android.app.Application
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.runtime.*
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

enum class Screen { Splash, Onboard, Home, FpsBoost, GameMode, Clean, Cache, Energy, Picker, Profile, Flow, Settings }
class Session(val pkg: String, val label: String, val start: Long, val ramStart: Long, val tempStart: Float, val mode: String)
class Summary(val label: String, val secs: Long, val ramStart: Long, val ramEnd: Long, val tempStart: Float, val tempEnd: Float, val mode: String)
class Explain(val title: String, val text: String, val action: () -> Unit)

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
    var energy by mutableStateOf(prefs.energy)
    var defProf by mutableStateOf(prefs.defProf)
    var games by mutableStateOf(prefs.games)
    var profVer by mutableIntStateOf(0)
    var treeUri by mutableStateOf(prefs.treeUri)
    var paywall by mutableStateOf(false)
    var toast by mutableStateOf<String?>(null)
    var explain by mutableStateOf<Explain?>(null)
    var summary by mutableStateOf<Summary?>(null)
    fun tt(ru: String, en: String) = if (lang == "en") en else ru

    var ramFree by mutableLongStateOf(0L)
    var ramTotal by mutableLongStateOf(1L)
    var stFree by mutableLongStateOf(0L)
    var stTotal by mutableLongStateOf(1L)
    var bat by mutableStateOf(Sys.battery(app))
    var saver by mutableStateOf(false)
    var dndOk by mutableStateOf(false)
    var notifOk by mutableStateOf(false)
    var ownBytes by mutableLongStateOf(0L)
    var apps by mutableStateOf<List<AppInfo>>(emptyList())
    var target by mutableStateOf<String?>(null)
    var mon by mutableStateOf<List<Int?>>(listOf(null, null, null, null))

    var junk by mutableStateOf<List<Junk>?>(null)
    var sel by mutableStateOf(setOf<String>())
    var phase by mutableStateOf("idle") // idle, scanning, found, cleaning, done
    var progress by mutableFloatStateOf(0f)
    var freed by mutableLongStateOf(0L)

    var flowStep by mutableIntStateOf(0)
    var flowReady by mutableStateOf(false)
    var flowFreed by mutableLongStateOf(0L)
    var flowError by mutableStateOf<String?>(null)
    private var session: Session? = null

    val billing = Billing(app) { grantPremium() }

    init { Notify.schedule(app, notif && energy != "save"); refresh() }

    fun grantPremium() { premium = true; prefs.premium = true }
    fun changeLang(l: String) { lang = l; prefs.lang = l }
    fun changeNotif(on: Boolean) { notif = on; prefs.notif = on; Notify.schedule(c, on && energy != "save"); refresh() }
    fun changeEnergy(e: String) { energy = e; prefs.energy = e; Notify.schedule(c, notif && e != "save") }
    fun finishOnboard() { prefs.onboarded = true }
    val onboarded: Boolean get() = prefs.onboarded

    fun refresh() {
        Sys.mem(c).let { ramFree = it.first; ramTotal = it.second }
        Sys.storage().let { stFree = it.first; stTotal = it.second }
        bat = Sys.battery(c); saver = Sys.powerSave(c); dndOk = Sys.hasDnd(c); notifOk = Sys.hasNotif(c)
    }

    fun loadApps() { viewModelScope.launch { apps = withContext(Dispatchers.IO) { Sys.apps(c) } } }
    fun refreshOwn() { viewModelScope.launch { ownBytes = withContext(Dispatchers.IO) { Cleaner.ownFiles(c).sumOf { it.length() } } } }
    fun appOf(pkg: String?) = apps.firstOrNull { it.pkg == pkg }

    // ---- игры и профили ----
    fun prof(pkg: String): Prof { profVer; return prefs.prof(pkg) }
    fun saveProf(pkg: String, p: Prof) { prefs.setProf(pkg, p); profVer++ }
    fun saveDef(p: Prof) { prefs.defProf = p; defProf = p }
    fun addGame(pkg: String) { prefs.setProf(pkg, prefs.defProf); games = games + pkg; prefs.games = games; profVer++ }
    fun removeGame(pkg: String) { games = games - pkg; prefs.games = games }

    fun askDnd() {
        explain = Explain(
            tt("Доступ «Не беспокоить»", "Do Not Disturb access"),
            tt("Нужен, чтобы на время игры скрывать уведомления и вернуть прежний режим после игры. Ничего другого приложение не получит.",
                "Needed to silence notifications during a game and restore your previous mode afterwards. Nothing else is accessed.")
        ) { Sys.dnd(c) }
    }

    // ---- очистка ----
    fun setTree(u: Uri?) {
        if (u != null) try { c.contentResolver.takePersistableUriPermission(u, Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION) } catch (e: Exception) { }
        treeUri = u?.toString(); prefs.treeUri = treeUri; junk = null; phase = "idle"
    }

    fun scan() {
        if (phase == "scanning" || phase == "cleaning") return
        phase = "scanning"
        viewModelScope.launch {
            val r = Cleaner.scan(c, treeUri?.let { Uri.parse(it) })
            junk = r; sel = r.filter { it.bytes > 0 }.map { it.id }.toSet(); phase = "found"
            ownBytes = r.firstOrNull { it.id == "cache" }?.bytes ?: 0L
        }
    }

    fun toggle(id: String) { sel = if (id in sel) sel - id else sel + id }

    fun cleanNow() {
        val items = junk?.filter { it.id in sel }?.flatMap { it.items } ?: return
        phase = "cleaning"; progress = 0f
        viewModelScope.launch {
            freed = Cleaner.clean(items) { progress = it }
            phase = "done"; junk = null; refresh(); refreshOwn()
        }
    }

    fun cleanOwnNow() {
        viewModelScope.launch {
            val f = Cleaner.cleanOwn(c); refreshOwn(); refresh()
            toast = if (f > 0) tt("Освобождено: ${f.sz()}", "Freed: ${f.sz()}") else tt("Очищать было нечего", "Nothing to clean")
        }
    }

    // ---- подготовка и запуск игры ----
    fun runFlow() {
        val pkg = target ?: return
        flowStep = 0; flowReady = false; flowFreed = 0; flowError = null
        viewModelScope.launch {
            delay(350)
            if (!Sys.canLaunch(c, pkg)) { flowError = tt("Игра не найдена на этом устройстве", "Game not found on this device"); return@launch }
            flowStep = 1; delay(350)
            flowStep = 2; delay(350)
            refresh(); flowStep = 3; delay(350)
            if (prof(pkg).clean) flowFreed = Cleaner.cleanOwn(c)
            flowStep = 4; flowReady = true
        }
    }

    fun launchGame(a: Activity) {
        val pkg = target ?: return
        val p = prof(pkg)
        if (premium && p.dnd) dndOn()
        val label = appOf(pkg)?.label ?: pkg
        session = Session(pkg, label, System.currentTimeMillis(), Sys.mem(c).first, bat.tempC, p.mode)
        val i = c.packageManager.getLaunchIntentForPackage(pkg)
        if (i == null) { session = null; restoreDnd(); toast = tt("Не удалось запустить игру", "Could not launch the game"); return }
        a.startActivity(i)
    }

    private fun dndOn() {
        val nm = c.getSystemService(NotificationManager::class.java)
        if (nm.isNotificationPolicyAccessGranted) {
            prefs.dndPrev = nm.currentInterruptionFilter
            nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_ALARMS)
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

    /** Возврат в приложение после игры: восстанавливаем режим и показываем только реально измеренное. */
    fun onResume() {
        refresh()
        val s = session
        if (s != null) {
            session = null; restoreDnd()
            val secs = (System.currentTimeMillis() - s.start) / 1000
            if (secs >= 5) summary = Summary(s.label, secs, s.ramStart, Sys.mem(c).first, s.tempStart, bat.tempC, s.mode)
        } else if (prefs.dndPrev >= 0) restoreDnd()
    }

    fun pollMon() {
        refresh()
        mon = listOf(Sys.cpu(), Sys.gpu(), bat.tempC.toInt(), ((ramTotal - ramFree) * 100 / ramTotal).toInt())
    }

    fun openGameSettings(): Boolean = Sys.gameSettings(c)
}
BB_NEW_6
cat > 'app/src/main/java/com/blackboost/app/UI.kt' <<'BB_NEW_7'
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

fun icon(d: String): ImageVector = ImageVector.Builder(24.dp, 24.dp, 24f, 24f).addPath(
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

val Ok = Color(0xFF3DDC84); val Warn = Color(0xFFFFC107); val Off = Color(0xFF8F8980); val Bad = Color(0xFFFF5252)

@Composable
fun Dot(c: Color) { Box(Modifier.size(9.dp).clip(CircleShape).background(c)) }

/** Строка функции с настоящим статусом: зелёный — активно, жёлтый — нужна настройка, серый — не используется, красный — недоступно. */
@Composable
fun Feat(ic: ImageVector, title: String, st: Color, stText: String, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).card(16).clickable(onClick = onClick).padding(16.dp, 14.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Icon(ic, null, Modifier.size(26.dp), tint = Em)
        Column(Modifier.weight(1f)) {
            Txt(title, 15, w = FontWeight.SemiBold)
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) { Dot(st); Txt(stText, 12, Mu) }
        }
        Txt("›", 22, Mu)
    }
}
BB_NEW_7
cat > 'app/src/main/java/com/blackboost/app/Screens.kt' <<'BB_NEW_8'
@file:Suppress("DEPRECATION")

package com.blackboost.app

import android.Manifest
import android.app.Activity
import android.os.Build
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
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.*
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import kotlinx.coroutines.*

@Composable
fun App(vm: Vm, act: Activity) {
    BackHandler(enabled = vm.screen != Screen.Home && vm.screen != Screen.Splash && vm.screen != Screen.Onboard) { vm.back() }
    Box(Modifier.fillMaxSize().background(Bg)) {
        when (vm.screen) {
            Screen.Splash -> SplashS(vm)
            Screen.Onboard -> OnboardS(vm)
            Screen.Home -> HomeS(vm)
            Screen.FpsBoost -> FpsBoostS(vm)
            Screen.Flow -> FlowS(vm, act)
            Screen.GameMode -> GameModeS(vm)
            Screen.Clean -> CleanS(vm)
            Screen.Cache -> CacheS(vm)
            Screen.Energy -> EnergyS(vm)
            Screen.Picker -> PickerS(vm)
            Screen.Profile -> ProfileS(vm)
            Screen.Settings -> SettingsS(vm)
        }
        vm.toast?.let {
            Box(Modifier.align(Alignment.BottomCenter).padding(24.dp, 0.dp, 24.dp, 60.dp).clip(RoundedCornerShape(14.dp)).background(Color(0xFF1A1512)).padding(16.dp, 12.dp)) {
                Txt(it, 13, w = FontWeight.SemiBold, align = TextAlign.Center)
            }
            LaunchedEffect(it) { delay(2800); vm.toast = null }
        }
        if (vm.paywall) Paywall(vm, act)
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
        vm.summary?.let { s ->
            Dialog(onDismissRequest = { vm.summary = null }) {
                Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(24.dp)).background(Bg).border(1.dp, Ln, RoundedCornerShape(24.dp)).padding(20.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    Txt(t("Игровая сессия завершена", "Game session finished"), 18, w = FontWeight.Bold)
                    Txt(s.label, 14, Mu)
                    Item(Ic.clock, t("Длительность", "Duration"), "${s.secs / 60} ${t("мин", "min")} ${s.secs % 60} ${t("с", "s")}")
                    Item(Ic.bolt, t("Профиль", "Profile"), modeName(s.mode))
                    Item(Ic.chart, t("Доступная память", "Available memory"), "${s.ramStart.sz()} → ${s.ramEnd.sz()}")
                    Item(Ic.battery, t("Температура батареи", "Battery temperature"), "${s.tempStart}°C → ${s.tempEnd}°C")
                    Txt(t("Показаны только измеренные значения. FPS приложение не измеряет.", "Only measured values are shown. FPS is not measured by the app."), 11, Mu)
                    HotBtn("OK") { vm.summary = null }
                }
            }
        }
    }
}

@Composable
fun modeName(m: String): String = when (m) {
    "max" -> t("Максимальная производительность", "Maximum performance")
    "perf" -> t("Производительность", "Performance")
    "bal" -> t("Баланс", "Balanced")
    else -> t("Экономия", "Battery saver")
}

@Composable
fun Page(vm: Vm, title: String?, back: Boolean = true, bottom: (@Composable () -> Unit)? = null, content: @Composable ColumnScope.() -> Unit) {
    Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding()) {
        if (title != null) TopBar(title, back) { vm.back() }
        Column(Modifier.weight(1f).verticalScroll(rememberScrollState()).padding(20.dp, 8.dp), verticalArrangement = Arrangement.spacedBy(12.dp), content = content)
        if (bottom != null) Box(Modifier.padding(20.dp, 4.dp, 20.dp, 16.dp)) { bottom() }
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
        vm.go(if (vm.onboarded) Screen.Home else Screen.Onboard, true)
    }
    Column(Modifier.fillMaxSize().padding(32.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Spacer(Modifier.weight(1f))
        Box(contentAlignment = Alignment.Center) {
            Box(Modifier.size(280.dp).background(Brush.radialGradient(listOf(Em.copy(alpha = glow), Color.Transparent))))
            Image(painterResource(R.drawable.ic_logo), null, Modifier.height(130.dp).aspectRatio(636f / 603f).scale(sc.value))
        }
        Spacer(Modifier.height(20.dp))
        Txt("Black", 50, disp = true, w = FontWeight.Black)
        Txt("Boost", 50, disp = true, w = FontWeight.Black, brush = Hot)
        Spacer(Modifier.weight(1f))
        Box(Modifier.width(200.dp)) { Bar(p.value) }
        Spacer(Modifier.height(12.dp))
        Txt(t("Загрузка...", "Loading..."), 12, Mu)
    }
}

@Composable
fun OnboardS(vm: Vm) {
    var step by remember { mutableIntStateOf(0) }
    val perm = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { ok -> vm.changeNotif(ok); step = 3 }
    Column(Modifier.fillMaxSize().statusBarsPadding().navigationBarsPadding().padding(28.dp), horizontalAlignment = Alignment.CenterHorizontally) {
        Spacer(Modifier.weight(1f))
        Image(painterResource(R.drawable.ic_logo), null, Modifier.height(90.dp).aspectRatio(636f / 603f))
        Spacer(Modifier.height(24.dp))
        when (step) {
            0 -> {
                Txt(t("Настроим FPS Boost", "Let's set up FPS Boost"), 26, disp = true, w = FontWeight.Black, align = TextAlign.Center)
                Spacer(Modifier.height(12.dp))
                Txt(t("Приложению нужны только разрешения, необходимые для выбранных функций. Вы сможете изменить их позже.",
                    "The app only asks for permissions needed by the features you choose. You can change them later."), 15, Mu, align = TextAlign.Center)
            }
            1 -> {
                Txt(t("Без лишнего", "No extras"), 26, disp = true, w = FontWeight.Black, align = TextAlign.Center)
                Spacer(Modifier.height(12.dp))
                Txt(t("FPS Boost не изменяет системные файлы и не требует лишних разрешений: ни камеры, ни геолокации, ни контактов, ни полного доступа к хранилищу.",
                    "FPS Boost does not modify system files and needs no extra permissions: no camera, location, contacts or full storage access."), 15, Mu, align = TextAlign.Center)
                Spacer(Modifier.height(10.dp))
                Txt(t("И никаких обещаний «+60 FPS»: только то, что Android реально позволяет.", "And no «+60 FPS» promises: only what Android really allows."), 13, Am, align = TextAlign.Center)
            }
            2 -> {
                Txt(t("Уведомления", "Notifications"), 26, disp = true, w = FontWeight.Black, align = TextAlign.Center)
                Spacer(Modifier.height(12.dp))
                Txt(t("По желанию: предупреждения о нехватке места и перегреве батареи. Можно пропустить.", "Optional: low storage and battery overheating alerts. You can skip this."), 15, Mu, align = TextAlign.Center)
            }
            else -> {
                Txt(t("Добавьте первую игру", "Add your first game"), 26, disp = true, w = FontWeight.Black, align = TextAlign.Center)
                Spacer(Modifier.height(12.dp))
                Txt(t("Для каждой игры создаётся свой профиль: режим, очистка перед запуском, «Не беспокоить».", "Each game gets its own profile: mode, clean before launch, Do Not Disturb."), 15, Mu, align = TextAlign.Center)
            }
        }
        Spacer(Modifier.weight(1f))
        when (step) {
            0, 1 -> HotBtn(t("Продолжить", "Continue")) { step++ }
            2 -> {
                HotBtn(t("Разрешить", "Allow")) { if (Build.VERSION.SDK_INT >= 33) perm.launch(Manifest.permission.POST_NOTIFICATIONS) else { vm.changeNotif(true); step = 3 } }
                Txt(t("Пропустить", "Skip"), 14, Mu, modifier = Modifier.clickable { step = 3 }.padding(14.dp))
            }
            else -> {
                HotBtn(t("Выбрать игру", "Choose a game")) { vm.finishOnboard(); vm.go(Screen.Picker, true) }
                Txt(t("Пропустить", "Skip"), 14, Mu, modifier = Modifier.clickable { vm.finishOnboard(); vm.go(Screen.Home, true) }.padding(14.dp))
            }
        }
    }
}

@Composable
fun HomeS(vm: Vm) {
    LaunchedEffect(Unit) { vm.loadApps(); vm.refreshOwn(); while (true) { vm.refresh(); delay(4000) } }
    val junkB = vm.junk?.sumOf { it.bytes } ?: 0L
    val ready = vm.games.isNotEmpty()
    Page(vm, null, false) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Image(painterResource(R.drawable.ic_logo), null, Modifier.height(26.dp).aspectRatio(636f / 603f))
            Txt("Black Boost", 19, disp = true, w = FontWeight.Bold, modifier = Modifier.weight(1f))
            Box(Modifier.size(40.dp).clip(CircleShape).background(Sf).border(1.dp, Ln, CircleShape).clickable { vm.go(Screen.Settings) }, Alignment.Center) {
                Icon(Ic.gear, null, Modifier.size(20.dp), tint = Tx)
            }
        }
        Column(Modifier.fillMaxWidth().padding(vertical = 8.dp), horizontalAlignment = Alignment.CenterHorizontally) {
            Box(contentAlignment = Alignment.Center) {
                Box(Modifier.size(200.dp).background(Brush.radialGradient(listOf(Em.copy(alpha = 0.3f), Color.Transparent))))
                Image(painterResource(R.drawable.ic_logo), null, Modifier.height(90.dp).aspectRatio(636f / 603f))
            }
            Txt(if (ready) t("Готово к игре", "Ready to play") else t("Добавьте первую игру", "Add your first game"), 24, disp = true, w = FontWeight.Black)
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Column(Modifier.weight(1f).card().padding(16.dp)) { Txt("RAM", 12, Mu); Txt(vm.ramFree.sz(), 20, Am, FontWeight.Bold, true); Txt(t("свободно", "free"), 11, Mu) }
            Column(Modifier.weight(1f).card().padding(16.dp)) { Txt("Storage", 12, Mu); Txt(vm.stFree.sz(), 20, Am, FontWeight.Bold, true); Txt(t("свободно", "free"), 11, Mu) }
        }
        Feat(Ic.bolt, "FPS BOOST", if (ready) Ok else Warn, if (ready) t("Готов", "Ready") else t("Добавьте игру", "Add a game")) { vm.go(Screen.FpsBoost) }
        Feat(Ic.play, "GAME MODE", if (vm.premium && vm.defProf.dnd && !vm.dndOk) Warn else Ok,
            if (vm.premium && vm.defProf.dnd && !vm.dndOk) t("Требуется разрешение", "Permission needed") else t("Готов", "Ready")) { vm.go(Screen.GameMode) }
        Feat(Ic.trash, t("ОЧИСТКА", "CLEANER"), if (junkB > 0) Ok else Off,
            if (junkB > 0) t("Можно очистить: ", "Can clean: ") + junkB.sz() else t("Не используется", "Not used")) { vm.go(Screen.Clean) }
        Feat(Ic.battery, t("ЭНЕРГОСБЕРЕЖЕНИЕ", "POWER SAVING"), if (vm.saver) Ok else Off,
            if (vm.saver) t("Активно", "Active") else t("Не используется", "Not used")) { vm.go(Screen.Energy) }
        Feat(Ic.db, t("ОЧИСТКА КЭША", "CACHE CLEANER"), if (vm.ownBytes > 0) Ok else Off,
            if (vm.ownBytes > 0) t("Можно очистить: ", "Can clean: ") + vm.ownBytes.sz() else t("Не используется", "Not used")) { vm.go(Screen.Cache) }
        Txt(t("Мои игры", "My games"), 16, w = FontWeight.Bold, modifier = Modifier.padding(top = 8.dp))
        vm.games.mapNotNull { vm.appOf(it) }.forEach { a ->
            Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).card(16).clickable { vm.target = a.pkg; vm.go(Screen.Flow) }.padding(12.dp, 10.dp),
                verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                a.icon?.let { Image(it, null, Modifier.size(40.dp)) }
                Column(Modifier.weight(1f)) { Txt(a.label, 15, w = FontWeight.SemiBold); Txt(modeName(vm.prof(a.pkg).mode), 12, Mu) }
                Box(Modifier.size(36.dp).clickable { vm.target = a.pkg; vm.go(Screen.Profile) }, Alignment.Center) { Icon(Ic.gear, null, Modifier.size(20.dp), tint = Mu) }
            }
        }
        Item(Ic.play, t("Добавить игру", "Add a game"), null, trail = { Txt("+", 22, Am) }) { vm.go(Screen.Picker) }
    }
}

@Composable
fun FpsBoostS(vm: Vm) {
    LaunchedEffect(Unit) { vm.loadApps() }
    Page(vm, "FPS Boost") {
        Txt(t("Выберите игру", "Choose a game"), 16, w = FontWeight.Bold)
        Txt(t("Перед запуском приложение применит профиль игры и очистит собственный кэш. Системные настройки при необходимости подтверждаете вы.",
            "Before launch the app applies the game profile and clears its own cache. You confirm system settings when needed."), 12, Mu)
        vm.games.mapNotNull { vm.appOf(it) }.forEach { a ->
            Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).card(16).clickable { vm.target = a.pkg; vm.go(Screen.Flow) }.padding(12.dp, 10.dp),
                verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                a.icon?.let { Image(it, null, Modifier.size(40.dp)) }
                Column(Modifier.weight(1f)) { Txt(a.label, 15, w = FontWeight.SemiBold); Txt(modeName(vm.prof(a.pkg).mode), 12, Mu) }
                Txt("›", 22, Mu)
            }
        }
        if (vm.games.isEmpty()) Txt(t("Игр пока нет.", "No games yet."), 13, Mu)
        Item(Ic.play, t("Добавить игру", "Add a game"), null, trail = { Txt("+", 22, Am) }) { vm.go(Screen.Picker) }
    }
}

@Composable
fun FlowS(vm: Vm, act: Activity) {
    val pkg = vm.target
    val a = vm.appOf(pkg)
    LaunchedEffect(pkg) { vm.runFlow() }
    val p = pkg?.let { vm.prof(it) } ?: vm.defProf
    val steps = listOf(t("Игра найдена", "Game found"), t("Профиль загружен", "Profile loaded"), t("Доступные оптимизации проверены", "Available optimizations checked"), t("Временные файлы обработаны", "Temporary files processed"))
    Page(vm, t("Оптимизация", "Optimization"), bottom = {
        HotBtn(if (vm.flowReady) t("ЗАПУСТИТЬ ИГРУ", "LAUNCH GAME") else t("Проверка устройства...", "Checking device..."), vm.flowReady) { vm.launchGame(act) }
    }) {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
            a?.icon?.let { Image(it, null, Modifier.size(52.dp)) }
            Column { Txt(t("Оптимизация для ", "Optimization for ") + (a?.label ?: ""), 17, w = FontWeight.Bold); Txt(modeName(p.mode), 12, Mu) }
        }
        steps.forEachIndexed { i, s -> Item(null, s, null, trail = { MiniCheck(vm.flowStep > i) }) }
        vm.flowError?.let { Txt(it, 13, Bad) }
        if (vm.flowReady) Txt(if (vm.flowFreed > 0) t("Очищено собственного кэша: ", "Own cache cleared: ") + vm.flowFreed.sz() else t("Собственный кэш пуст — очищать нечего.", "Own cache is empty — nothing to clean."), 12, Mu)
        if (vm.saver && (p.mode == "perf" || p.mode == "max"))
            Item(Ic.battery, t("Энергосбережение Android включено", "Android power saving is on"), t("Оно может снижать производительность. Отключите вручную.", "It may reduce performance. Turn it off manually."),
                trail = { Txt(t("Открыть", "Open"), 13, Am, FontWeight.Bold) }) { Sys.saver(act) }
        if (premiumNeeds(vm, p)) Item(Ic.bell, t("Нужен доступ «Не беспокоить»", "Do Not Disturb access needed"), t("Без него уведомления в игре не скрываются", "Without it notifications are not hidden"),
            trail = { Txt(t("Дать", "Grant"), 13, Am, FontWeight.Bold) }) { vm.askDnd() }
        Txt(t("Во время игры FPS Boost ничего не выполняет в фоне.", "While you play, FPS Boost does nothing in the background."), 11, Mu)
    }
}

private fun premiumNeeds(vm: Vm, p: Prof) = vm.premium && p.dnd && !vm.dndOk

@Composable
fun ProfileEditor(vm: Vm, p: Prof, on: (Prof) -> Unit) {
    listOf("perf", "max", "bal", "save").forEach { m ->
        Item(null, modeName(m), if (m == "max" && !vm.premium) "Premium" else null, trail = { MiniCheck(p.mode == m) }) {
            if (m == "max" && !vm.premium) vm.paywall = true else on(Prof(m, p.clean, p.dnd))
        }
    }
    Item(Ic.trash, t("Очистка перед запуском", "Clean before launch"), t("Только собственный кэш Black Boost", "Only Black Boost's own cache"),
        trail = { Tog(p.clean) { on(Prof(p.mode, it, p.dnd)) } })
    Item(Ic.bell, t("Не беспокоить на время игры", "Do Not Disturb during game"), "Game Mode+ · Premium",
        trail = { Tog(p.dnd) { v -> if (!vm.premium) vm.paywall = true else if (v && !vm.dndOk) vm.askDnd() else on(Prof(p.mode, p.clean, v)) } })
}

@Composable
fun GameModeS(vm: Vm) {
    LaunchedEffect(vm.premium) { while (vm.premium) { vm.pollMon(); delay(1000) } }
    Page(vm, "Game Mode", bottom = { HotBtn(t("Запустить игру", "Launch game")) { vm.go(Screen.FpsBoost) } }) {
        Item(Ic.play, t("Системный Game Mode", "System Game Mode"),
            if (Sys.gameModeSupported()) t("Поддерживается Android 12+. Включается в Game Dashboard игры.", "Supported on Android 12+. Enabled in the game's Game Dashboard.") else t("Недоступно на этом устройстве", "Not available on this device"),
            trail = { Dot(if (Sys.gameModeSupported()) Ok else Bad) })
        if (Sys.gameModeSupported()) HotBtn(t("Открыть системный Game Mode", "Open system Game Mode")) {
            if (!vm.openGameSettings()) vm.toast = vm.tt("На этом телефоне нет отдельного экрана Game Mode. Откройте Game Dashboard из игры.", "No separate Game Mode screen on this phone. Open Game Dashboard from inside a game.")
        }
        Txt(t("Профиль по умолчанию", "Default profile"), 16, w = FontWeight.Bold, modifier = Modifier.padding(top = 6.dp))
        ProfileEditor(vm, vm.defProf) { vm.saveDef(it) }
        if (vm.premium) {
            val names = listOf("CPU", "GPU", t("Темп.", "Temp"), "RAM")
            val vals = listOf(vm.mon[0], vm.mon[1], vm.mon[2], vm.mon[3])
            val shown = vals.indices.filter { vals[it] != null }
            Column(Modifier.fillMaxWidth().card().padding(16.dp)) {
                Txt("Performance Monitor", 14, w = FontWeight.Bold)
                Txt(t("Только данные, которые отдаёт ваше устройство", "Only data your device exposes"), 11, Mu)
                Spacer(Modifier.height(10.dp))
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    shown.forEach { i ->
                        Column(Modifier.weight(1f)) {
                            Txt(names[i], 11, Mu)
                            Txt("${vals[i]}" + if (i == 2) "°" else "%", 17, Am, FontWeight.Bold, true)
                            Spacer(Modifier.height(6.dp)); Bar((vals[i] ?: 0) / (if (i == 2) 60f else 100f))
                        }
                    }
                }
            }
        } else Row(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(Brush.horizontalGradient(listOf(Color(0xFF2A1208), Sf)))
                .border(1.dp, Color(0xFF5A2C1A), RoundedCornerShape(16.dp)).clickable { vm.paywall = true }.padding(14.dp),
            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Image(painterResource(R.drawable.ic_crown), null, Modifier.height(28.dp).aspectRatio(828f / 545f))
            Column(Modifier.weight(1f)) {
                Txt("Premium Boost", 15, w = FontWeight.Bold, disp = true)
                Txt(t("Monitor, Game Mode+ и максимальный профиль", "Monitor, Game Mode+ and maximum profile"), 12, Mu)
            }
        }
    }
}

@Composable
fun ProfileS(vm: Vm) {
    val pkg = vm.target ?: return
    val a = vm.appOf(pkg)
    Page(vm, a?.label ?: "") {
        ProfileEditor(vm, vm.prof(pkg)) { vm.saveProf(pkg, it) }
        Txt(t("Убрать из моих игр", "Remove from my games"), 14, Bad, modifier = Modifier.fillMaxWidth().clickable { vm.removeGame(pkg); vm.back() }.padding(14.dp), align = TextAlign.Center)
    }
}

@Composable
fun PickerS(vm: Vm) {
    var tab by remember { mutableIntStateOf(0) }
    LaunchedEffect(Unit) { vm.loadApps() }
    val list = if (tab == 0) vm.apps.filter { it.game } else vm.apps
    Page(vm, t("Добавить игру", "Add a game")) {
        Tabs(listOf(t("Игры", "Games"), t("Все приложения", "All apps")), tab) { tab = it }
        if (tab == 0 && list.isEmpty()) Txt(t("Система не пометила ни одно приложение как игру. Откройте вкладку «Все приложения».", "The system did not mark any app as a game. Open the “All apps” tab."), 13, Mu)
        list.forEach { a ->
            Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).card(16).clickable {
                if (a.pkg !in vm.games) { vm.addGame(a.pkg); vm.toast = vm.tt("Игра добавлена", "Game added") }
                vm.back()
            }.padding(12.dp, 10.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                a.icon?.let { Image(it, null, Modifier.size(40.dp)) }
                Txt(a.label, 15, w = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                MiniCheck(a.pkg in vm.games)
            }
        }
    }
}

@Composable
fun CleanS(vm: Vm) {
    val pick = rememberLauncherForActivityResult(ActivityResultContracts.OpenDocumentTree()) { vm.setTree(it) }
    LaunchedEffect(Unit) { if (vm.phase == "done") vm.phase = "idle" }
    val inf by rememberInfiniteTransition(label = "s").animateFloat(0f, 1f, infiniteRepeatable(tween(1400, easing = LinearEasing)), label = "s")
    val j = vm.junk
    val tot = j?.sumOf { it.bytes } ?: 0L
    val selB = j?.filter { it.id in vm.sel }?.sumOf { it.bytes } ?: 0L
    Page(vm, t("Очистка", "Cleaner"), bottom = {
        when {
            vm.phase == "done" -> HotBtn(t("Готово", "Done")) { vm.back() }
            vm.phase == "scanning" -> HotBtn(t("Сканируем...", "Scanning..."), false) {}
            vm.phase == "cleaning" -> HotBtn(t("Идёт очистка...", "Cleaning..."), false) {}
            j != null && tot > 0 -> HotBtn(t("Очистить ", "Clean ") + selB.sz(), selB > 0) { vm.cleanNow() }
            else -> HotBtn(t("Сканировать", "Scan")) { vm.scan() }
        }
    }) {
        Box(Modifier.fillMaxWidth(), Alignment.Center) {
            val rp = when (vm.phase) { "scanning" -> inf; "cleaning" -> vm.progress; "done" -> 1f; else -> if (j != null && tot == 0L) 1f else 0f }
            Ring(rp, 210.dp, anim = vm.phase != "scanning") {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    when {
                        vm.phase == "done" -> { CheckMark(64.dp); Txt(t("Очистка завершена", "Cleaning complete"), 13, Tx, FontWeight.SemiBold); Txt(t("Освобождено: ", "Freed: ") + vm.freed.sz(), 13, Mu) }
                        vm.phase == "scanning" -> Txt(t("Сканируем...", "Scanning..."), 15, Mu)
                        vm.phase == "cleaning" -> Txt("${(vm.progress * 100).toInt()}%", 38, disp = true, w = FontWeight.Black)
                        j == null -> Txt(t("Нажмите «Сканировать»", "Tap “Scan”"), 13, Mu, align = TextAlign.Center)
                        tot > 0 -> { Txt(t("Можно очистить", "Can clean"), 12, Mu); Txt(tot.sz(), 30, disp = true, w = FontWeight.Black) }
                        else -> { CheckMark(64.dp); Txt(t("Очищать нечего", "Nothing to clean"), 13, Mu) }
                    }
                }
            }
        }
        if (vm.phase == "found") j?.forEach { x ->
            Item(null, t(x.ru, x.en), null, trail = { Txt(x.bytes.sz(), 13, Am, FontWeight.Bold); Spacer(Modifier.width(10.dp)); MiniCheck(x.id in vm.sel) }) { if (x.bytes > 0) vm.toggle(x.id) }
        }
        Item(Ic.db, t("Папка для проверки", "Folder to scan"),
            if (vm.treeUri != null) t("Выбрана вами через системный выбор файлов", "Chosen by you in the system file picker") else t("Не выбрана. Без неё проверяется только кэш Black Boost.", "Not chosen. Only Black Boost's own cache is scanned."),
            trail = { Txt(if (vm.treeUri != null) t("Сменить", "Change") else t("Выбрать", "Choose"), 13, Am, FontWeight.Bold) }) { pick.launch(null) }
        if (vm.treeUri != null) Txt(t("Сбросить папку", "Reset folder"), 13, Mu, modifier = Modifier.fillMaxWidth().clickable { vm.setTree(null) }.padding(8.dp), align = TextAlign.Center)
    }
}

@Composable
fun CacheS(vm: Vm) {
    val ctx = androidx.compose.ui.platform.LocalContext.current
    LaunchedEffect(Unit) { vm.loadApps(); vm.refreshOwn() }
    Page(vm, t("Очистка кэша", "Cache cleaner")) {
        Column(Modifier.fillMaxWidth().card().padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Txt(t("Найдено доступных для очистки данных", "Data available to clean"), 12, Mu)
            Txt(vm.ownBytes.sz(), 28, Am, FontWeight.Black, true)
            Txt(t("Это собственный кэш Black Boost. Кэш других приложений Android не даёт удалять напрямую.", "This is Black Boost's own cache. Android does not let apps delete other apps' cache directly."), 12, Mu)
            HotBtn(t("Очистить кэш Black Boost", "Clear Black Boost cache"), vm.ownBytes > 0) { vm.cleanOwnNow() }
        }
        Item(Ic.db, t("Системная очистка", "System cleanup"), t("Откроется экран Android «Освободить место»", "Opens Android's “Free up space” screen"),
            trail = { Txt("›", 22, Mu) }) { Sys.manageStorage(ctx) }
        Txt(t("Кэш приложения → открыть экран Android", "App cache → open the Android screen"), 14, w = FontWeight.Bold, modifier = Modifier.padding(top = 6.dp))
        Txt(t("В системном экране выберите «Хранилище» → «Очистить кэш».", "On the system screen choose “Storage” → “Clear cache”."), 12, Mu)
        (vm.apps.filter { it.pkg in vm.games } + vm.apps.filter { it.pkg !in vm.games }).forEach { a ->
            Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).card(16).clickable { Sys.appInfo(ctx, a.pkg) }.padding(12.dp, 10.dp),
                verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                a.icon?.let { Image(it, null, Modifier.size(36.dp)) }
                Txt(a.label, 14, w = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                Txt("›", 20, Mu)
            }
        }
    }
}

@Composable
fun EnergyS(vm: Vm) {
    val ctx = androidx.compose.ui.platform.LocalContext.current
    LaunchedEffect(Unit) { while (true) { vm.refresh(); delay(3000) } }
    val b = vm.bat
    Page(vm, t("Энергосбережение", "Power saving")) {
        Column(Modifier.fillMaxWidth().card().padding(20.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(verticalAlignment = Alignment.Bottom) {
                Txt("${b.pct}", 44, disp = true, w = FontWeight.Black); Txt("%", 20, Mu, modifier = Modifier.padding(bottom = 6.dp, start = 2.dp))
                Spacer(Modifier.weight(1f))
                Txt("${b.tempC}°C", 16, Am, FontWeight.Bold)
            }
            Bar(b.pct / 100f)
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Dot(if (vm.saver) Ok else Off)
                Txt(if (vm.saver) t("Энергосбережение Android включено", "Android power saving is on") else t("Энергосбережение Android выключено", "Android power saving is off"), 12, Mu)
            }
            b.minutes?.let { Txt((if (b.charging) t("До полной зарядки (оценка): ", "Until full (estimate): ") else t("Оценка по текущему расходу: ", "Estimate at current drain: ")) + "${it / 60} ${t("ч", "h")} ${it % 60} ${t("мин", "min")}", 12, Mu) }
        }
        Item(Ic.battery, t("Энергосбережение Android", "Android power saving"), t("Откроется системная настройка", "Opens the system setting"), trail = { Tog(vm.saver) { Sys.saver(ctx) } }) { Sys.saver(ctx) }
        Item(Ic.clock, t("Оптимизация расхода в фоне", "Background usage optimization"), t("Системный список приложений", "System app list"), trail = { Txt("›", 22, Mu) }) { Sys.battOpt(ctx) }
        Txt(t("Поведение Black Boost", "Black Boost behavior"), 16, w = FontWeight.Bold, modifier = Modifier.padding(top = 6.dp))
        listOf(
            Triple("save", t("Максимальная экономия", "Maximum saving"), t("Без уведомлений и фоновых проверок", "No notifications or background checks")),
            Triple("bal", t("Баланс", "Balanced"), t("Обычная работа приложения", "Normal operation")),
            Triple("perf", t("Производительность", "Performance"), t("Никаких действий во время игры", "No actions during a game"))
        ).forEach { (id, n, d) -> Item(null, n, d, trail = { MiniCheck(vm.energy == id) }) { vm.changeEnergy(id) } }
        Txt(t("Время работы зависит от устройства, игры, яркости и температуры, поэтому приложение не обещает конкретный процент.", "Battery life depends on device, game, brightness and temperature, so the app does not promise a specific percentage."), 11, Mu)
    }
}

@Composable
fun SettingsS(vm: Vm) {
    val ctx = androidx.compose.ui.platform.LocalContext.current
    val perm = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { ok -> vm.changeNotif(ok) }
    LaunchedEffect(Unit) { vm.refresh() }
    Page(vm, t("Настройки", "Settings")) {
        Row(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(Brush.horizontalGradient(listOf(Color(0xFF2A1208), Sf)))
                .border(1.dp, Color(0xFF5A2C1A), RoundedCornerShape(18.dp)).clickable { vm.paywall = true }.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Image(painterResource(R.drawable.ic_crown), null, Modifier.height(30.dp).aspectRatio(828f / 545f))
            Column(Modifier.weight(1f)) {
                Txt("Premium Boost", 16, disp = true, w = FontWeight.Bold)
                Txt(if (vm.premium) t("Активен навсегда", "Active forever") else t("Получить Premium", "Get Premium"), 12, Mu)
            }
            Txt(if (vm.premium) t("Активен", "Active") else "›", 15, Am, FontWeight.Bold, true)
        }
        Column(Modifier.fillMaxWidth().card().padding(16.dp), verticalArrangement = Arrangement.spacedBy(14.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                Icon(Ic.globe, null, Modifier.size(24.dp), tint = Em); Txt(t("Язык", "Language"), 15, w = FontWeight.Bold)
            }
            Tabs(listOf("Русский", "English"), if (vm.lang == "en") 1 else 0) { vm.changeLang(if (it == 1) "en" else "ru") }
        }
        Item(Ic.bell, t("Уведомления", "Notifications"), t("Мало места и перегрев батареи", "Low storage and battery overheating"), trail = {
            Tog(vm.notif && vm.notifOk) { on ->
                if (on && !vm.notifOk) vm.explain = Explain(vm.tt("Разрешение на уведомления", "Notification permission"),
                    vm.tt("Нужно только для предупреждений о нехватке места и перегреве. Без него приложение работает полностью.", "Only needed for low-storage and overheating alerts. The app works fully without it.")) {
                    if (Build.VERSION.SDK_INT >= 33) perm.launch(Manifest.permission.POST_NOTIFICATIONS) else vm.changeNotif(true)
                } else vm.changeNotif(on)
            }
        })
        Txt(t("Разрешения", "Permissions"), 16, w = FontWeight.Bold, modifier = Modifier.padding(top = 6.dp))
        Item(Ic.bell, t("Уведомления", "Notifications"), if (vm.notifOk) t("Разрешено", "Allowed") else t("Не требуется для работы", "Not required to use the app"),
            trail = { Dot(if (vm.notifOk) Ok else Off) }) { Sys.notifSettings(ctx) }
        Item(Ic.play, t("Не беспокоить", "Do Not Disturb"), if (vm.dndOk) t("Доступ выдан (Game Mode+)", "Access granted (Game Mode+)") else t("Нужен только для Game Mode+", "Only needed for Game Mode+"),
            trail = { Dot(if (vm.dndOk) Ok else if (vm.premium) Warn else Off) }) { vm.askDnd() }
        Item(Ic.db, t("Папка для очистки", "Cleanup folder"), if (vm.treeUri != null) t("Выбрана вами", "Chosen by you") else t("Не выбрана", "Not chosen"),
            trail = { Dot(if (vm.treeUri != null) Ok else Off) }) { vm.go(Screen.Clean) }
        Txt(t("Black Boost не изменяет системные файлы и не просит доступ ко всем файлам, камере, микрофону, контактам или геолокации.", "Black Boost does not modify system files and never asks for full storage, camera, microphone, contacts or location access."), 11, Mu)
        Txt("Black Boost 1.0.0", 11, Mu, modifier = Modifier.fillMaxWidth(), align = TextAlign.Center)
    }
}

@Composable
fun Paywall(vm: Vm, act: Activity) {
    Dialog(onDismissRequest = { vm.paywall = false }, properties = DialogProperties(usePlatformDefaultWidth = false)) {
        Box(Modifier.padding(16.dp)) {
            Column(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(28.dp)).background(Brush.verticalGradient(listOf(Color(0xFF2A1208), Color(0xFF0B0B0B))))
                    .border(1.dp, Color(0xFF5A2C1A), RoundedCornerShape(28.dp)).verticalScroll(rememberScrollState()).padding(22.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                Image(painterResource(R.drawable.ic_crown), null, Modifier.height(90.dp).aspectRatio(828f / 545f))
                Spacer(Modifier.height(10.dp))
                Txt("Premium Boost", 26, disp = true, w = FontWeight.Black, brush = Hot)
                Spacer(Modifier.height(6.dp))
                if (vm.premium) {
                    Txt(t("Premium активирован", "Premium activated"), 16, w = FontWeight.Bold)
                    Txt(t("Все функции открыты. Спасибо!", "All features unlocked. Thank you!"), 13, Mu)
                    Spacer(Modifier.height(20.dp))
                    HotBtn(t("Продолжить", "Continue")) { vm.paywall = false }
                } else {
                    Txt(t("Получи максимум с Premium", "Get the most with Premium"), 15, w = FontWeight.SemiBold)
                    Spacer(Modifier.height(16.dp))
                    Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).background(Color(0xAA0E0E0E)).border(1.dp, Ln, RoundedCornerShape(16.dp)).padding(14.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        Txt(t("Premium включает:", "Premium includes:"), 13, w = FontWeight.Bold)
                        listOf(
                            "Performance Monitor" to t("Нагрузка CPU, GPU и температура в реальном времени.", "CPU and GPU load and temperature in real time."),
                            "Game Mode+" to t("Идеальный режим для запуска игр", "The perfect mode for launching games"),
                            null to t("Разблокировка Максимального режима FPS Boost", "Unlocks Maximum mode in FPS Boost")
                        ).forEach { (h, d) ->
                            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                                Box(Modifier.padding(top = 6.dp).size(8.dp).clip(CircleShape).background(Hot))
                                Column {
                                    if (h != null) Txt(h, 13, w = FontWeight.Bold)
                                    Txt(d, 12, if (h != null) Mu else Tx)
                                }
                            }
                        }
                    }
                    Spacer(Modifier.height(16.dp))
                    Txt(t("Навсегда", "Forever"), 12, Mu)
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                        Txt(vm.billing.price ?: "49 ₽", 38, disp = true, w = FontWeight.Black)
                        Txt("99 ₽", 20, Mu, deco = TextDecoration.LineThrough)
                        Box(Modifier.rotate(-4f).clip(RoundedCornerShape(50)).background(Hot).padding(10.dp, 5.dp)) { Txt("−50%", 13, Ink, FontWeight.ExtraBold) }
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
BB_NEW_8
echo "▶ Коммит..."
git add -A
GN="$(git config user.name || echo BlackBoost)"; GE="$(git config user.email || echo bb@example.com)"
git -c user.name="$GN" -c user.email="$GE" commit -q -m "FPS Boost: games, profiles, Game Mode, honest cleaner" || echo "(нечего коммитить)"
if git remote | grep -q .; then git push -u origin HEAD && echo "✅ Готово. Открой Actions → Build APK → Artifacts"; else echo "⚠ Нет remote: git remote add origin <URL> && git push -u origin HEAD"; fi

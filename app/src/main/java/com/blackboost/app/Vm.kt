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

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

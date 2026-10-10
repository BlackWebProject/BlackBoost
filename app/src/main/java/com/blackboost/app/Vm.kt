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

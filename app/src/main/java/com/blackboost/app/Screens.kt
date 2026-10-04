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
                trail = { Tog(vm.gameMode) { on -> vm.setGameMode(on); if (on && !vm.dndOk) Sys.dnd(ctx) } })
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
    val perm = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { ok -> vm.setNotif(ok) }
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
            Tabs(listOf("Русский", "English"), if (vm.lang == "en") 1 else 0) { vm.setLang(if (it == 1) "en" else "ru") }
        }
        Item(Ic.bell, t("Уведомления", "Notifications"), t("Включить оповещения", "Turn on alerts"), trail = {
            Tog(vm.notif) { on ->
                if (on && Build.VERSION.SDK_INT >= 33 && ContextCompat.checkSelfPermission(ctx, Manifest.permission.POST_NOTIFICATIONS) != android.content.pm.PackageManager.PERMISSION_GRANTED)
                    perm.launch(Manifest.permission.POST_NOTIFICATIONS)
                else vm.setNotif(on)
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

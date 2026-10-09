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
        Item(Ic.bell, t("Уведомления", "Notifications"), t("Напоминания: мало места, перегрев", "Reminders: low storage, overheating"), trail = {
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


@Composable
fun tips(vm: Vm): List<String> {
    val l = ArrayList<String>()
    if (vm.bat.tempC >= 42f) l.add(t("Телефон нагрет: закройте тяжёлые приложения, снимите чехол, не заряжайте во время игры.", "Phone is hot: close heavy apps, remove the case, avoid charging while gaming."))
    if (vm.ramFree * 100 / vm.ramTotal < 15) l.add(t("Мало свободной ОЗУ: закройте приложения, которыми не пользуетесь.", "Low free RAM: close apps you are not using."))
    if (vm.stFree * 100 / vm.stTotal < 15) l.add(t("Мало места: выполните глубокое сканирование на вкладке «Очистка».", "Low storage: run a deep scan on the Cleaner tab."))
    if (!vm.saver && vm.bat.pct < 30) l.add(t("Заряд ниже 30%: включите энергосбережение Android.", "Battery below 30%: turn on Android power saving."))
    l.add(t("Уменьшите яркость и включите автояркость.", "Lower the brightness and enable auto-brightness."))
    l.add(t("Если важна экономия, выберите частоту экрана 60 Гц вместо 120 Гц.", "If saving matters, choose a 60 Hz refresh rate instead of 120 Hz."))
    return l
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
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Tile(Ic.trash, t("Очистка", "Cleaner"), junk?.sz() ?: t("Сканировать", "Scan")) { vm.go(Screen.Clean, true) }
            Tile(Ic.battery, t("Батарея", "Battery"), "${vm.bat.pct}%") { vm.go(Screen.Battery, true) }
        }
        Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
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
        if (tab == 2 && !vm.usageOk) Txt(t("Поиск неиспользуемых приложений работает только с доступом к статистике.", "Finding unused apps works only with usage access."), 12, Mu)
        if (tab == 2 && vm.usageOk) Txt(t("Не запускались больше 30 дней.", "Not opened for more than 30 days."), 12, Mu)
        if (vm.appsLoading && vm.apps.isEmpty()) Txt(t("Загрузка...", "Loading..."), 13, Mu)
        list.forEach { a ->
            Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).card(16).clickable { sel = a }.padding(12.dp, 10.dp),
                verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                a.icon?.let { Image(it, null, Modifier.size(40.dp)) }
                Column(Modifier.weight(1f)) {
                    Txt(a.label, 15, w = FontWeight.SemiBold)
                    if (vm.usageOk) Txt(a.bytes.sz() + " · " + t("кэш ", "cache ") + a.cache.sz(), 12, Mu)
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
    LaunchedEffect(vm.premium) { while (vm.premium) { vm.pollMon(); delay(1000) } }
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
            if (i == 2 && !vm.premium) vm.paywall = true else vm.changeGMode(i)
        }
        if (!vm.premium) Txt(t("Максимальный режим и Game Mode+ доступны в Premium", "Maximum mode and Game Mode+ require Premium"), 11, Mu, modifier = Modifier.fillMaxWidth(), align = TextAlign.Center)
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
        if (vm.premium) {
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

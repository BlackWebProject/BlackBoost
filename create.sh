#!/usr/bin/env bash
# Black Boost: создает Android-проект и workflow GitHub Actions для сборки APK.
# Запуск в Codespaces из корня репозитория: bash create.sh
set -euo pipefail
cd "$(dirname "$0")"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Ошибка: откройте корень уже существующего GitHub-репозитория в Codespaces." >&2
  exit 1
fi

echo "Создаю проект Black Boost..."
cat > 'README.md' <<'BB_EOF_1'
# Black Boost — Android (Kotlin + Jetpack Compose)

Нативное приложение в дизайне Black Boost: загрузочный экран с логотипом, очистка, батарея,
приложения, хранилище, FPS Boost, Premium (корона), язык RU/EN, уведомления.

## Как собрать
1. Установите Android Studio (Koala или новее) и откройте папку проекта.
2. Дождитесь Gradle Sync (скачает Gradle 8.7, AGP 8.5.2, Kotlin 1.9.24).
3. Запустите на телефоне (Android 8.0+, API 26).
   GitHub Actions соберёт APK после отправки изменений в GitHub.

## Что работает по-настоящему
| Функция | Как сделано |
|---|---|
| Оценка оптимизации | Считается из свободной ОЗУ, свободного места, найденного мусора и температуры батареи |
| Ускорить сейчас | `killBackgroundProcesses()` для всех приложений с лаунчером, измеряется реальный прирост свободной ОЗУ |
| Очистка | Кэш Black Boost, временные файлы (tmp/log/bak), APK-установщики, дубликаты (SHA-1), `.trashed-*`/`.thumbnails` |
| Батарея | Уровень, температура, оценка времени (BatteryManager), реальное состояние режима энергосбережения, переходы в системные настройки |
| Приложения | Размер и кэш (нужен «Доступ к статистике использования»), давность запуска, переход в «О приложении» для очистки кэша, остановка, удаление |
| Хранилище | StatFs + StorageStatsManager + MediaStore |
| FPS Boost | Очистка ОЗУ и мусора, режим стабильной производительности, максимальная частота экрана для окна приложения, запуск игры после очистки ОЗУ. FPS замеряется реально до и после |
| Premium: Game Mode+ | Включает «Не беспокоить» на время игры, запущенной из приложения; режим восстанавливается при возврате |
| Premium: Performance Monitor | Частота CPU/GPU, температура батареи, загрузка ОЗУ — раз в секунду |
| Premium: покупка | Google Play Billing, разовая покупка `premium_forever` |
| Уведомления | WorkManager раз в 6 часов: мало места (<15%) и перегрев батареи |

## Ограничения Android (честно)
* Android не даёт обычному приложению очищать кэш чужих приложений и «разгонять FPS» в играх. Поэтому очистка кэша других приложений идёт через системный экран, а FPS показывается замеренный, а не обещанный.
* Загрузка CPU/GPU читается из /sys. Многие телефоны это запрещают, тогда в мониторе будет «—».
* iPhone: такое приложение на iOS невозможно.

## Premium в Google Play
1. Play Console → Монетизация → Товары в приложении → создайте товар **premium_forever**, цена 49 ₽.
2. Старая цена 99 ₽ и скидка −50% в окне — только оформление, реальную цену берёт Google Play.
3. В debug-сборке, если Play Billing недоступен, кнопка «Оплатить» выдаёт Premium для теста.

## Перед публикацией в Google Play
* `MANAGE_EXTERNAL_STORAGE` (доступ ко всем файлам) Google разрешает не для всех приложений. Для публикации заполняется декларация, либо замените поиск мусора на MediaStore/SAF.
* `PACKAGE_USAGE_STATS` и `KILL_BACKGROUND_PROCESSES` требуют объяснения в политике конфиденциальности.
* Не обещайте в описании «ускорение FPS» и «+N FPS»: магазины блокируют такие утверждения.
* Нужна политика конфиденциальности (приложение читает список приложений и статистику).

## Структура
`Vm.kt` — состояние и логика · `Sys.kt` — системные данные · `Cleaner.kt` — поиск и удаление мусора ·
`Billing.kt` — покупки · `Notify.kt` — уведомления · `UI.kt` — компоненты · `Screens.kt` — экраны.
Логотип и корона — векторные drawable (`res/drawable`), иконка приложения — adaptive icon.
BB_EOF_1
mkdir -p "$(dirname 'app/build.gradle.kts')"
cat > 'app/build.gradle.kts' <<'BB_EOF_2'
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
    buildTypes {
        debug { applicationIdSuffix = ".debug" }
        release { isMinifyEnabled = false }
    }
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
BB_EOF_2
mkdir -p "$(dirname 'app/src/main/res/font')"
mkdir -p 'app/src/main/res/font'
curl --fail --location --silent --show-error 'https://raw.githubusercontent.com/google/fonts/main/ofl/unbounded/Unbounded%5Bwght%5D.ttf' -o 'app/src/main/res/font/unbounded.ttf'
curl --fail --location --silent --show-error 'https://raw.githubusercontent.com/google/fonts/main/ofl/manrope/Manrope%5Bwght%5D.ttf' -o 'app/src/main/res/font/manrope.ttf'
mkdir -p "$(dirname 'app/proguard-rules.pro')"
cat > 'app/proguard-rules.pro' <<'BB_EOF_3'

BB_EOF_3
mkdir -p "$(dirname 'app/src/main/AndroidManifest.xml')"
cat > 'app/src/main/AndroidManifest.xml' <<'BB_EOF_4'
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
BB_EOF_4
mkdir -p "$(dirname 'app/src/main/java/com/blackboost/app/Billing.kt')"
cat > 'app/src/main/java/com/blackboost/app/Billing.kt' <<'BB_EOF_5'
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
BB_EOF_5
mkdir -p "$(dirname 'app/src/main/java/com/blackboost/app/Cleaner.kt')"
cat > 'app/src/main/java/com/blackboost/app/Cleaner.kt' <<'BB_EOF_6'
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
        val tmp = ArrayList<File>(); val sys = ArrayList<File>(); val big = ArrayList<File>()
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
                        // APK installers are never auto-classified as junk or deleted.
                        ext == "apk" -> Unit
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
            j("left", "Остаточные файлы", "Leftover files", emptyList()),
            j("dup", "Дубликаты файлов", "Duplicate files", dup),
            j("sys", "Системный мусор", "System junk", sys)
        )
    }

    suspend fun clean(items: List<Junk>, progress: (Float) -> Unit): Long = withContext(Dispatchers.IO) {
        val all = items.flatMap { it.files }.distinctBy { it.canonicalPath }
        var freed = 0L
        all.forEachIndexed { i, f ->
            val l = f.length()
            if (f.isFile && !f.name.endsWith(".apk", ignoreCase = true) && f.delete()) freed += l
            if (i % 20 == 0) progress((i + 1f) / all.size)
        }
        progress(1f)
        freed
    }
}
BB_EOF_6
mkdir -p "$(dirname 'app/src/main/java/com/blackboost/app/MainActivity.kt')"
cat > 'app/src/main/java/com/blackboost/app/MainActivity.kt' <<'BB_EOF_7'
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
BB_EOF_7
mkdir -p "$(dirname 'app/src/main/java/com/blackboost/app/Notify.kt')"
cat > 'app/src/main/java/com/blackboost/app/Notify.kt' <<'BB_EOF_8'
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
BB_EOF_8
mkdir -p "$(dirname 'app/src/main/java/com/blackboost/app/Prefs.kt')"
cat > 'app/src/main/java/com/blackboost/app/Prefs.kt' <<'BB_EOF_9'
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
BB_EOF_9
mkdir -p "$(dirname 'app/src/main/java/com/blackboost/app/Screens.kt')"
cat > 'app/src/main/java/com/blackboost/app/Screens.kt' <<'BB_EOF_10'
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
BB_EOF_10
mkdir -p "$(dirname 'app/src/main/java/com/blackboost/app/Sys.kt')"
cat > 'app/src/main/java/com/blackboost/app/Sys.kt' <<'BB_EOF_11'
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
BB_EOF_11
mkdir -p "$(dirname 'app/src/main/java/com/blackboost/app/UI.kt')"
cat > 'app/src/main/java/com/blackboost/app/UI.kt' <<'BB_EOF_12'
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
import androidx.compose.ui.text.ExperimentalTextApi
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
    pathData = androidx.compose.ui.graphics.vector.PathParser().parsePathString(d).toNodes(), stroke = SolidColor(Color.White), strokeLineWidth = 1.8f,
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
BB_EOF_12
mkdir -p "$(dirname 'app/src/main/java/com/blackboost/app/Vm.kt')"
cat > 'app/src/main/java/com/blackboost/app/Vm.kt' <<'BB_EOF_13'
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
    fun setLang(l: String) { lang = l; prefs.lang = l }
    fun setNotif(on: Boolean) { notif = on; prefs.notif = on; Notify.schedule(c, on) }
    fun setGameMode(on: Boolean) { gameMode = on; prefs.gameMode = on }

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
BB_EOF_13
mkdir -p "$(dirname 'app/src/main/res/drawable/ic_crown.xml')"
cat > 'app/src/main/res/drawable/ic_crown.xml' <<'BB_EOF_14'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" xmlns:aapt="http://schemas.android.com/aapt" android:width="96dp" android:height="63dp" android:viewportWidth="828" android:viewportHeight="545"><path android:fillType="evenOdd" android:pathData="M118.2,539.3C112.4,536.4 109.8,531.3 105.5,514.0C104.1,508.2 102.0,500.6 100.9,497.1C96.3,481.9 99.7,477.8 121.0,473.1C124.0,472.4 133.7,470.1 142.5,468.0C243.2,443.6 353.2,430.2 433.0,432.6C437.7,432.8 451.2,433.1 463.0,433.4C536.0,435.4 626.1,449.8 705.5,472.3C728.0,478.7 728.6,479.3 724.7,492.1C708.8,545.4 713.1,542.3 666.3,534.6C651.6,532.1 634.1,529.4 627.5,528.6C596.6,524.6 590.3,523.8 572.5,522.0C473.4,512.0 341.4,512.6 246.0,523.5C209.8,527.7 196.9,529.5 155.8,536.5C126.3,541.5 123.0,541.7 118.2,539.3ZM91.3,455.6C88.9,453.8 86.6,447.2 79.1,421.5C76.4,412.1 71.4,394.8 68.0,383.0C64.6,371.2 58.5,350.2 54.5,336.5C50.4,322.8 43.7,299.8 39.5,285.5C35.3,271.2 29.4,251.2 26.3,241.0C16.9,209.4 7.8,177.8 5.9,170.0C0.6,148.8 5.4,149.5 72.8,179.7C80.9,183.3 89.5,187.1 92.0,188.2C128.9,204.5 207.7,241.3 209.5,243.1C212.1,245.6 210.7,247.0 201.5,250.8C197.7,252.4 185.7,257.4 175.0,262.0C164.3,266.5 152.3,271.5 148.5,273.0C137.9,277.3 132.1,280.0 131.5,280.9C130.9,282.0 142.0,292.1 195.0,339.2C215.7,357.5 240.6,379.7 250.4,388.5C260.2,397.3 270.3,406.2 272.8,408.3C287.0,419.8 286.4,420.8 264.0,424.0C220.7,430.3 179.2,438.2 134.6,448.6C98.0,457.2 94.4,457.8 91.3,455.6ZM719.5,453.4C713.5,451.7 680.7,443.7 666.0,440.3C650.4,436.8 639.0,434.5 614.0,430.0C576.4,423.3 566.1,421.6 556.0,420.4C543.5,419.0 544.8,416.8 573.5,391.4C592.6,374.5 608.3,360.7 628.0,343.5C667.6,308.8 697.5,281.8 697.8,280.6C698.2,278.8 696.3,278.0 646.4,257.9C612.0,244.1 612.0,244.1 633.0,234.5C639.9,231.3 649.8,226.8 655.0,224.3C660.2,221.8 667.9,218.3 672.0,216.5C676.1,214.7 685.1,210.6 692.0,207.5C698.9,204.4 707.4,200.5 711.0,199.0C714.6,197.5 723.1,193.6 730.0,190.5C743.8,184.3 766.8,174.1 783.0,167.3C814.3,153.9 817.7,152.9 821.6,155.5C826.2,158.5 824.5,166.1 805.0,230.0C801.1,242.9 794.8,263.6 791.0,276.0C787.3,288.4 779.0,315.6 772.7,336.5C736.6,455.5 738.3,450.2 735.2,452.7C732.0,455.4 727.1,455.6 719.5,453.4ZM287.8,394.3C286.9,393.3 285.5,390.0 284.7,387.0C283.2,381.5 280.4,372.0 267.2,326.5C253.6,279.6 249.0,262.0 249.0,256.3C249.1,249.0 252.3,243.6 299.9,171.5C341.9,107.8 401.2,18.7 405.6,12.7C415.6,-1.0 419.8,1.2 437.0,28.7C442.2,37.1 460.1,65.0 473.8,86.0C479.0,94.0 485.7,104.3 488.7,109.0C491.7,113.7 498.8,124.5 504.4,133.1C509.9,141.7 517.1,152.7 520.2,157.6C523.3,162.5 530.7,173.9 536.6,183.0C574.3,241.3 579.0,249.3 579.0,256.3C579.0,263.4 572.3,287.1 554.5,343.5C551.1,354.5 546.5,369.1 544.5,376.0C536.7,401.9 535.4,402.1 522.6,379.0C499.7,337.7 468.9,281.0 450.7,247.0C444.1,234.6 435.3,218.2 431.2,210.5C427.1,202.8 421.9,193.0 419.7,188.8C417.5,184.5 415.1,181.0 414.5,181.0C413.3,181.0 409.7,187.0 400.0,205.0C388.7,226.1 380.7,240.5 380.0,241.5C379.6,242.1 375.2,249.9 370.3,259.0C357.5,282.4 338.0,317.7 327.0,337.0C321.9,346.1 315.5,357.6 312.7,362.5C294.6,394.9 291.7,398.6 287.8,394.3Z"><aapt:attr name="android:fillColor"><gradient android:startX="0" android:startY="0" android:endX="828" android:endY="545" android:type="linear"><item android:offset="0" android:color="#FFFFEE00"/><item android:offset="0.5" android:color="#FFFF7A00"/><item android:offset="1" android:color="#FFF00014"/></gradient></aapt:attr></path></vector>
BB_EOF_14
mkdir -p "$(dirname 'app/src/main/res/drawable/ic_launcher_foreground.xml')"
cat > 'app/src/main/res/drawable/ic_launcher_foreground.xml' <<'BB_EOF_15'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" xmlns:aapt="http://schemas.android.com/aapt" android:width="108dp" android:height="108dp" android:viewportWidth="108" android:viewportHeight="108"><group android:scaleX="0.08176" android:scaleY="0.08176" android:translateX="28.0" android:translateY="29.35"><path android:fillType="evenOdd" android:pathData="M5.2,597.4C4.6,596.3 5.2,592.6 7.2,586.1C11.9,570.6 50.7,450.7 58.5,427.5C60.9,420.4 70.8,390.2 80.5,360.5C102.2,294.2 123.9,228.0 142.0,173.0C149.7,149.7 175.6,70.4 180.2,56.0C185.0,41.1 191.0,26.2 192.5,25.6C194.9,24.7 213.3,23.0 242.5,21.0C278.6,18.5 319.4,15.5 345.5,13.5C519.1,0.2 540.0,0.7 576.0,19.1C640.3,52.0 650.5,139.2 597.7,205.8C582.8,224.6 559.3,245.1 539.8,256.4C533.7,259.8 533.8,260.4 540.2,262.6C592.9,279.7 624.0,322.7 621.7,374.9C618.6,443.9 571.3,507.4 498.0,541.0C453.9,561.2 415.2,569.0 327.0,575.5C315.7,576.3 291.2,578.1 272.5,579.5C253.8,580.9 226.6,582.9 212.0,584.0C183.2,586.2 163.4,587.7 112.0,591.5C93.6,592.9 72.2,594.4 64.5,595.0C51.1,596.0 8.3,599.0 6.8,599.0C6.4,599.0 5.7,598.3 5.2,597.4ZM137.1,530.2C143.0,525.4 155.8,514.8 165.6,506.5C218.0,462.3 210.9,466.7 232.0,465.1C308.1,459.3 375.4,453.8 380.8,453.0C398.2,450.3 409.9,438.8 419.0,415.5C421.2,409.8 423.0,404.6 423.0,403.9C423.0,402.6 410.1,403.0 372.0,405.5C360.2,406.3 342.6,407.4 333.0,408.0C323.4,408.6 310.6,409.5 304.5,410.1C287.6,411.5 280.0,411.3 280.0,409.5C280.0,407.2 313.6,371.4 405.1,275.8C448.8,230.2 451.6,227.2 450.6,226.3C450.0,225.7 434.2,226.3 370.8,229.2C356.1,229.8 343.7,230.1 343.3,229.7C342.0,228.3 345.2,219.9 364.0,175.5C379.3,139.4 382.4,132.0 388.7,116.5C399.6,89.7 402.8,81.5 402.5,81.1C402.0,80.6 379.7,96.7 373.2,102.2C343.5,127.7 317.0,153.1 260.6,210.1C206.1,265.1 171.8,301.2 172.8,302.2C173.2,302.6 188.7,302.1 207.1,301.1C266.9,297.6 267.9,297.6 268.6,299.4C269.1,300.8 263.7,310.3 243.8,342.5C239.7,349.1 223.8,374.8 208.5,399.5C177.1,450.2 163.3,472.7 158.3,481.5C156.4,484.8 153.2,490.2 151.1,493.5C147.5,499.2 145.0,503.4 131.7,526.1C122.3,542.0 122.5,542.2 137.1,530.2Z"><aapt:attr name="android:fillColor"><gradient android:startX="0" android:startY="0" android:endX="636" android:endY="603" android:type="linear"><item android:offset="0" android:color="#FFFFEE00"/><item android:offset="0.5" android:color="#FFFF7A00"/><item android:offset="1" android:color="#FFF00014"/></gradient></aapt:attr></path></group></vector>
BB_EOF_15
mkdir -p "$(dirname 'app/src/main/res/drawable/ic_logo.xml')"
cat > 'app/src/main/res/drawable/ic_logo.xml' <<'BB_EOF_16'
<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android" xmlns:aapt="http://schemas.android.com/aapt" android:width="64dp" android:height="61dp" android:viewportWidth="636" android:viewportHeight="603"><path android:fillType="evenOdd" android:pathData="M5.2,597.4C4.6,596.3 5.2,592.6 7.2,586.1C11.9,570.6 50.7,450.7 58.5,427.5C60.9,420.4 70.8,390.2 80.5,360.5C102.2,294.2 123.9,228.0 142.0,173.0C149.7,149.7 175.6,70.4 180.2,56.0C185.0,41.1 191.0,26.2 192.5,25.6C194.9,24.7 213.3,23.0 242.5,21.0C278.6,18.5 319.4,15.5 345.5,13.5C519.1,0.2 540.0,0.7 576.0,19.1C640.3,52.0 650.5,139.2 597.7,205.8C582.8,224.6 559.3,245.1 539.8,256.4C533.7,259.8 533.8,260.4 540.2,262.6C592.9,279.7 624.0,322.7 621.7,374.9C618.6,443.9 571.3,507.4 498.0,541.0C453.9,561.2 415.2,569.0 327.0,575.5C315.7,576.3 291.2,578.1 272.5,579.5C253.8,580.9 226.6,582.9 212.0,584.0C183.2,586.2 163.4,587.7 112.0,591.5C93.6,592.9 72.2,594.4 64.5,595.0C51.1,596.0 8.3,599.0 6.8,599.0C6.4,599.0 5.7,598.3 5.2,597.4ZM137.1,530.2C143.0,525.4 155.8,514.8 165.6,506.5C218.0,462.3 210.9,466.7 232.0,465.1C308.1,459.3 375.4,453.8 380.8,453.0C398.2,450.3 409.9,438.8 419.0,415.5C421.2,409.8 423.0,404.6 423.0,403.9C423.0,402.6 410.1,403.0 372.0,405.5C360.2,406.3 342.6,407.4 333.0,408.0C323.4,408.6 310.6,409.5 304.5,410.1C287.6,411.5 280.0,411.3 280.0,409.5C280.0,407.2 313.6,371.4 405.1,275.8C448.8,230.2 451.6,227.2 450.6,226.3C450.0,225.7 434.2,226.3 370.8,229.2C356.1,229.8 343.7,230.1 343.3,229.7C342.0,228.3 345.2,219.9 364.0,175.5C379.3,139.4 382.4,132.0 388.7,116.5C399.6,89.7 402.8,81.5 402.5,81.1C402.0,80.6 379.7,96.7 373.2,102.2C343.5,127.7 317.0,153.1 260.6,210.1C206.1,265.1 171.8,301.2 172.8,302.2C173.2,302.6 188.7,302.1 207.1,301.1C266.9,297.6 267.9,297.6 268.6,299.4C269.1,300.8 263.7,310.3 243.8,342.5C239.7,349.1 223.8,374.8 208.5,399.5C177.1,450.2 163.3,472.7 158.3,481.5C156.4,484.8 153.2,490.2 151.1,493.5C147.5,499.2 145.0,503.4 131.7,526.1C122.3,542.0 122.5,542.2 137.1,530.2Z"><aapt:attr name="android:fillColor"><gradient android:startX="0" android:startY="0" android:endX="636" android:endY="603" android:type="linear"><item android:offset="0" android:color="#FFFFEE00"/><item android:offset="0.5" android:color="#FFFF7A00"/><item android:offset="1" android:color="#FFF00014"/></gradient></aapt:attr></path></vector>
BB_EOF_16
mkdir -p "$(dirname 'app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml')"
cat > 'app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml' <<'BB_EOF_17'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
BB_EOF_17
mkdir -p "$(dirname 'app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml')"
cat > 'app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml' <<'BB_EOF_18'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
BB_EOF_18
mkdir -p "$(dirname 'app/src/main/res/values/colors.xml')"
cat > 'app/src/main/res/values/colors.xml' <<'BB_EOF_19'
<resources>
    <color name="bb_bg">#FF050505</color>
    <color name="ic_launcher_background">#FF050505</color>
</resources>
BB_EOF_19
mkdir -p "$(dirname 'app/src/main/res/values/strings.xml')"
cat > 'app/src/main/res/values/strings.xml' <<'BB_EOF_20'
<resources>
    <string name="app_name">Black Boost</string>
</resources>
BB_EOF_20
mkdir -p "$(dirname 'app/src/main/res/values/themes.xml')"
cat > 'app/src/main/res/values/themes.xml' <<'BB_EOF_21'
<resources>
    <style name="Theme.BlackBoost" parent="android:Theme.Material.NoActionBar">
        <item name="android:windowBackground">@color/bb_bg</item>
        <item name="android:statusBarColor">@color/bb_bg</item>
        <item name="android:navigationBarColor">@color/bb_bg</item>
    </style>
</resources>
BB_EOF_21
mkdir -p "$(dirname 'build.gradle.kts')"
cat > 'build.gradle.kts' <<'BB_EOF_22'
plugins {
    id("com.android.application") version "8.5.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
}
BB_EOF_22
mkdir -p "$(dirname 'gradle.properties')"
cat > 'gradle.properties' <<'BB_EOF_23'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.nonTransitiveRClass=true
kotlin.code.style=official
BB_EOF_23
mkdir -p "$(dirname 'gradle/wrapper/gradle-wrapper.properties')"
cat > 'gradle/wrapper/gradle-wrapper.properties' <<'BB_EOF_24'
distributionBase=GRADLE_USER_HOME
distributionPath=wrapper/dists
distributionUrl=https\://services.gradle.org/distributions/gradle-8.7-bin.zip
zipStoreBase=GRADLE_USER_HOME
zipStorePath=wrapper/dists
BB_EOF_24
cat > 'gradlew' <<'BB_EOF_24B'
#!/usr/bin/env sh
set -eu
exec gradle "$@"
BB_EOF_24B
chmod +x gradlew
mkdir -p "$(dirname 'settings.gradle.kts')"
cat > 'settings.gradle.kts' <<'BB_EOF_25'
pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement { repositories { google(); mavenCentral() } }
rootProject.name = "BlackBoost"
include(":app")
BB_EOF_25
mkdir -p "$(dirname '.github/workflows/build.yml')"
cat > '.github/workflows/build.yml' <<'BB_EOF_26'
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
      - name: Build debug APK
        run: ./gradlew :app:assembleDebug --no-daemon --stacktrace
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: black-boost-debug-apk
          path: app/build/outputs/apk/debug/*.apk
          if-no-files-found: error
BB_EOF_26
mkdir -p "$(dirname '.gitignore')"
cat > '.gitignore' <<'BB_EOF_27'
build/
.gradle/
.idea/
local.properties
*.iml
BB_EOF_27
echo "Готово: файлы проекта созданы. Проверьте изменения, затем выполните git add, commit и push в GitHub."
echo "APK появится в Actions → Build APK → Artifacts → black-boost-debug-apk."


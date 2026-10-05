#!/usr/bin/env bash
# Black Boost: создает Android-приложение менеджера игровых профилей и сборку APK через GitHub Actions.
# Запуск из корня репозитория Codespaces: bash create2.sh
set -euo pipefail
cd "$(dirname "$0")"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Откройте корень GitHub-репозитория в Codespaces и поместите туда create2.sh." >&2
  exit 1
fi

mkdir -p app/src/main/java/com/blackboost/app app/src/main/res/values .github/workflows

cat > settings.gradle.kts <<'EOF_SETTINGS'
pluginManagement { repositories { google(); mavenCentral(); gradlePluginPortal() } }
dependencyResolutionManagement { repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS); repositories { google(); mavenCentral() } }
rootProject.name = "BlackBoost"
include(":app")
EOF_SETTINGS

cat > build.gradle.kts <<'EOF_ROOT_BUILD'
plugins {
    id("com.android.application") version "8.5.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.24" apply false
}
EOF_ROOT_BUILD

cat > gradle.properties <<'EOF_GRADLE_PROPERTIES'
org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=true
android.nonTransitiveRClass=true
kotlin.code.style=official
EOF_GRADLE_PROPERTIES

cat > app/build.gradle.kts <<'EOF_APP_BUILD'
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
        versionCode = 2
        versionName = "2.0.0"
    }
    buildTypes {
        debug { applicationIdSuffix = ".debug" }
        release { isMinifyEnabled = false }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
    buildFeatures { compose = true }
    composeOptions { kotlinCompilerExtensionVersion = "1.5.14" }
}

dependencies {
    implementation(platform("androidx.compose:compose-bom:2024.06.00"))
    implementation("androidx.activity:activity-compose:1.9.0")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.3")
}
EOF_APP_BUILD

cat > app/src/main/AndroidManifest.xml <<'EOF_MANIFEST'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <queries>
        <intent>
            <action android:name="android.intent.action.MAIN" />
            <category android:name="android.intent.category.LAUNCHER" />
        </intent>
    </queries>
    <application
        android:allowBackup="false"
        android:label="Black Boost"
        android:theme="@style/Theme.BlackBoost">
        <activity
            android:name=".MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF_MANIFEST

cat > app/src/main/res/values/styles.xml <<'EOF_STYLES'
<resources>
    <style name="Theme.BlackBoost" parent="android:style/Theme.Material.Light.NoActionBar">
        <item name="android:fontFamily">sans</item>
        <item name="android:colorAccent">#FF6A24</item>
        <item name="android:statusBarColor">#090909</item>
        <item name="android:navigationBarColor">#090909</item>
        <item name="android:windowLightStatusBar">false</item>
        <item name="android:windowActionModeOverlay">true</item>
    </style>
</resources>
EOF_STYLES

cat > app/src/main/java/com/blackboost/app/MainActivity.kt <<'EOF_ACTIVITY'
package com.blackboost.app

import android.app.ActivityManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Bundle
import android.os.StatFs
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import java.io.File
import java.util.Locale

private val Background = Color(0xFF090909)
private val Panel = Color(0xFF171717)
private val Orange = Color(0xFFFF6A24)
private val MainText = Color(0xFFF5F1EC)
private val Muted = Color(0xFFAAA39C)

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                Surface(modifier = Modifier.fillMaxSize(), color = Background) {
                    BlackBoostApp()
                }
            }
        }
    }
}

private data class Game(val name: String, val packageName: String, val icon: android.graphics.drawable.Drawable?)
private enum class PowerProfile { SAVE, BALANCED, PERFORMANCE }

@Composable
private fun BlackBoostApp() {
    val context = LocalContext.current
    val prefs = remember { context.getSharedPreferences("black_boost_profiles", Context.MODE_PRIVATE) }
    var games by remember { mutableStateOf(loadGames(context)) }
    var selected by remember { mutableStateOf<Game?>(null) }
    var showPicker by remember { mutableStateOf(false) }
    var power by remember { mutableStateOf(runCatching { PowerProfile.valueOf(prefs.getString("power", "BALANCED") ?: "BALANCED") }.getOrDefault(PowerProfile.BALANCED)) }
    var status by remember { mutableStateOf("Готово к игре") }
    var lastSession by remember { mutableStateOf("") }

    val mem = remember { readMemory(context) }
    val storage = remember { readStorage() }
    val batteryTemp = remember { readBatteryTemp(context) }
    val profileKey = selected?.packageName?.let { "game_$it" }
    var boostEnabled by remember(selected) { mutableStateOf(profileKey?.let { prefs.getBoolean("${it}_boost", true) } ?: true) }
    var gameMode by remember(selected) { mutableStateOf(profileKey?.let { prefs.getBoolean("${it}_mode", true) } ?: true) }
    var cleanupBeforeLaunch by remember(selected) { mutableStateOf(profileKey?.let { prefs.getBoolean("${it}_clean", true) } ?: true) }

    fun saveGameProfile() {
        val key = profileKey ?: return
        prefs.edit().putBoolean("${key}_boost", boostEnabled)
            .putBoolean("${key}_mode", gameMode)
            .putBoolean("${key}_clean", cleanupBeforeLaunch).apply()
    }

    fun launchSelectedGame() {
        val game = selected ?: run { showPicker = true; return }
        saveGameProfile()
        status = "Профиль проверен · запускаем ${game.name}"
        if (cleanupBeforeLaunch) clearOwnCache(context.cacheDir)
        val launch = context.packageManager.getLaunchIntentForPackage(game.packageName)
        if (launch == null) {
            status = "Не удалось открыть игру. Проверьте, что она установлена."
        } else {
            lastSession = "Последний запуск: ${game.name} · профиль ${powerLabel(power)}"
            status = "Игра запущена. Black Boost не работает в фоне."
            context.startActivity(launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        }
    }

    Column(
        modifier = Modifier.fillMaxSize().background(Background).verticalScroll(rememberScrollState()).padding(horizontal = 20.dp, vertical = 18.dp),
        verticalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(42.dp).background(Orange, CircleShape), contentAlignment = Alignment.Center) {
                Text("B", color = Background, fontWeight = FontWeight.Black, fontSize = 24.sp)
            }
            Column(Modifier.weight(1f).padding(start = 12.dp)) {
                Text("BLACK BOOST", color = MainText, fontSize = 19.sp, fontWeight = FontWeight.Black)
                Text("Менеджер игровых профилей", color = Muted, fontSize = 12.sp)
            }
        }

        Card(colors = CardDefaults.cardColors(containerColor = Panel), shape = RoundedCornerShape(20.dp)) {
            Column(Modifier.fillMaxWidth().padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                Text(status, color = MainText, fontSize = 18.sp, fontWeight = FontWeight.Bold)
                Text("Доступные данные устройства", color = Muted, fontSize = 12.sp)
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                    Stat("Свободная RAM", mem)
                    Stat("Свободное место", storage)
                    Stat("Батарея", batteryTemp)
                }
            }
        }

        Button(
            onClick = { launchSelectedGame() },
            modifier = Modifier.fillMaxWidth().height(56.dp),
            shape = RoundedCornerShape(16.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Orange, contentColor = Background)
        ) {
            Text(if (selected == null) "ВЫБРАТЬ ИГРУ" else "ЗАПУСТИТЬ ИГРУ", fontWeight = FontWeight.Black, fontSize = 16.sp)
        }

        TextButton(onClick = {
            val freed = clearOwnCache(context.cacheDir)
            status = if (freed > 0) "Очищен кэш Black Boost · ${freed / 1_000_000} MB" else "Кэш Black Boost уже пуст"
        }) {
            Text("ОЧИСТИТЬ КЭШ BLACK BOOST", color = Orange, fontWeight = FontWeight.Bold)
        }

        Card(colors = CardDefaults.cardColors(containerColor = Panel), shape = RoundedCornerShape(18.dp)) {
            Column(Modifier.fillMaxWidth().padding(14.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text("Профиль питания", color = MainText, fontWeight = FontWeight.Bold)
                PowerProfile.entries.forEach { option ->
                    Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth().clickable {
                        power = option
                        prefs.edit().putString("power", option.name).apply()
                    }) {
                        RadioButton(selected = power == option, onClick = {
                            power = option
                            prefs.edit().putString("power", option.name).apply()
                        })
                        Column {
                            Text(powerLabel(option), color = MainText, fontSize = 14.sp)
                            Text(powerDescription(option), color = Muted, fontSize = 11.sp)
                        }
                    }
                }
            }
        }

        selected?.let { game ->
            Card(colors = CardDefaults.cardColors(containerColor = Panel), shape = RoundedCornerShape(18.dp)) {
                Column(Modifier.fillMaxWidth().padding(14.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text("Профиль: ${game.name}", color = MainText, fontWeight = FontWeight.Bold)
                    ProfileSwitch("FPS Boost", "Без обещаний изменения FPS", boostEnabled) { boostEnabled = it; saveGameProfile() }
                    ProfileSwitch("Game Mode", "Профиль приложения и запуск игры", gameMode) { gameMode = it; saveGameProfile() }
                    ProfileSwitch("Очистка перед запуском", "Только кэш Black Boost", cleanupBeforeLaunch) { cleanupBeforeLaunch = it; saveGameProfile() }
                }
            }
        }

        Row(verticalAlignment = Alignment.CenterVertically) {
            Text("Мои игры", color = MainText, fontWeight = FontWeight.Bold, modifier = Modifier.weight(1f))
            TextButton(onClick = { games = loadGames(context); showPicker = true }) { Text("Добавить игру", color = Orange) }
        }
        if (games.isEmpty()) {
            Text("Добавьте игру из списка установленных приложений.", color = Muted, fontSize = 13.sp)
        } else {
            LazyColumn(verticalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth().height(180.dp)) {
                items(games, key = { it.packageName }) { game ->
                    Card(
                        colors = CardDefaults.cardColors(containerColor = if (selected?.packageName == game.packageName) Color(0xFF302015) else Panel),
                        shape = RoundedCornerShape(14.dp),
                        modifier = Modifier.fillMaxWidth().clickable {
                            selected = game
                            status = "Профиль готов · ${game.name}"
                        }
                    ) {
                        Row(Modifier.padding(12.dp), verticalAlignment = Alignment.CenterVertically) {
                            Text(game.name, color = MainText, fontWeight = FontWeight.SemiBold, modifier = Modifier.weight(1f))
                            if (selected?.packageName == game.packageName) Text("ВЫБРАНА", color = Orange, fontSize = 10.sp)
                        }
                    }
                }
            }
        }
        if (lastSession.isNotBlank()) Text(lastSession, color = Muted, fontSize = 11.sp)
        Text("Используются только доступные Android данные. Системные настройки телефона приложение не меняет.", color = Muted, fontSize = 10.sp)
    }

    if (showPicker) {
        val candidates = remember(games) { loadGames(context).filterNot { candidate -> games.any { it.packageName == candidate.packageName } } }
        AlertDialog(
            onDismissRequest = { showPicker = false },
            containerColor = Panel,
            title = { Text("Добавить игру", color = MainText) },
            text = {
                if (candidates.isEmpty()) Text("Других приложений с иконкой запуска не найдено.", color = Muted)
                else LazyColumn { items(candidates, key = { it.packageName }) { game ->
                    Text(game.name, color = MainText, modifier = Modifier.fillMaxWidth().clickable {
                        games = games + game
                        selected = game
                        status = "Профиль готов · ${game.name}"
                        showPicker = false
                    }.padding(vertical = 12.dp))
                } }
            },
            confirmButton = { TextButton(onClick = { showPicker = false }) { Text("Закрыть", color = Orange) } }
        )
    }
}

@Composable
private fun Stat(title: String, value: String) {
    Column {
        Text(title, color = Muted, fontSize = 10.sp)
        Text(value, color = MainText, fontSize = 13.sp, fontWeight = FontWeight.Bold)
    }
}

@Composable
private fun ProfileSwitch(title: String, detail: String, checked: Boolean, onChange: (Boolean) -> Unit) {
    Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
        Column(Modifier.weight(1f)) {
            Text(title, color = MainText, fontSize = 13.sp)
            Text(detail, color = Muted, fontSize = 10.sp)
        }
        Switch(checked = checked, onCheckedChange = onChange)
    }
}

private fun loadGames(context: Context): List<Game> {
    val launchIntent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
    return context.packageManager.queryIntentActivities(launchIntent, 0)
        .mapNotNull { resolve ->
            val pkg = resolve.activityInfo.packageName
            if (pkg == context.packageName) null else Game(
                name = resolve.loadLabel(context.packageManager).toString(),
                packageName = pkg,
                icon = runCatching { resolve.loadIcon(context.packageManager) }.getOrNull()
            )
        }
        .distinctBy { it.packageName }
        .sortedBy { it.name.lowercase(Locale.getDefault()) }
}

private fun clearOwnCache(cacheDir: File): Long {
    var freed = 0L
    cacheDir.walkBottomUp().filter { it.isFile }.forEach { file ->
        val size = file.length()
        if (file.delete()) freed += size
    }
    return freed
}

private fun readMemory(context: Context): String = runCatching {
    val info = ActivityManager.MemoryInfo()
    context.getSystemService(ActivityManager::class.java).getMemoryInfo(info)
    "${info.availMem / 1_000_000} MB"
}.getOrDefault("Недоступно")

private fun readStorage(): String = runCatching {
    val stat = StatFs(android.os.Environment.getDataDirectory().path)
    "${stat.availableBytes / 1_000_000_000} GB"
}.getOrDefault("Недоступно")

private fun readBatteryTemp(context: Context): String = runCatching {
    val intent = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
    val value = (intent?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, -1) ?: -1) / 10f
    if (value < 0f) "—" else String.format(Locale.getDefault(), "%.1f°C", value)
}.getOrDefault("—")

private fun powerLabel(profile: PowerProfile): String = when (profile) {
    PowerProfile.SAVE -> "Максимальная экономия"
    PowerProfile.BALANCED -> "Баланс"
    PowerProfile.PERFORMANCE -> "Производительность"
}

private fun powerDescription(profile: PowerProfile): String = when (profile) {
    PowerProfile.SAVE -> "Минимум фоновой активности приложения"
    PowerProfile.BALANCED -> "Обычная работа менеджера профилей"
    PowerProfile.PERFORMANCE -> "Не выполнять энергосберегающие действия в игровой сессии"
}
EOF_ACTIVITY

cat > .github/workflows/build.yml <<'EOF_WORKFLOW'
name: Build APK

on:
  push:
  workflow_dispatch:

permissions:
  contents: read

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
        run: gradle :app:assembleDebug --no-daemon --stacktrace
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: black-boost-debug-apk
          path: app/build/outputs/apk/debug/*.apk
          if-no-files-found: error
EOF_WORKFLOW

cat > .gitignore <<'EOF_GITIGNORE'
.gradle/
build/
app/build/
.idea/
local.properties
*.iml
EOF_GITIGNORE

echo "Проект Black Boost 2.0 создан. Скрипт ничего не коммитит и не отправляет в GitHub."
echo "Проверьте изменения, затем: git add . && git commit -m 'Build Black Boost game profiles' && git push"
echo "APK появится в GitHub → Actions → Build APK → Artifacts → black-boost-debug-apk."

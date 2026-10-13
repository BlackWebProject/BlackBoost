#!/usr/bin/env bash
# Release.sh — подписанная release-сборка для RuStore (вместо debug).
# Запуск в Codespaces из корня репозитория:  bash Release.sh
set -e
cd "$(dirname "$0")"
[ -f app/build.gradle.kts ] || { echo "❌ Не найден проект"; exit 1; }
command -v keytool >/dev/null || { echo "❌ Не найден keytool (Java). Установите: sudo apt-get install -y default-jdk-headless"; exit 1; }

echo "▶ Обновляю настройки сборки..."
cat > app/build.gradle.kts <<'EOF_GRADLE'
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
    signingConfigs {
        create("release") {
            val ksPath = System.getenv("KEYSTORE_FILE")
            if (!ksPath.isNullOrEmpty()) {
                storeFile = file(ksPath)
                storePassword = System.getenv("KEYSTORE_PASSWORD")
                keyAlias = System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("KEY_PASSWORD")
            }
        }
    }
    buildTypes {
        release {
            isMinifyEnabled = false
            if (!System.getenv("KEYSTORE_FILE").isNullOrEmpty()) signingConfig = signingConfigs.getByName("release")
        }
    }
    lint { checkReleaseBuilds = false; abortOnError = false }
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
EOF_GRADLE
mkdir -p .github/workflows
cat > .github/workflows/build.yml <<'EOF_WF'
name: Build APK

on:
  push:
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    env:
      KEYSTORE_BASE64: ${{ secrets.KEYSTORE_BASE64 }}
      KEYSTORE_PASSWORD: ${{ secrets.KEYSTORE_PASSWORD }}
      KEY_ALIAS: ${{ secrets.KEY_ALIAS }}
      KEY_PASSWORD: ${{ secrets.KEY_PASSWORD }}
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
      - name: Prepare release keystore
        if: env.KEYSTORE_BASE64 != ''
        run: |
          echo "$KEYSTORE_BASE64" | base64 -d > "$RUNNER_TEMP/release.jks"
          echo "KEYSTORE_FILE=$RUNNER_TEMP/release.jks" >> "$GITHUB_ENV"
      - name: Build release APK
        if: env.KEYSTORE_BASE64 != ''
        run: gradle :app:assembleRelease --no-daemon --console=plain > release.log 2>&1
      - name: Show errors
        if: failure()
        run: |
          grep -E "^e: |error:|What went wrong|Execution failed|Manifest merger|AAPT" -A4 build.log release.log 2>/dev/null | head -70 || true
      - name: Upload debug APK
        uses: actions/upload-artifact@v4
        with:
          name: black-boost-debug-apk
          path: app/build/outputs/apk/debug/*.apk
          if-no-files-found: warn
      - name: Upload release APK (for RuStore)
        if: env.KEYSTORE_BASE64 != ''
        uses: actions/upload-artifact@v4
        with:
          name: black-boost-release-apk
          path: app/build/outputs/apk/release/*.apk
          if-no-files-found: error
EOF_WF
grep -q '\*.jks' .gitignore 2>/dev/null || printf '*.jks\nkeystore.b64.txt\n' >> .gitignore

KS="$HOME/blackboost-release.jks"; INFO="$HOME/blackboost-keystore.txt"; B64="$HOME/keystore.b64.txt"
if [ ! -f "$KS" ]; then
  echo "▶ Создаю ключ подписи (хранится вне репозитория)..."
  PASS="$(openssl rand -hex 12)"
  keytool -genkeypair -v -keystore "$KS" -alias blackboost -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass "$PASS" -keypass "$PASS" -dname "CN=Black Boost, O=BlackWeb Project, C=RU" >/dev/null 2>&1
  printf 'alias: blackboost\npassword: %s\nfile: %s\n' "$PASS" "$KS" > "$INFO"; chmod 600 "$INFO" "$KS"
fi
PASS="$(grep '^password:' "$INFO" | cut -d' ' -f2)"
base64 -w0 "$KS" > "$B64"

echo "▶ Добавляю секреты в GitHub..."
if gh secret set KEYSTORE_BASE64 < "$B64" >/dev/null 2>&1 \
 && gh secret set KEYSTORE_PASSWORD --body "$PASS" >/dev/null 2>&1 \
 && gh secret set KEY_ALIAS --body "blackboost" >/dev/null 2>&1 \
 && gh secret set KEY_PASSWORD --body "$PASS" >/dev/null 2>&1; then
  echo "✅ Секреты добавлены автоматически."
else
  echo "⚠ Не удалось добавить секреты автоматически. Добавьте вручную:"
  echo "  GitHub → репозиторий → Settings → Secrets and variables → Actions → New repository secret"
  echo "  KEY_ALIAS = blackboost"
  echo "  KEYSTORE_PASSWORD = $PASS"
  echo "  KEY_PASSWORD = $PASS"
  echo "  KEYSTORE_BASE64 = всё содержимое файла $B64 (откройте его в редакторе, выделите всё, скопируйте)"
fi

echo "▶ Коммит..."
git add -A
GN="$(git config user.name || echo BlackBoost)"; GE="$(git config user.email || echo bb@example.com)"
git -c user.name="$GN" -c user.email="$GE" commit -q -m "Signed release build for RuStore" || echo "(нечего коммитить)"
git push -u origin HEAD
echo "✅ Готово. После сборки: Actions → Build APK → Artifacts → black-boost-release-apk (внутри app-release.apk). Эту копию ключа сохраните: $KS и $INFO"

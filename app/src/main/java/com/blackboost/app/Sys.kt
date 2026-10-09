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

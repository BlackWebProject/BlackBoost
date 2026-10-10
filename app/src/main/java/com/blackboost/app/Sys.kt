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
                var b = apkSize(ai)
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

    /** Размер установки (APK) — доступен без каких-либо разрешений, в отличие от размера данных и кэша. */
    private fun apkSize(ai: ApplicationInfo): Long {
        var s = try { File(ai.sourceDir).length() } catch (e: Exception) { 0L }
        ai.splitSourceDirs?.forEach { s += try { File(it).length() } catch (e: Exception) { 0L } }
        return s
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
    fun openUrl(c: Context, u: String) = tryGo(c, Intent(Intent.ACTION_VIEW, Uri.parse(u)))
    fun usageSettings(c: Context) = go(c, Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
    fun filesSettings(c: Context) { if (Build.VERSION.SDK_INT >= 30) go(c, Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION, Uri.parse("package:${c.packageName}"))) }
    fun appInfo(c: Context, p: String) = go(c, Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.parse("package:$p")))
    fun saver(c: Context) = go(c, Intent(Settings.ACTION_BATTERY_SAVER_SETTINGS))
    fun battOpt(c: Context) = go(c, Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
    fun dnd(c: Context) = go(c, Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS))
    fun uninstall(c: Context, p: String) = go(c, Intent(Intent.ACTION_DELETE, Uri.parse("package:$p")))

    fun model() = Build.MANUFACTURER.replaceFirstChar { it.uppercase() } + " " + Build.MODEL
    fun androidVer() = "Android " + Build.VERSION.RELEASE + " (API " + Build.VERSION.SDK_INT + ")"
    fun thermal(c: Context): Int? = if (Build.VERSION.SDK_INT >= 29) c.getSystemService(PowerManager::class.java).currentThermalStatus else null
    fun display(c: Context) = go(c, Intent(Settings.ACTION_DISPLAY_SETTINGS))

    /** Время на экране за 24 часа (нужен доступ к статистике использования). */
    fun fgUsage(c: Context): Map<String, Long> {
        if (!hasUsage(c)) return emptyMap()
        val now = System.currentTimeMillis()
        return c.getSystemService(UsageStatsManager::class.java).queryAndAggregateUsageStats(now - 86400000L, now).mapValues { it.value.totalTimeInForeground }
    }

    /** Загрузка CPU из /proc/stat. На многих телефонах Android 8+ файл закрыт, тогда вернёт null. */
    class CpuSampler {
        private var prev: LongArray? = null
        fun read(): Int? {
            val l = try { File("/proc/stat").bufferedReader().use { it.readLine() } } catch (e: Exception) { null } ?: return null
            val n = l.trim().split(Regex("\\s+")).drop(1).mapNotNull { it.toLongOrNull() }
            if (n.size < 4) return null
            val idle = n[3] + (n.getOrNull(4) ?: 0L)
            val tot = n.sum()
            val p = prev
            prev = longArrayOf(idle, tot)
            if (p == null) return null
            val dt = tot - p[1]
            return if (dt > 0) (100 * (dt - (idle - p[0])) / dt).toInt().coerceIn(0, 100) else null
        }
    }

    private val SENS = mapOf(
        "android.permission.CAMERA" to "camera", "android.permission.RECORD_AUDIO" to "mic",
        "android.permission.ACCESS_FINE_LOCATION" to "loc", "android.permission.ACCESS_COARSE_LOCATION" to "loc",
        "android.permission.READ_CONTACTS" to "contacts", "android.permission.READ_SMS" to "sms", "android.permission.READ_CALL_LOG" to "calls"
    )

    /** Какие чувствительные разрешения реально выданы приложениям. */
    fun sensitive(c: Context, pkgs: List<String>): Map<String, Set<String>> {
        val pm = c.packageManager
        val out = HashMap<String, Set<String>>()
        for (p in pkgs) {
            try {
                val pi = pm.getPackageInfo(p, PackageManager.GET_PERMISSIONS)
                val rp = pi.requestedPermissions ?: continue
                val fl = pi.requestedPermissionsFlags ?: continue
                val s = HashSet<String>()
                rp.forEachIndexed { i, n ->
                    val k = SENS[n]
                    if (k != null && (fl[i] and android.content.pm.PackageInfo.REQUESTED_PERMISSION_GRANTED) != 0) s.add(k)
                }
                if (s.isNotEmpty()) out[p] = s
            } catch (e: Exception) { }
        }
        return out
    }
}

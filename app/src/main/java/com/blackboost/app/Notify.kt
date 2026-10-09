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
        val last = Prefs(applicationContext).lastClean
        if (System.currentTimeMillis() - last > 7 * 86400000L && s.first * 100 / s.second < 40)
            Notify.post(applicationContext, if (en) "Time to check storage" else "Пора проверить хранилище", if (en) "No cleanup for a week. Open Black Boost and run a scan." else "Неделю не было очистки. Откройте Black Boost и запустите сканирование.")
        return Result.success()
    }
}

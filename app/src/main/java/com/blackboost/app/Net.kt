package com.blackboost.app

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.net.HttpURLConnection
import java.net.InetSocketAddress
import java.net.Socket
import java.net.URL
import kotlin.math.abs

class NetRes(val type: String, val ping: Int?, val jitter: Int?, val loss: Int, val mbps: Float?)

/** Диагностика сети: задержка (TCP), джиттер, потери, скорость загрузки (около 4 МБ трафика). */
object Net {
    suspend fun test(c: Context): NetRes = withContext(Dispatchers.IO) {
        val cm = c.getSystemService(ConnectivityManager::class.java)
        val caps = cm.getNetworkCapabilities(cm.activeNetwork)
        val type = when {
            caps == null -> "none"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
            caps.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "cell"
            else -> "other"
        }
        val times = ArrayList<Long>()
        var lost = 0
        repeat(8) {
            val t0 = System.nanoTime()
            try {
                Socket().use { it.connect(InetSocketAddress("1.1.1.1", 443), 2000) }
                times.add((System.nanoTime() - t0) / 1_000_000)
            } catch (e: Exception) { lost++ }
            Thread.sleep(150)
        }
        val ping = if (times.isNotEmpty()) times.average().toInt() else null
        val jit = if (times.size > 1) times.zipWithNext { a, b -> abs(a - b) }.average().toInt() else null
        var mbps: Float? = null
        if (type != "none") {
            try {
                val t0 = System.nanoTime()
                var n = 0L
                val con = URL("https://speed.cloudflare.com/__down?bytes=4000000").openConnection() as HttpURLConnection
                con.connectTimeout = 4000
                con.readTimeout = 6000
                con.inputStream.use { s ->
                    val b = ByteArray(32768)
                    while (true) { val r = s.read(b); if (r < 0) break; n += r }
                }
                val sec = (System.nanoTime() - t0) / 1e9
                if (sec > 0 && n > 0) mbps = (n * 8 / 1e6 / sec).toFloat()
            } catch (e: Exception) { }
        }
        NetRes(type, ping, jit, lost * 100 / 8, mbps)
    }
}

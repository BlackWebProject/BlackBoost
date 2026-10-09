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
    var gProf: String
        get() = p.getString("gprof", "perf") ?: "perf"
        set(v) = p.edit().putString("gprof", v).apply()
    var gMode: Int
        get() = p.getInt("gmode", 1)
        set(v) = p.edit().putInt("gmode", v).apply()
    var lastClean: Long
        get() = p.getLong("lastclean", 0L)
        set(v) = p.edit().putLong("lastclean", v).apply()
    var games: Set<String>
        get() = p.getStringSet("games", emptySet())?.toSet() ?: emptySet()
        set(v) = p.edit().putStringSet("games", v).apply()
    private var hist: String
        get() = p.getString("hist", "") ?: ""
        set(v) = p.edit().putString("hist", v).apply()

    /** История очистки: сколько байт освобождено и когда. */
    fun addHist(b: Long) {
        if (b <= 0) return
        val now = System.currentTimeMillis()
        val cut = now - 31L * 86400000
        val l = hist.split(";").filter { it.isNotEmpty() && (it.substringBefore(",").toLongOrNull() ?: 0L) > cut } + "$now,$b"
        hist = l.joinToString(";")
        lastClean = now
    }

    fun histSum(days: Int): Long {
        val cut = System.currentTimeMillis() - days * 86400000L
        return hist.split(";").filter { it.isNotEmpty() }.sumOf {
            val a = it.split(",")
            if ((a[0].toLongOrNull() ?: 0L) >= cut) (a.getOrNull(1)?.toLongOrNull() ?: 0L) else 0L
        }
    }
}

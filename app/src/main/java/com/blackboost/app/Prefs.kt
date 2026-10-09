package com.blackboost.app

import android.content.Context

class Prof(val mode: String, val clean: Boolean, val dnd: Boolean) {
    fun enc() = "$mode|$clean|$dnd"
    companion object {
        fun dec(s: String?): Prof? {
            val p = s?.split("|") ?: return null
            return if (p.size >= 3) Prof(p[0], p[1] == "true", p[2] == "true") else null
        }
    }
}

class Prefs(c: Context) {
    private val p = c.getSharedPreferences("bb", Context.MODE_PRIVATE)
    var lang: String
        get() = p.getString("lang", "ru") ?: "ru"
        set(v) = p.edit().putString("lang", v).apply()
    var notif: Boolean
        get() = p.getBoolean("notif", false)
        set(v) = p.edit().putBoolean("notif", v).apply()
    var premium: Boolean
        get() = p.getBoolean("pr", false)
        set(v) = p.edit().putBoolean("pr", v).apply()
    var onboarded: Boolean
        get() = p.getBoolean("onb", false)
        set(v) = p.edit().putBoolean("onb", v).apply()
    var treeUri: String?
        get() = p.getString("tree", null)
        set(v) = p.edit().putString("tree", v).apply()
    var dndPrev: Int
        get() = p.getInt("dnd", -1)
        set(v) = p.edit().putInt("dnd", v).apply()
    var energy: String
        get() = p.getString("energy", "bal") ?: "bal"
        set(v) = p.edit().putString("energy", v).apply()
    var defProf: Prof
        get() = Prof.dec(p.getString("def", null)) ?: Prof("perf", true, false)
        set(v) = p.edit().putString("def", v.enc()).apply()
    var games: Set<String>
        get() = p.getStringSet("games", emptySet())?.toSet() ?: emptySet()
        set(v) = p.edit().putStringSet("games", v).apply()
    fun prof(pkg: String): Prof = Prof.dec(p.getString("p_$pkg", null)) ?: defProf
    fun setProf(pkg: String, v: Prof) = p.edit().putString("p_$pkg", v.enc()).apply()
}

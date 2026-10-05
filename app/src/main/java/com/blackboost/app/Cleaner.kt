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

package com.blackboost.app

import android.content.Context
import android.os.Environment
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.security.MessageDigest

/** Файл-кандидат на удаление. group > 0 — группа дубликатов, orig — самый старый экземпляр (оригинал). */
class Fi(val file: File, val size: Long, val def: Boolean, val group: Int = 0, val orig: Boolean = false) {
    val path: String get() = file.path
}

class Cat(val id: String, val ru: String, val en: String, val files: List<Fi>) {
    val bytes: Long get() = files.sumOf { it.size }
}

object Cleaner {
    private val tmpExt = setOf("tmp", "temp", "log", "bak", "old", "chk", "dmp")
    private val mediaExt = setOf("jpg", "jpeg", "png", "webp", "heic", "gif", "mp4", "mkv", "mov", "3gp", "avi")

    fun ownFiles(c: Context): List<File> =
        listOfNotNull(c.cacheDir, c.externalCacheDir).flatMap { d -> d.walkBottomUp().filter { it.isFile }.toList() }

    private fun isJunk(n: String, par: String): Boolean {
        val ext = n.substringAfterLast('.', "")
        return n.startsWith(".trashed-") || par == ".thumbnails" || par == "LOST.DIR" || ext in tmpExt || n.startsWith("~")
    }

    private fun sha(f: File): String = try {
        val md = MessageDigest.getInstance("SHA-1")
        f.inputStream().use { s ->
            val buf = ByteArray(65536)
            while (true) { val n = s.read(buf); if (n <= 0) break; md.update(buf, 0, n) }
        }
        md.digest().joinToString("") { "%02x".format(it) }
    } catch (e: Exception) { f.path }

    /** Глубокое сканирование: кэш и временные файлы, старые загрузки, большие файлы, дубликаты фото и видео. Ничего не удаляет. */
    suspend fun scan(c: Context, stage: (String) -> Unit): List<Cat> = withContext(Dispatchers.IO) {
        val root = Environment.getExternalStorageDirectory()
        val dlPrefix = File(root, "Download").path + "/"
        val junk = ArrayList<Fi>()
        val dl = ArrayList<Fi>()
        val big = ArrayList<Fi>()
        val media = ArrayList<File>()
        ownFiles(c).forEach { junk.add(Fi(it, it.length(), true)) }
        stage("files")
        val old = System.currentTimeMillis() - 30L * 86400000
        root.walkTopDown().onEnter { !(it.parentFile == root && it.name == "Android") }.forEach { f ->
            if (!f.isFile) return@forEach
            val n = f.name.lowercase()
            val ext = n.substringAfterLast('.', "")
            val len = f.length()
            if (isJunk(n, f.parentFile?.name ?: "")) junk.add(Fi(f, len, true))
            else if (f.path.startsWith(dlPrefix) && (ext == "apk" || f.lastModified() < old)) dl.add(Fi(f, len, ext == "apk"))
            else if (len >= 100L * 1024 * 1024) big.add(Fi(f, len, false))
            else if (ext in mediaExt && len >= 50 * 1024) media.add(f)
        }
        stage("dups")
        val dup = ArrayList<Fi>()
        var gid = 0
        media.groupBy { it.length() }.values.filter { it.size > 1 }.take(400).forEach { g ->
            g.groupBy { sha(it) }.values.forEach { s ->
                if (s.size > 1) {
                    gid++
                    s.sortedBy { it.lastModified() }.forEachIndexed { i, f -> dup.add(Fi(f, f.length(), i > 0, gid, i == 0)) }
                }
            }
        }
        listOf(
            Cat("junk", "Кэш и временные файлы", "Cache & temp files", junk),
            Cat("dl", "Загрузки", "Downloads", dl),
            Cat("big", "Большие файлы", "Large files", big.sortedByDescending { it.size }),
            Cat("dup", "Дубликаты фото и видео", "Duplicate photos & videos", dup)
        )
    }

    suspend fun delete(list: List<Fi>, progress: (Float) -> Unit): Long = withContext(Dispatchers.IO) {
        var freed = 0L
        list.forEachIndexed { i, x ->
            val l = x.file.length()
            if (x.file.delete()) freed += l
            if (i % 10 == 0) progress((i + 1f) / list.size)
        }
        progress(1f)
        freed
    }

    suspend fun cleanOwn(c: Context): Long = withContext(Dispatchers.IO) {
        var freed = 0L
        ownFiles(c).forEach { val l = it.length(); if (it.delete()) freed += l }
        freed
    }

    /** Быстрая безопасная очистка: собственный кэш + явный мусор (tmp, миниатюры, корзина). Личные файлы не трогает. */
    suspend fun quick(c: Context, all: Boolean): Long = withContext(Dispatchers.IO) {
        var freed = 0L
        ownFiles(c).forEach { val l = it.length(); if (it.delete()) freed += l }
        if (all) {
            val root = Environment.getExternalStorageDirectory()
            root.walkTopDown().onEnter { !(it.parentFile == root && it.name == "Android") }.forEach { f ->
                if (f.isFile && isJunk(f.name.lowercase(), f.parentFile?.name ?: "")) {
                    val l = f.length()
                    if (f.delete()) freed += l
                }
            }
        }
        freed
    }
}

package com.blackboost.app

import android.content.Context
import android.net.Uri
import androidx.documentfile.provider.DocumentFile
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

class Del(val size: Long, val del: () -> Boolean)
class Junk(val id: String, val ru: String, val en: String, val items: List<Del>) {
    val bytes: Long get() = items.sumOf { it.size }
}

/**
 * Удаляет только то, к чему у приложения есть законный доступ:
 * 1) собственный кэш Black Boost; 2) файлы в папке, которую пользователь сам выбрал в системном выборе файлов (SAF).
 */
object Cleaner {
    private val tmpExt = setOf("tmp", "temp", "log", "bak", "old", "chk", "dmp")

    fun ownFiles(c: Context): List<File> =
        listOfNotNull(c.cacheDir, c.externalCacheDir).flatMap { d -> d.walkBottomUp().filter { it.isFile }.toList() }

    private fun fileItem(f: File) = Del(f.length()) { f.delete() }

    suspend fun cleanOwn(c: Context): Long = withContext(Dispatchers.IO) {
        var freed = 0L
        ownFiles(c).forEach { val l = it.length(); if (it.delete()) freed += l }
        freed
    }

    private fun walk(d: DocumentFile, depth: Int, tmp: MutableList<Del>, other: MutableList<Del>, cnt: IntArray) {
        if (depth > 6 || cnt[0] > 20000) return
        for (f in d.listFiles()) {
            cnt[0]++
            if (f.isDirectory) { walk(f, depth + 1, tmp, other, cnt); continue }
            val n = (f.name ?: "").lowercase()
            val ext = n.substringAfterLast('.', "")
            val it = Del(f.length()) { f.delete() }
            if (ext in tmpExt || n.startsWith("~")) tmp.add(it)
            else if (ext == "apk" || n.startsWith(".trashed-")) other.add(it)
        }
    }

    suspend fun scan(c: Context, tree: Uri?): List<Junk> = withContext(Dispatchers.IO) {
        val tmp = ArrayList<Del>()
        val other = ArrayList<Del>()
        if (tree != null) {
            try {
                DocumentFile.fromTreeUri(c, tree)?.let { walk(it, 0, tmp, other, IntArray(1)) }
            } catch (e: Exception) { }
        }
        listOf(
            Junk("cache", "Кэш Black Boost", "Black Boost cache", ownFiles(c).map { fileItem(it) }),
            Junk("tmp", "Временные файлы", "Temp files", tmp),
            Junk("other", "Остальное", "Other", other)
        )
    }

    suspend fun clean(items: List<Del>, progress: (Float) -> Unit): Long = withContext(Dispatchers.IO) {
        var freed = 0L
        items.forEachIndexed { i, x ->
            if (x.del()) freed += x.size
            if (i % 10 == 0) progress((i + 1f) / items.size)
        }
        progress(1f)
        freed
    }
}

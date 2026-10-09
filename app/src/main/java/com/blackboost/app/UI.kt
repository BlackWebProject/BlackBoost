@file:OptIn(ExperimentalTextApi::class)

package com.blackboost.app

import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.*
import androidx.compose.foundation.text.BasicText
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.*
import androidx.compose.ui.draw.*
import androidx.compose.ui.geometry.*
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.*
import androidx.compose.ui.graphics.vector.*
import androidx.compose.ui.text.*
import androidx.compose.ui.text.font.*
import androidx.compose.ui.text.style.*
import androidx.compose.ui.unit.*
import java.util.Locale

val Bg = Color(0xFF050505); val Sf = Color(0xFF0E0E0E); val Ln = Color(0xFF242120)
val Tx = Color(0xFFF4EFE8); val Mu = Color(0xFF8F8980); val Ink = Color(0xFF150500)
val Em = Color(0xFFFF5A1F); val Am = Color(0xFFFFB347); val Rd = Color(0xFFC1121F)
val Hot = Brush.linearGradient(listOf(Am, Em, Rd))

val Disp = FontFamily(
    Font(R.font.unbounded, FontWeight.Bold, variationSettings = FontVariation.Settings(FontVariation.weight(700))),
    Font(R.font.unbounded, FontWeight.Black, variationSettings = FontVariation.Settings(FontVariation.weight(900)))
)
val Body = FontFamily(
    Font(R.font.manrope, FontWeight.Medium, variationSettings = FontVariation.Settings(FontVariation.weight(500))),
    Font(R.font.manrope, FontWeight.SemiBold, variationSettings = FontVariation.Settings(FontVariation.weight(600))),
    Font(R.font.manrope, FontWeight.Bold, variationSettings = FontVariation.Settings(FontVariation.weight(700)))
)

val LocalLang = compositionLocalOf { "ru" }
@Composable fun t(ru: String, en: String) = if (LocalLang.current == "en") en else ru

fun Long.sz(): String = if (this >= 1_000_000_000L) String.format(Locale.US, "%.1f GB", this / 1e9) else String.format(Locale.US, "%d MB", this / 1_000_000)

fun icon(d: String): ImageVector = ImageVector.Builder(24.dp, 24.dp, 24f, 24f).addPath(
    pathData = addPathNodes(d), stroke = SolidColor(Color.White), strokeLineWidth = 1.8f,
    strokeLineCap = StrokeCap.Round, strokeLineJoin = StrokeJoin.Round
).build()

object Ic {
    val home = icon("M3 11L12 4l9 7v9H3z")
    val trash = icon("M4 7h16M9 7V4h6v3M6 7l1 13h10l1-13")
    val battery = icon("M8 5h8a2 2 0 0 1 2 2v12a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2zM10 2h4")
    val grid = icon("M4 4h7v7H4zM13 4h7v7h-7zM4 13h7v7H4zM13 13h7v7h-7z")
    val gear = icon("M12 9a3 3 0 1 0 0 6 3 3 0 1 0 0-6zM12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M19 5l-2 2M7 17l-2 2")
    val back = icon("M15 5l-7 7 7 7")
    val db = icon("M4 6a8 3 0 1 0 16 0 8 3 0 1 0-16 0M4 6v6c0 1.7 3.6 3 8 3s8-1.3 8-3V6M4 12v6c0 1.7 3.6 3 8 3s8-1.3 8-3v-6")
    val bell = icon("M6 16V11a6 6 0 0 1 12 0v5l2 2H4zM10 21h4")
    val globe = icon("M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0zM3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18")
    val bolt = icon("M13 2L4 14h6l-1 8 9-12h-6z")
    val clock = icon("M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0zM12 7v5l3 2")
    val close = icon("M6 6l12 12M18 6L6 18")
    val play = icon("M5 3l14 9-14 9z")
    val chart = icon("M3 17l5-6 4 4 6-8M3 21h18")
}

@Composable
fun Txt(
    s: String, size: Int = 15, color: Color = Tx, w: FontWeight = FontWeight.Medium, disp: Boolean = false,
    modifier: Modifier = Modifier, align: TextAlign? = null, brush: Brush? = null, deco: TextDecoration? = null
) {
    val fam = if (disp) Disp else Body
    if (brush != null) BasicText(s, modifier, TextStyle(brush = brush, fontSize = size.sp, fontWeight = w, fontFamily = fam, textAlign = align ?: TextAlign.Unspecified, textDecoration = deco))
    else Text(s, modifier, color = color, fontSize = size.sp, fontWeight = w, fontFamily = fam, textAlign = align, textDecoration = deco)
}

fun Modifier.card(r: Int = 18): Modifier = this.background(Sf, RoundedCornerShape(r.dp)).border(1.dp, Ln, RoundedCornerShape(r.dp))

@Composable
fun HotBtn(text: String, enabled: Boolean = true, onClick: () -> Unit) {
    Box(
        Modifier.fillMaxWidth().height(54.dp).clip(RoundedCornerShape(16.dp)).background(Hot, alpha = if (enabled) 1f else 0.4f)
            .clickable(enabled = enabled, onClick = onClick), Alignment.Center
    ) { Txt(text, 15, Ink, FontWeight.Bold) }
}

@Composable
fun Item(ic: ImageVector?, title: String, sub: String? = null, trail: (@Composable () -> Unit)? = null, onClick: (() -> Unit)? = null) {
    Row(
        Modifier.fillMaxWidth().card(16).then(if (onClick != null) Modifier.clip(RoundedCornerShape(16.dp)).clickable(onClick = onClick) else Modifier).padding(14.dp, 12.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        if (ic != null) Icon(ic, null, Modifier.size(24.dp), tint = Em)
        Column(Modifier.weight(1f)) { Txt(title, 15, w = FontWeight.SemiBold); if (sub != null) Txt(sub, 12, Mu) }
        trail?.invoke()
    }
}

@Composable
fun Tog(on: Boolean, onChange: (Boolean) -> Unit) {
    val x by animateDpAsState(if (on) 22.dp else 3.dp, label = "tog")
    Box(Modifier.width(46.dp).height(27.dp).clip(RoundedCornerShape(14.dp)).background(if (on) Em else Color(0xFF2A2725)).clickable { onChange(!on) }) {
        Box(Modifier.offset(x, 3.dp).size(21.dp).clip(CircleShape).background(Tx))
    }
}

@Composable
fun Tabs(l: List<String>, s: Int, on: (Int) -> Unit) {
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        l.forEachIndexed { i, x ->
            Box(
                Modifier.weight(1f).height(40.dp).clip(RoundedCornerShape(20.dp))
                    .then(if (i == s) Modifier.background(Hot) else Modifier.border(1.dp, Ln, RoundedCornerShape(20.dp)))
                    .clickable { on(i) }, Alignment.Center
            ) { Txt(x, 12, if (i == s) Ink else Mu, FontWeight.SemiBold) }
        }
    }
}

@Composable
fun Bar(p: Float) {
    Box(Modifier.fillMaxWidth().height(7.dp).clip(RoundedCornerShape(4.dp)).background(Color(0xFF1C1917))) {
        Box(Modifier.fillMaxWidth(p.coerceIn(0f, 1f)).fillMaxHeight().background(Hot))
    }
}

@Composable
fun Ring(p: Float, size: Dp, anim: Boolean = true, content: @Composable BoxScope.() -> Unit) {
    val a by animateFloatAsState(p.coerceIn(0f, 1f), tween(600), label = "ring")
    val v = if (anim) a else p.coerceIn(0f, 1f)
    Box(Modifier.size(size), Alignment.Center) {
        Canvas(Modifier.fillMaxSize()) {
            val s = this.size.width * 0.06f
            val tl = Offset(s, s)
            val sz = Size(this.size.width - 2 * s, this.size.height - 2 * s)
            drawArc(Color(0xFF1A1816), 0f, 360f, false, tl, sz, style = Stroke(s))
            rotate(-90f) {
                drawArc(Em.copy(alpha = 0.22f), 0f, 360f * v, false, tl, sz, style = Stroke(s * 2f, cap = StrokeCap.Round))
                drawArc(Brush.sweepGradient(listOf(Am, Em, Rd)), 0f, 360f * v, false, tl, sz, style = Stroke(s, cap = StrokeCap.Round))
            }
        }
        content()
    }
}

@Composable
fun Donut(parts: List<Pair<Float, Color>>, size: Dp, content: @Composable BoxScope.() -> Unit) {
    Box(Modifier.size(size), Alignment.Center) {
        Canvas(Modifier.fillMaxSize()) {
            val s = this.size.width * 0.12f
            val tl = Offset(s / 2, s / 2)
            val sz = Size(this.size.width - s, this.size.height - s)
            drawArc(Color(0xFF1C1917), 0f, 360f, false, tl, sz, style = Stroke(s))
            var a = -90f
            parts.forEach { (f, c) ->
                val sw = f * 360f
                if (sw > 1f) drawArc(c, a, sw - 1.5f, false, tl, sz, style = Stroke(s))
                a += sw
            }
        }
        content()
    }
}

/** Ровная галочка: рисуется вертикально, без поворотов. */
@Composable
fun CheckMark(size: Dp, color: Color = Tx) {
    val p = remember { Animatable(0f) }
    LaunchedEffect(Unit) { p.animateTo(1f, tween(500)) }
    Canvas(Modifier.size(size)) {
        val w = this.size.width
        val path = Path().apply { moveTo(w * 0.2f, w * 0.52f); lineTo(w * 0.43f, w * 0.74f); lineTo(w * 0.8f, w * 0.3f) }
        val seg = Path()
        val pm = PathMeasure()
        pm.setPath(path, false)
        pm.getSegment(0f, pm.length * p.value, seg, true)
        drawPath(seg, color, style = Stroke(w * 0.1f, cap = StrokeCap.Round, join = StrokeJoin.Round))
    }
}

@Composable
fun MiniCheck(on: Boolean) {
    Box(
        Modifier.size(22.dp).clip(CircleShape).then(if (on) Modifier.background(Hot) else Modifier.border(2.dp, Color(0xFF4A4540), CircleShape)),
        Alignment.Center
    ) { if (on) CheckMark(14.dp, Ink) }
}

@Composable
fun TopBar(title: String, back: Boolean, onBack: () -> Unit) {
    Row(Modifier.fillMaxWidth().padding(20.dp, 16.dp, 20.dp, 8.dp), verticalAlignment = Alignment.CenterVertically) {
        if (back) Box(Modifier.size(40.dp).clip(CircleShape).background(Sf).border(1.dp, Ln, CircleShape).clickable(onClick = onBack), Alignment.Center) { Icon(Ic.back, null, Modifier.size(20.dp), tint = Tx) }
        else Spacer(Modifier.size(40.dp))
        Txt(title, 19, disp = true, w = FontWeight.Bold, modifier = Modifier.weight(1f), align = TextAlign.Center)
        Spacer(Modifier.size(40.dp))
    }
}

val Ok = Color(0xFF3DDC84); val Warn = Color(0xFFFFC107); val Off = Color(0xFF8F8980); val Bad = Color(0xFFFF5252)

@Composable
fun Dot(c: Color) { Box(Modifier.size(9.dp).clip(CircleShape).background(c)) }

/** Строка функции с настоящим статусом: зелёный — активно, жёлтый — нужна настройка, серый — не используется, красный — недоступно. */
@Composable
fun Feat(ic: ImageVector, title: String, st: Color, stText: String, onClick: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(16.dp)).card(16).clickable(onClick = onClick).padding(16.dp, 14.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp)
    ) {
        Icon(ic, null, Modifier.size(26.dp), tint = Em)
        Column(Modifier.weight(1f)) {
            Txt(title, 15, w = FontWeight.SemiBold)
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) { Dot(st); Txt(stText, 12, Mu) }
        }
        Txt("›", 22, Mu)
    }
}

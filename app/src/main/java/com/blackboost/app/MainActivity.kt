package com.blackboost.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.viewModels
import androidx.compose.runtime.CompositionLocalProvider
import androidx.core.view.WindowCompat

class MainActivity : ComponentActivity() {
    private val vm: Vm by viewModels()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.getInsetsController(window, window.decorView).isAppearanceLightStatusBars = false
        vm.billing.start()
        setContent { CompositionLocalProvider(LocalLang provides vm.lang) { App(vm, this) } }
    }

    override fun onResume() {
        super.onResume()
        vm.onResume()
    }
}

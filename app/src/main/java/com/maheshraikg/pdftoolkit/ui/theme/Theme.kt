package com.maheshraikg.pdftoolkit.ui.theme

import android.app.Activity
import android.os.Build
import androidx.appcompat.app.AppCompatDelegate
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val DarkColorScheme = darkColorScheme(
    primary = Teal80,
    secondary = TealGrey80,
    tertiary = Amber80
)

private val LightColorScheme = lightColorScheme(
    primary = Teal40,
    secondary = TealGrey40,
    tertiary = Amber40
)

@Composable
fun PDFToolkitTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    // Default to the app's own brand palette rather than the device wallpaper's
    // Material You colors, so the app has a consistent, distinctive identity.
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit
) {
    // Determine the actual dark theme state based on AppCompatDelegate mode
    val actualDarkTheme = when (AppCompatDelegate.getDefaultNightMode()) {
        AppCompatDelegate.MODE_NIGHT_YES -> true
        AppCompatDelegate.MODE_NIGHT_NO -> false
        else -> darkTheme // MODE_NIGHT_FOLLOW_SYSTEM or unspecified
    }
    
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (actualDarkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }

        actualDarkTheme -> DarkColorScheme
        else -> LightColorScheme
    }
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = colorScheme.primary.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !actualDarkTheme
        }
    }

    MaterialTheme(
        colorScheme = colorScheme,
        typography = Typography,
        content = content
    )
}
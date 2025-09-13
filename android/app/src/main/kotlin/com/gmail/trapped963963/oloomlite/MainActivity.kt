package com.gmail.trapped963963.oloomlite

import io.flutter.embedding.android.FlutterActivity
import androidx.core.view.WindowCompat // ## ADD THIS IMPORT ##

class MainActivity: FlutterActivity() {

    override fun onPostResume() {
        super.onPostResume()
        WindowCompat.setDecorFitsSystemWindows(window, true)
    }
}
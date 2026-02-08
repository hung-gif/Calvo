package com.example.calvo

import android.content.Context
import androidx.multidex.MultiDexApplication

class CalvoApplication : MultiDexApplication() {
    override fun onCreate() {
        super.onCreate()
        instance = this
    }

    companion object {
        lateinit var instance: CalvoApplication
            private set
    }
}
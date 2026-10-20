package com.absensi.mobile

import android.os.SystemClock
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.bsp.absensi/elapsed_time"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getElapsedRealtime" -> {
                    val elapsedMillis = SystemClock.elapsedRealtime()
                    result.success(elapsedMillis)
                }
                "getBootCount" -> {
                    try {
                        val bootCount = Settings.Global.getInt(
                            contentResolver,
                            Settings.Global.BOOT_COUNT
                        )
                        result.success(bootCount)
                    } catch (e: Settings.SettingNotFoundException) {
                        result.success(0)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}

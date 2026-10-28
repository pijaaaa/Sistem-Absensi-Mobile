package com.absensi.mobile

import android.os.SystemClock
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
                    result.success(SystemClock.elapsedRealtime())
                }
                "getBootCount" -> {
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.N) {
                        val bootCount = android.provider.Settings.Global.getInt(
                            contentResolver,
                            android.provider.Settings.Global.BOOT_COUNT,
                            0
                        )
                        result.success(bootCount)
                    } else {
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

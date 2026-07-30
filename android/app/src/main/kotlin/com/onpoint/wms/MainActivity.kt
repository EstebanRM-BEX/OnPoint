package com.onpoint.wms

import android.net.wifi.WifiManager
import android.content.Context
import android.os.Build
import android.provider.Settings
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "device_info/custom"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {

                // Obtener MAC
                "getMacAddress" -> {
                    try {
                        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                        val mac = wifiManager.connectionInfo.macAddress
                        result.success(mac)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                // Obtener IMEI o ANDROID_ID
                "getImei" -> {
                    try {
                        var imei: String? = null
                        val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

                        try {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                // getImei() requiere API >= 26
                                imei = telephonyManager.getImei(0) // primer SIM
                            } else {
                                @Suppress("DEPRECATION")
                                imei = telephonyManager.deviceId
                            }
                        } catch (_: SecurityException) {
                            // No tiene permisos, ignoramos
                        } catch (_: NoSuchMethodError) {
                            // Método no disponible
                        }

                        // Si no hay IMEI, usamos ANDROID_ID
                        if (imei.isNullOrEmpty()) {
                            imei = Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
                        }

                        result.success(imei)

                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}

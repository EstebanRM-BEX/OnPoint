package com.onpoint.wms

import android.app.ActivityManager
import android.app.ApplicationExitInfo
import android.net.wifi.WifiManager
import android.content.Context
import android.os.Build
import android.provider.Settings
import android.telephony.TelephonyManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.net.NetworkInterface

class MainActivity: FlutterActivity() {
    private val CHANNEL = "device_info/custom"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {

                // Obtener MAC
                "getMacAddress" -> {
                    try {
                        // WifiManager devuelve siempre 02:00:00:00:00:00 desde
                        // Android 6; se intenta primero la MAC real de wlan0.
                        val mac = getWlanMac() ?: run {
                            val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                            wifiManager.connectionInfo.macAddress
                        }
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

                // Motivos de salida recientes del proceso (Android 11+). En
                // versiones anteriores devuelve lista vacía.
                "getExitInfo" -> {
                    try {
                        result.success(getExitInfo())
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    /** Últimas salidas del proceso según ApplicationExitInfo (API 30+). */
    private fun getExitInfo(): List<Map<String, Any?>> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return emptyList()
        val am = getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        return am.getHistoricalProcessExitReasons(packageName, 0, 5).map {
            mapOf(
                "reason" to exitReasonName(it.reason),
                "description" to it.description,
                "importance" to it.importance,
                "pss" to it.pss,
                "rss" to it.rss,
                "timestamp" to it.timestamp,
            )
        }
    }

    private fun exitReasonName(reason: Int): String = when (reason) {
        ApplicationExitInfo.REASON_EXIT_SELF -> "EXIT_SELF"
        ApplicationExitInfo.REASON_SIGNALED -> "SIGNALED"
        ApplicationExitInfo.REASON_LOW_MEMORY -> "LOW_MEMORY"
        ApplicationExitInfo.REASON_CRASH -> "CRASH"
        ApplicationExitInfo.REASON_CRASH_NATIVE -> "CRASH_NATIVE"
        ApplicationExitInfo.REASON_ANR -> "ANR"
        ApplicationExitInfo.REASON_INITIALIZATION_FAILURE -> "INITIALIZATION_FAILURE"
        ApplicationExitInfo.REASON_PERMISSION_CHANGE -> "PERMISSION_CHANGE"
        ApplicationExitInfo.REASON_EXCESSIVE_RESOURCE_USAGE -> "EXCESSIVE_RESOURCE_USAGE"
        ApplicationExitInfo.REASON_USER_REQUESTED -> "USER_REQUESTED"
        ApplicationExitInfo.REASON_USER_STOPPED -> "USER_STOPPED"
        ApplicationExitInfo.REASON_DEPENDENCY_DIED -> "DEPENDENCY_DIED"
        ApplicationExitInfo.REASON_OTHER -> "OTHER"
        else -> if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            when (reason) {
                ApplicationExitInfo.REASON_FREEZER -> "FREEZER"
                ApplicationExitInfo.REASON_PACKAGE_STATE_CHANGE -> "PACKAGE_STATE_CHANGE"
                ApplicationExitInfo.REASON_PACKAGE_UPDATED -> "PACKAGE_UPDATED"
                else -> "UNKNOWN_$reason"
            }
        } else "UNKNOWN_$reason"
    }

    /** MAC de wlan0 vía NetworkInterface o sysfs; null si el SO la oculta. */
    private fun getWlanMac(): String? {
        try {
            val bytes = NetworkInterface.getNetworkInterfaces().toList()
                .firstOrNull { it.name.equals("wlan0", ignoreCase = true) }
                ?.hardwareAddress
            if (bytes != null && bytes.isNotEmpty()) {
                val mac = bytes.joinToString(":") { "%02x".format(it) }
                if (mac != "02:00:00:00:00:00") return mac
            }
        } catch (_: Exception) {
        }
        try {
            val mac = File("/sys/class/net/wlan0/address").readText().trim().lowercase()
            if (mac.isNotEmpty() && mac != "02:00:00:00:00:00") return mac
        } catch (_: Exception) {
        }
        return null
    }
}

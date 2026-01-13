// File: rfid/Constants.kt
package com.example.rfid_demo.rfid

object Constants {

    private const val CHANNEL_NAMESPACE = "com.chien.libs.rfid_r6" // Phải khớp với Flutter
    
    const val CHANNEL_COMMAND = "$CHANNEL_NAMESPACE/methods"
    const val CHANNEL_EVENT = "$CHANNEL_NAMESPACE/events"
    
    // Commands
    const val CMD_CONNECT = "connect"
    const val CMD_DISCONNECT = "disconnect"
    const val CMD_START_SCAN = "startScan"
    const val CMD_STOP_SCAN = "stopScan"
    const val CMD_SET_POWER = "setPower"
    const val CMD_GET_POWER = "getPower"
    const val CMD_GET_BATTERY = "getBattery"
    const val CMD_SET_CW = "setCW"
    const val CMD_SET_BUZZER = "setBuzzer"
    const val CMD_CLEAR_DATA = "clearData"
}
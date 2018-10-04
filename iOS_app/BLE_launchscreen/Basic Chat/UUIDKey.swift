//
//  UUIDKey.swift
//  Basic Chat
//
//  Created by Trevor Beaton on 12/3/16.
//  Copyright © 2016 Vanguard Logic LLC. All rights reserved.
//
//  Modified by Trenton Taylor on 6/5/18.

import CoreBluetooth

//Uart Service uuid
//Modified to Environmental Sensing uuid

let kBLEService_UUID = "0000181a-0000-1000-8000-00805f9b34fb" // SIG UUID: Environmental Sensing
let kBLE_Characteristic_uuid_temperature = "00002a6e-0000-1000-8000-00805f9b34fb" // SIG UUID: Temperature
let kBLE_Characteristic_uuid_humidity = "00002a6f-0000-1000-8000-00805f9b34fb" // SIG UUID: Humidity
let kBLE_Characteristic_uuid_pressure = "00002a6d-0000-1000-8000-00805f9b34fb" // SIG UUID: Pressure
let MaxCharacters = 20
let BLEService_UUID = CBUUID(string: kBLEService_UUID)


let BLE_Characteristic_uuid_temperature = CBUUID(string: kBLE_Characteristic_uuid_temperature) //(Property = Read/Notify)
let BLE_Characteristic_uuid_humidity = CBUUID(string: kBLE_Characteristic_uuid_humidity) //(Property = Read/Notify)
let BLE_Characteristic_uuid_pressure = CBUUID(string: kBLE_Characteristic_uuid_pressure) //(Property = Read/Notify)

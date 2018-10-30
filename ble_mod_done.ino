/*
    Video: https://www.youtube.com/watch?v=oCMOYS71NIU
    Based on Neil Kolban example for IDF: https://github.com/nkolban/esp32-snippets/blob/master/cpp_utils/tests/BLE%20Tests/SampleNotify.cpp
    Ported to Arduino ESP32 by Evandro Copercini

   Create a BLE server that, once we receive a connection, will send periodic notifications.
   The service advertises itself as: 4fafc201-1fb5-459e-8fcc-c5c9c331914b
   And has a characteristic of: beb5483e-36e1-4688-b7f5-ea07361b26a8

   The design of creating the BLE server is:
   1. Create a BLE Server
   2. Create a BLE Service
   3. Create a BLE Characteristic on the Service
   4. Create a BLE Descriptor on the characteristic
   5. Start the service.
   6. Start advertising.

   A connect hander associated with the server starts a background task that performs notification
   every couple of seconds.
*/
#include <BLEDevice.h>
#include <BLE2902.h>
#include <Adafruit_BMP280.h>
#include "DHT.h"
#include <string>

// See the following for generating UUIDs:
// https://www.uuidgenerator.net/

#define SERVICE_UUID    "0000181a-0000-1000-8000-00805f9b34fb"
#define TEMP_UUID       "00002a6e-0000-1000-8000-00805f9b34fb"
#define HUMIDITY_UUID   "00002a6f-0000-1000-8000-00805f9b34fb"
#define PRESSURE_UUID   "00002a6d-0000-1000-8000-00805f9b34fb"
#define DHTPIN           21     // DHT11 connected to GPIO pin 21
#define DHTTYPE          DHT11  // DHT 11

// Global data
BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic_T = NULL;
BLECharacteristic* pCharacteristic_H = NULL;
BLECharacteristic* pCharacteristic_P = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;
Adafruit_BMP280 bme;
DHT dht(DHTPIN, DHTTYPE);
uint8_t temp[4];
uint8_t hum;    
uint8_t pres[4];
int tmp;
unsigned long start_time;
unsigned long cur_time;


// Server call back class
class MyServerCallbacks: public BLEServerCallbacks 
{
  void onConnect(BLEServer* pServer) 
  {
    deviceConnected = true;
  };

  void onDisconnect(BLEServer* pServer) 
  {
    deviceConnected = false;
  }
};


/***********************
 * Set up
************************/
void setup()  
{
  uint8_t baseMac[6];
  String deviceName = "UUweather_";
  
  //Serial.begin(115200);

  // Turn on RED led (GPIO 13) to signal board is powered on.
  pinMode(13, OUTPUT);
  digitalWrite(13, HIGH);

  // Get MAC address from ESP32 to include in the BLE device name
  //Serial.println("");
  //Serial.println("");
  esp_read_mac(baseMac, ESP_MAC_WIFI_STA);
  deviceName.concat(baseMac[5]);
  deviceName.concat(':');
  deviceName.concat(baseMac[4]);
  deviceName.concat(':');
  deviceName.concat(baseMac[3]);
  //Serial.println(deviceName);
  std::string str1;
  str1 = deviceName.c_str();

  // Try to reconnect if connection to BMP280 failed
  while(!bme.begin()) 
  {  
    //Serial.println("Could not find a valid BMP280 sensor, check wiring!");
    //while (1);
    digitalWrite(13, LOW);
    delay(500);
    digitalWrite(13, HIGH);
  }

  // DHT11 set up
  dht.begin();

  // Create the BLE Device
  BLEDevice::init(str1.c_str());

  // Create the BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

  // Create the BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  // Create a BLE Characteristic
  pCharacteristic_T = pService->createCharacteristic(
                      TEMP_UUID,
                      BLECharacteristic::PROPERTY_READ |
                      BLECharacteristic::PROPERTY_NOTIFY
                    );
  pCharacteristic_H = pService->createCharacteristic(
                      HUMIDITY_UUID,
                      BLECharacteristic::PROPERTY_READ |
                      BLECharacteristic::PROPERTY_NOTIFY
                    );
  pCharacteristic_P = pService->createCharacteristic(
                      PRESSURE_UUID,
                      BLECharacteristic::PROPERTY_READ |
                      BLECharacteristic::PROPERTY_NOTIFY
                    );

  // https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.descriptor.gatt.client_characteristic_configuration.xml
  // Create a BLE Descriptor
  pCharacteristic_T->addDescriptor(new BLE2902());
  pCharacteristic_H->addDescriptor(new BLE2902());
  pCharacteristic_P->addDescriptor(new BLE2902());

  // Start the service
  pService->start();

  // Start advertising
  pServer->getAdvertising()->start();
  //Serial.println("Waiting a client connection to notify...");

  // Start timer
  start_time = millis();
}


/***********************
 * Infinite loop
************************/
void loop() 
{
  // notify changed values
  if (deviceConnected) 
  {
    tmp = dht.readTemperature();
    //Serial.print("Temperature: ");
    //Serial.println(tmp);
    temp[0] = tmp;
    temp[1] = tmp >> 8;
    temp[2] = tmp >> 16;
    temp[3] = tmp >> 24;
    pCharacteristic_T->setValue(temp, 4);
    pCharacteristic_T->notify();
    delay(1000);

    hum = dht.readHumidity();
    //Serial.print("Humidity: ");
    //Serial.println(hum);
    pCharacteristic_H->setValue(&hum, 1);
    pCharacteristic_H->notify();
    delay(1000);

    tmp = bme.readPressure();
    //Serial.print("Pressure: ");
    //Serial.println(tmp);
    pres[0] = tmp;
    pres[1] = tmp >> 8;
    pres[2] = tmp >> 16;
    pres[3] = tmp >> 24;
    pCharacteristic_P->setValue(pres, 4);
    pCharacteristic_P->notify();
    delay(1000); // bluetooth stack will go into congestion, if too many packets are sent
  }
  // disconnecting
  if (!deviceConnected && oldDeviceConnected) 
  {
    delay(500); // give the bluetooth stack the chance to get things ready
    pServer->startAdvertising(); // restart advertising
    //Serial.println("start advertising");
    oldDeviceConnected = deviceConnected;
  }
  // connecting
  if (deviceConnected && !oldDeviceConnected) 
  {
    // do stuff here on connecting
    oldDeviceConnected = deviceConnected;
  }

  // Check if about 15 min have gone by
  cur_time = millis();
  if(cur_time - start_time >= 120000)
  {
    // Turn off RED LED to and power down board.
    digitalWrite(13, LOW);
    esp_deep_sleep_start();
  }
}



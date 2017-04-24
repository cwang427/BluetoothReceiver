//int datatype is 2 bytes (16 bits)

#include <SoftwareSerial.h>
//#include <CurieBLE.h>

//Set up serial bluetooth output stream
#define rxPin 11
#define txPin 12
SoftwareSerial BT1 = SoftwareSerial(rxPin, txPin);

//Set up peripheral device
//BLEPeripheral blePeripheral;
//BLEService bleService("FFE0");
//BLECharacteristic bleCharacteristic("FFE1", BLERead | BLENotify, 20)

int count = 0;  //keeps track of number of consecutive data points above threshold
int reps = 0;
void setup() {
  //Define pin modes
  pinMode(rxPin, INPUT);
  pinMode(txPin, OUTPUT);
  
  //Set up USB serial connection to computer
  Serial.begin(9600);

  //Set up Bluetooth serial connection to iOS
  BT1.begin(9600);

//  blePeripheral.setLocalName("SH-HC-08");
//  blePeripheral.setAdvertisedServiceUuid(bleService.uuid());
//  blePeripheral.addAttribute(bleService);
//  blePeripheral.addAttribute(bleCharacteristic);
//  blePeripheral.begin();
//  Serial.println("BLE device active. Waiting for connections...");
}

void loop() {
  //Serial.print("DATA, timex, voltage"); //writes the time in the first column A and the time since the measurements started in column B
  
  int sensorValue = analogRead(A0); //read in sensor data
  
  //Increment count if above threshold
  if (sensorValue >= 600) {
    count++;
  }

  //if below threshold, reset count to 0
  if (sensorValue < 600){
    count = 0;
  }

  //If above threshold for 20 counts, increment reps
  if (count == 20) {
    reps++;
  }
  
  //Serial.print("SensorValue: ");
  //Serial.print(sensorValue);
  //Serial.print("\t");
  //Serial.print("count: ");
  //Serial.print(count);
  //Serial.print("\t");
  //Serial.print("reps: ");

  Serial.println(reps);
  BT1.write(reps);

//  BLECentral central = blePeripheral.central();
//  if (central) {
//    Serial.print("Connected to central: ");
//    Serial.println(central.addres());
//    Serial.println(reps);
//  }

}

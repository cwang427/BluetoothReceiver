//
//  StreamViewController.swift
//  BluetoothReceiver
//
//  Created by Cassidy Wang on 4/22/17.
//  Copyright © 2017 Cassidy Wang. All rights reserved.
//

import UIKit
import BluetoothKit
import CoreBluetooth

class StreamViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    //Outlets
    @IBOutlet weak var streamDataLabel: UILabel!
    @IBOutlet weak var deviceConnectionStatusLabel: UILabel!
    @IBOutlet weak var serviceLabel: UILabel!
    @IBOutlet weak var characteristicLabel: UILabel!
    @IBOutlet weak var disconnectButton: UIButton!
    @IBOutlet weak var readValueButton: UIButton!

    //Vars
    var manager: CBCentralManager!
    var btModule: CBPeripheral!
    var nearbyPeripherals: [CBPeripheral] = []
    var keepScanning = false
    var btCharacteristic: CBCharacteristic?
    
    //UUID constants
    let PERIPHERAL_NAME = "SH-HC-08"
    let SERVICE_UUID = "FFE0"
    let CHAR_UUID = "FFE1"
    
    //Scanning intervals
    let timerPauseInterval: TimeInterval = 10.0
    let timerScanInterval: TimeInterval = 2.0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Search for BT connection
        NotificationCenter.default.addObserver(self, selector: #selector(StreamViewController.connectionChanged(_:)), name: NSNotification.Name(rawValue: BLEServiceChangedStatusNotification), object: nil)
        
        manager = CBCentralManager(delegate: self, queue: nil)
    }
    
    //MARK: - Bluetooth scanning
    
    func pauseScan() {
        print("***PAUSING SCAN***")
        _ = Timer(timeInterval: timerPauseInterval, target: self, selector: #selector(resumeScan), userInfo: nil, repeats: false)
        manager.stopScan()
        //disconnectButton.enabled = true
    }
    
    func resumeScan() {
        if (keepScanning) {
            print("***RESUMING SCAN***")
            //disconnectButton.enabled = false
            _ = Timer(timeInterval: timerScanInterval, target: self, selector: #selector(pauseScan), userInfo: self, repeats: false)
            manager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            //disconnectButton.enabled = true
        }
    }
    
    //MARK: - CBCentralManagerDelegate functions
    
    
    /*
     
     Invoked when central manager state is updated
     
    */
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        var showAlert = true
        var message = ""
        
        switch central.state {
        case .poweredOn:
            showAlert = false
            message = "BLE is on and ready for communication."
            keepScanning = true
            _ = Timer(timeInterval: timerScanInterval, target: self, selector: #selector(pauseScan), userInfo: nil, repeats: false)
            
            //Option 1: Scan for all devices
            manager.scanForPeripherals(withServices: nil, options: nil)
            
            //Option 2: Scan for devices with service(s) of interest
//            let serviceUUID = CBUUID(string: Device.serviceUUID)
//            print("Scanning for peripheral advertising with UUID: \(serviceUUID)")
//            manager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        case .poweredOff:
            message = "Bluetooth on this device is currently powered off."
        case .resetting:
            message = "BLE Manager is resetting; a state update is pending."
        case .unsupported:
            message = "This device does not support BLE."
        case .unauthorized:
            message = "This app is not authorized to use BLE."
        case .unknown:
            message = "The state of the BLE Manager is unknown."
        }
        
        if showAlert {
            let alertController = UIAlertController(title: "Central Manager State", message: message, preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
            alertController.addAction(okAction)
            self.show(alertController, sender: self)
        }
    }
    
    /*
     
     Invoked when central manager discovers a peripheral while scanning.
     
    */
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//        print("Discovered peripheral")
//        print("Advertisement data: \(advertisementData)")
//        print("Peripheral: \(peripheral)")
//        
//        print("centralManager didDiscoverPeripheral - CBAdvertisementDataLocalNameKey is \"\(CBAdvertisementDataLocalNameKey)\"")
        
        // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            print("NEXT PERIPHERAL NAME: \(peripheralName)")
            print("NEXT PERIPHERAL UUID: \(peripheral.identifier.uuidString)")
            
            if peripheralName == PERIPHERAL_NAME {
                print("Arduino+BLE module discovered! Adding now...")
                // to save power, stop scanning for other devices
                keepScanning = false
//                disconnectButton.enabled = true
                
                // save a reference to the sensor tag
                btModule = peripheral
                btModule!.delegate = self
                
                // Request a connection to the peripheral
                manager.connect(btModule, options: nil)
            }
        }
    }
    
    /*
 
     Invoked when connection is successfully created with a peripheral
     
    */
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to peripheral")
        deviceConnectionStatusLabel.text = "Connected"
        deviceConnectionStatusLabel.textColor = UIColor.green
        
        //Option 1: Discover all services
        peripheral.discoverServices(nil)
        
        //Option 2: Search for subset of services of interest
        peripheral.discoverServices([CBUUID(string: SERVICE_UUID)])
    }
    
    /*
 
     Invoked when central manager fails to establish connection with peripheral
     
     */
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("***CONNECTION FAILED***")
    }
    
    
    /*
     
     Invoked when existing connection with a peripheral is torn down
     
    */
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("***DISCONNECTED FROM PERIPHERAL***")
        if error != nil {
            print("***DISCONNECTION DETAILS: \(error!.localizedDescription)")
        }
        deviceConnectionStatusLabel.text = "Disconnected"
        deviceConnectionStatusLabel.textColor = UIColor.red
        btModule = nil
        central.scanForPeripherals(withServices: nil, options: nil)
    }
    
    
    //MARK: - CBPeripheralDelegate functions
    
    /*
     
     Invoked when services are discovered
     
    */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("***ERROR DISCOVERING SERVICES: \(String(describing: error?.localizedDescription))")
            return
        }
        
        if let services = peripheral.services {
            for service in services {
                print("Discovered service: \(service)")
                if service.uuid.uuidString == SERVICE_UUID {
                    print("Discovered target service \(SERVICE_UUID)")
                    peripheral.discoverCharacteristics(nil, for: service)
                }
            }
        }
    }
    
    /*
     
     Invoked when characteristics are discovered
     
    */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("***ERROR DISCOVERING CHARACTERISTICS: \(String(describing: error?.localizedDescription))")
            return
        }
        
        if let characteristics = service.characteristics {
            var enableValue:UInt8 = 1
            let enableBytes = NSData(bytes: &enableValue, length: MemoryLayout<UInt8>.size)
            
            for characteristic in characteristics {
                print("Discovered characteristic: \(characteristic)")
                if characteristic.uuid == CBUUID(string: Device.characteristicUUID) {
                    // Enable characteristic notifications
                    btCharacteristic = characteristic
                    self.readValueButton.isEnabled = true
                    btModule?.setNotifyValue(true, for: characteristic)
                    print("Set notify value to true for characteristic \(characteristic)")
                }
            }
        }
    }
    
    /*
 
     Invoked when characteristic value is retrieved or when the peripheral notifies change in characteristic value
     
    */
    
    @IBAction func readCharacteristic() {
        print("***READING CHARACTERISTIC***")
        if (btModule != nil && btCharacteristic != nil) {
            btModule.readValue(for: btCharacteristic!)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("ERROR UPDATING VALUE FOR CHARACTERISTIC: \(characteristic) - \(String(describing: error?.localizedDescription))")
            return
        }
        
        // extract the data from the characteristic's value property and display the value based on the characteristic type
        if let dataBytes = characteristic.value {
            if characteristic.uuid == CBUUID(string: Device.characteristicUUID) {
                print("Updated characteristic: \(characteristic)")
                displayData(data: dataBytes as NSData)
            }
        }
    }
    
    func displayData(data: NSData) {
        //We expect 20 bytes of data back
        //Create array of 16-bit (2 byte) values
        let dataLength = data.length / MemoryLayout<UInt16>.size
        var dataArray = [UInt16](repeating: 0, count: dataLength)
        
        //Extract data from dataBytes object
        data.getBytes(&dataArray, length: dataLength * MemoryLayout<Int16>.size)
        
        //Get characteristic value
        let rawValue: UInt16 = dataArray[0]
        print("rawValue: \(rawValue)")
        let value = Double(rawValue) / 128.0
        print("value: \(value)")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: BLEServiceChangedStatusNotification), object: nil)
    }
    
    func connectionChanged(_ notification: Notification) {
        //Connection status changed. Indicate on GUI
        print("connectionChanged() called")
    }
}

//
//  BluetoothController.swift
//  Mirage
//
//  Created by shaotianchi on 2024/09/19.
//

import CoreBluetooth
import os

class BluetoothController: NSObject {
    
    var shouldReconnect = true
    private(set) var canSendData = false
    
    private var peripheralManager: CBPeripheralManager!

    private var characteristic: CBMutableCharacteristic?
    private var connectedCentral: CBCentral?
    
    override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: true])
    }
    
    
    // MARK: - Helper Methods
    private func setupPeripheral() {
        // Build our service.
        
        // MARK: Generic Access Service
        
        let genericAccessService = CBMutableService(type: CBUUID(string: "1800"), primary: false)
        
        let appearenceUUID = CBUUID(string: "2A01")
        let appearanceValue = Data(NSData(bytes: [0xC103] as [UInt16], length: 2))
        let appearenceCharacteristic = CBMutableCharacteristic(type: appearenceUUID, properties: [.read], value: appearanceValue, permissions: [.readable])
        
        genericAccessService.characteristics = [appearenceCharacteristic]
        peripheralManager.add(genericAccessService)
        
        // MARK: Device Information Service
        
        let deviceInformationService = CBMutableService(type: CBUUID(string: "180A"), primary: false)
        
        let pnpUUID = CBUUID(string: "2A50")
        let pnpValue = Data(NSData(bytes: [0x00, 0x4700, 0xFFFF, 0xFFFF] as [UInt16], length: 8))
        let pnpCharacteristic = CBMutableCharacteristic(type: pnpUUID, properties: [.read], value: pnpValue, permissions: [.readable])
        
        deviceInformationService.characteristics = [pnpCharacteristic]
        peripheralManager.add(deviceInformationService)
        
        // MARK: Human Interface Device Service
        // See https://www.bluetooth.com/xml-viewer/?src=https://www.bluetooth.com/wp-content/uploads/Sitecore-Media-Library/Gatt/Xml/Services/org.bluetooth.service.human_interface_device.xml
        // Reference https://docs.silabs.com/bluetooth/latest/code-examples/applications/ble-hid-keyboard#gatt-database-for-keyboard-example
        
        let hidService = CBMutableService(type: HIDService.serviceUUID, primary: true)
        
        let hidInfoUUID = CBUUID(string: "2A4A")
        let hidInfoValue = Data(NSData(bytes: [0x0111, 0x0002] as [UInt16], length: 4))
        let hidInfoCharacteristic = CBMutableCharacteristic(type: hidInfoUUID, properties: [.read], value: hidInfoValue, permissions: [.readable])
        
        let protocolModeUUID = CBUUID(string: "2A4E")
        let protocolModeValue = Data(NSData(bytes: [0x00] as [UInt8], length: 1)) // report mode 00 is boot, 01 is report
        let protocolModeCharacteristic = CBMutableCharacteristic(type: protocolModeUUID, properties: [.read], value: protocolModeValue, permissions: [.readable])
        
        let reportMapUUID = CBUUID(string: "2A4B")
        let reportMapData = Data(HIDService.hidReportDescriptor)
        let reportMapCharacteristic = CBMutableCharacteristic(type: reportMapUUID, properties: [.read], value: reportMapData, permissions: [.readable, .readEncryptionRequired])

//        let hidControlPointUUID = CBUUID(string: "2A4C")
//        let hidControlPointCharacteristic = CBMutableCharacteristic(type: hidControlPointUUID, properties: [.writeWithoutResponse], value: nil, permissions: [.writeable])
        
        let reportUUID = CBUUID(string: "2A22")//"2A4D") would be report mode
        let reportCharacteristic = CBMutableCharacteristic(type: reportUUID, properties: [.read, .notify], value: nil, permissions: [.readable])
        
        let reportDescriptorUUID = CBUUID(string: "2908")
        let reportDescriptorValue = Data(NSData(bytes: [0x0001] as [UInt16], length: 2))
        let reportDescriptorCharacteristic = CBMutableCharacteristic(type: reportDescriptorUUID, properties: [.read], value: reportDescriptorValue, permissions: [.readable, .readEncryptionRequired])
        
        let cccd = CBMutableDescriptor(type: CBUUID(string: "2908"),  value: Data(NSData(bytes: [0x00, 0x01] as [UInt8], length: 2)))
        reportCharacteristic.descriptors = [cccd]
        
        hidService.characteristics = [hidInfoCharacteristic, protocolModeCharacteristic, reportMapCharacteristic, reportCharacteristic, reportDescriptorCharacteristic]
        
        // And add it to the peripheral manager.
        peripheralManager.add(hidService)
        
        // Save the characteristic for later.
        self.characteristic = reportCharacteristic

        let serviceUUIDs = [
            CBUUID(string: "1800"),
            CBUUID(string: "180A"),
            HIDService.serviceUUID
        ]
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: serviceUUIDs])
        
        print("after call start advertisting")
        print(serviceUUIDs)
        
        // MARK: WORKING CODE but with limited functionality
/*
        let characteristic = CBMutableCharacteristic(type: HIDService.characteristicUUID,
                                                         properties: [.notify, .writeWithoutResponse],
                                                         value: nil,
                                                         permissions: [.readable, .writeable])
        
        // Create a service from the characteristic.
        let service = CBMutableService(type: HIDService.serviceUUID, primary: true)
        
        // Add the characteristic to the service.
        service.characteristics = [characteristic]
        
        // And add it to the peripheral manager.
        peripheralManager.add(service)
        
        // Save the characteristic for later.
        self.characteristic = characteristic
        peripheralManager.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [HIDService.serviceUUID]])
 */
    }
    
    func sendKeystroke(_ keyStroke: HIDService.KeyStroke, _ keyState: HIDService.KeyState) {
        guard let characteristic = characteristic else {
            return
        }
        var didSend = true
        while didSend {
            
            // Get the data we need to send
            let data = HIDService.getReportDataFor(keyStroke: keyStroke, keyState: keyState)
            
            // Work out how big it can be
            let amountToSend = data.count
            if let mtu = connectedCentral?.maximumUpdateValueLength {
                guard mtu > amountToSend else {
                    os_log("Central can't receive \(amountToSend) bytes at a time - this is not handled")
                    // todo disconnect?
                    fatalError("Central can't receive \(amountToSend) bytes at a time - this is not handled")
                }
            }
            
            // TODO key up/down - rest of this function is not properly implemented
            //let chunk = HIDService.Data(keyStroke: keyStroke, state: keyState).stringRepresentation.data(using: .utf8)!
            
            // Send it
            didSend = peripheralManager.updateValue(data, for: characteristic, onSubscribedCentrals: nil)
            
            // If it didn't work, drop out and wait for the callback
            if !didSend {
                print("Didn't send")
                return
            }
            
//            let stringFromData = String(data: data, encoding: .ascii)
//            os_log("Sent %d bytes: %s", data.count, String(describing: stringFromData))
        }
    }
}

// MARK: Implementation of CBPeripheralManagerDelegate

extension BluetoothController: CBPeripheralManagerDelegate {

    /*
     *  Required protocol method.  A full app should take care of all the possible states,
     *  but we're just waiting for to know when the CBPeripheralManager is ready
     *
     *  Starting from iOS 13.0, if the state is CBManagerStateUnauthorized, you
     *  are also required to check for the authorization state of the peripheral to ensure that
     *  your app is allowed to use bluetooth
     */
    internal func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        
        // TODO tell UI if bluetooth is off
//        advertisingSwitch.isEnabled = peripheral.state == .poweredOn
        
        switch peripheral.state {
        case .poweredOn:
            // ... so start working with the peripheral
            os_log("CBManager is powered on")
            setupPeripheral()
        case .poweredOff:
            os_log("CBManager is not powered on")
            // TODO deal with all the states accordingly
            return
        case .resetting:
            os_log("CBManager is resetting")
            // TODO deal with all the states accordingly
            return
        case .unauthorized:
            // TODO deal with all the states accordingly
            switch CBPeripheralManager.authorization {
            case .denied:
                os_log("You are not authorized to use Bluetooth")
            case .restricted:
                os_log("Bluetooth is restricted")
            default:
                os_log("Unexpected authorization")
            }
            return
        case .unknown:
            os_log("CBManager state is unknown")
            // TODO deal with all the states accordingly
            return
        case .unsupported:
            os_log("Bluetooth is not supported on this device")
            // TODO deal with all the states accordingly
            return
        @unknown default:
            os_log("A previously unknown peripheral manager state occurred")
            // TODO deal with yet unknown cases that might occur in the future
            return
        }
    }

    /*
     *  Catch when someone subscribes to our characteristic, then start sending them data
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        os_log("Central subscribed to characteristic")
        
        // save central
        connectedCentral = central
        
        // Start sending
        canSendData = true
    }
    
    /*
     *  Recognize when the central unsubscribes
     */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        os_log("Central unsubscribed from characteristic")
        connectedCentral = nil
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print(String(describing: error))
        } else {
            print("Did start advertising.")
        }
    }
    
    /*
     *  This callback comes in when the PeripheralManager is ready to send the next chunk of data.
     *  This is to ensure that packets will arrive in the order they are sent
     */
//    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        // TODO do I need this?
//    }
    
    /*
     * This callback comes in when the PeripheralManager received write to characteristics
     */
//    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
//        for aRequest in requests {
//            guard let requestValue = aRequest.value,
//                let stringFromData = String(data: requestValue, encoding: .utf8) else {
//                    continue
//            }
//
//            os_log("Received write request of %d bytes: %s", requestValue.count, stringFromData)
//            self.textView.text = stringFromData
//        }
//    }
}

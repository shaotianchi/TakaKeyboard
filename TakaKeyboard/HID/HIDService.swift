//
//  HIDService.swift
//  Mirage
//
//  Created by shaotianchi on 2024/09/19.
//

import Foundation
import CoreBluetooth

struct HIDService {
    static let minRSSI = -70
    static let serviceUUID = CBUUID(string: "00001812-0000-1000-8000-00805F9B34FB")
    
    static let hidReportDescriptor = NSData(bytes:
                                                [
                                                    0x05, 0x01,  // USAGE_PAGE
                                                    0x09, 0x06,  // USAGE
                                                    0xA1, 0x01,  // COLLECTION
                                                    0x05, 0x07,  // USAGE_PAGE
                                                    0x19, 0xE0,  // USAGE_MINIMUM
                                                    0x29, 0xE7,  // USAGE_MAXIMUM
                                                    0x15, 0x00,  // LOGICAL_MINIMUM
                                                    0x25, 0x01,  // LOGICAL_MAXIMUM
                                                    0x75, 0x01,  // REPORT_SIZE 1 byte (Modifier)
                                                    0x95, 0x08,  // REPORT_COUNT
                                                    0x81, 0x02,  // INPUT   Data,Var,Abs,No Wrap,Linear,Preferred State,No Null Position
                                                    0x95, 0x01,  // REPORT_COUNT  1 byte (Reserved)
                                                    0x75, 0x08,  // REPORT_SIZE
                                                    0x81, 0x01,  // INPUT  Const,Array,Abs,No Wrap,Linear,Preferred State,No Null Position
                                                    0x95, 0x05,  // REPORT_COUNT  5 bits (Num lock, Caps lock, Scroll lock, Compose, Kana)
                                                    0x75, 0x01,  // REPORT_SIZE
                                                    0x05, 0x08,  // USAGE_PAGE LEDs
                                                    0x19, 0x01,  // USAGE_MINIMUM  Num Lock
                                                    0x29, 0x05,  // USAGE_MAXIMUM  Kana
                                                    0x91, 0x02,  // OUTPUT  Data,Var,Abs,No Wrap,Linear,Preferred State,No Null Position,Non-volatile
                                                    0x95, 0x01,  // REPORT_COUNT  3 bits (Padding)
                                                    0x75, 0x03,  // REPORT_SIZE
                                                    0x91, 0x01,  // OUTPUT Const,Array,Abs,No Wrap,Linear,Preferred State,No Null Position,Non-volatile
                                                    0x95, 0x06,  // REPORT_COUNT  6 bytes (Keys)
                                                    0x75, 0x08,  // REPORT_SIZE
                                                    0x15, 0x00,  // LOGICAL_MINIMUM
                                                    0x25, 0x65,  // LOGICAL_MAXIMUM  101 keys
                                                    0x05, 0x07,  // USAGE_PAGE  Kbrd/Keypad
                                                    0x19, 0x00,  // USAGE_MINIMUM
                                                    0x29, 0x65,  // USAGE_MAXIMUM
                                                    0x81, 0x00,  // INPUT  Data,Array,Abs,No Wrap,Linear,Preferred State,No Null Position
                                                    0xC0,           // END_COLLECTION
                                                ] as [UInt8], length: 63)
    // NSData(bytes:
//            [
//                0x05, 0x01, // Usage Page (Generic Desktop)
//                0x09, 0x06, // Usage (Keyboard)
//                0xA1, 0x01, // Collection (Application)
//                0x05, 0x07, // Usage Page (Keyboard)
//                0x19, 0xE0, // Usage Minimum (Keyboard LeftControl)
//                0x29, 0xE7, // Usage Maximum (Keyboard Right GUI)
//                0x15, 0x00, // Logical Minimum (0)
//                0x25, 0x01, // Logical Maximum (1)
//                0x75, 0x01, // Report Size (1)
//                0x95, 0x08, // Report Count (9)
//                0x81, 0x02, // Input (Data, Variable, Absolute) Modifier byte
//                0x95, 0x01, // Report Size (1)
//                0x75, 0x08, // Report Count (8)
//                0x81, 0x03, // Input (Constant) Reserved byte
//                0x95, 0x06, // Report Count (6)
//                0x75, 0x08, // Report Size (8)
//                0x15, 0x00, // Logical Minimum (0)
//                0x25, 0x65, // Logical Maximum (101)
//                0x05, 0x07, // Usage Page (Key Codes)
//                0x05, 0x01, // Usage Minimum (Reserved (no event indicated))
//                0x05, 0x01, // Usage Maximum (Keyboard Application)
//                0x05, 0x01, // Input (Data,Array) Key arrays (6 bytes)
//                0xC0        // End Collection
//            ] as [UInt8], length: 45)
    
    static func getReportDataFor(keyStroke: KeyStroke, keyState: KeyState) -> Data {
        var chunk: UInt8!
        switch keyState {
        case .Down:
            switch keyStroke {
            case .Left:
                chunk = 0x7F
            case .Right:
                chunk = 0x59
            case .Z:
                chunk = 0x1D
            }
        default:
            chunk = 0x00
        }
        let values = [0x00, 0x00, chunk, 0x00, 0x00, 0x00, 0x00, 0x00] as [UInt8]
        let data = Data(NSData(bytes: values, length: 8))
        return data
    }
    
    enum KeyStroke: UInt16 {
        case Left = 79
        case Right = 89
        case Z = 26
        
        static let lengthBytes = 2
    }
    
    enum KeyState: String {
        case Up = "up"
        case Down = "do"
        case None = "  "
    }
}

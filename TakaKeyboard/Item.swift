//
//  Item.swift
//  TakaKeyboard
//
//  Created by shaotianchi on 2024/09/19.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

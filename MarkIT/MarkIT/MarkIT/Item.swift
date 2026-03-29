//
//  Item.swift
//  MarkIT
//
//  Created by Kunal Kumar on 2026-03-29.
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

//
//  BufferManager.swift
//  smartdoor
//
//  Created by Lucas on 17/03/20.
//  Copyright © 2020 realize. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class storeBuffer {
    
    static let shared = storeBuffer()
    
    var actBuffer : CMSampleBuffer?
    
    var serviceBlocked : Bool
    
    init() {
        self.serviceBlocked = false
    }
}

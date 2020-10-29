//
//  Extesions.swift
//  smartdoor
//
//  Created by Lucas on 17/03/20.
//  Copyright © 2020 realize. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    
    func rotate(radians: CGFloat) -> UIImage {
          let rotatedSize = CGRect(origin: .zero, size: size)
              .applying(CGAffineTransform(rotationAngle: CGFloat(radians)))
              .integral.size
          UIGraphicsBeginImageContext(rotatedSize)
          if let context = UIGraphicsGetCurrentContext() {
              let origin = CGPoint(x: rotatedSize.width / 2.0,
                                   y: rotatedSize.height / 2.0)
              context.translateBy(x: origin.x, y: origin.y)
              context.rotate(by: radians)
              draw(in: CGRect(x: -origin.y, y: -origin.x,
                              width: size.width, height: size.height))
              let rotatedImage = UIGraphicsGetImageFromCurrentImageContext()
              UIGraphicsEndImageContext()

              return rotatedImage ?? self
          }

          return self
      }
    
    func resizeImage(targetSize: CGSize) -> UIImage {
        let size = self.size
        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height
        let newSize = widthRatio > heightRatio ?  CGSize(width: size.width * heightRatio, height: size.height * heightRatio) : CGSize(width: size.width * widthRatio,  height: size.height * widthRatio)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}

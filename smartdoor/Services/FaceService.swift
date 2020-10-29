//
//  FaceService.swift
//  tickets
//
//  Created by Lucas on 18/02/20.
//  Copyright © 2020 realize. All rights reserved.
//

import Foundation
import UIKit

struct FaceServiceResponse : Codable {
    //    var name : String?
    //    var valid : Bool?
    var faceId: String
    
}

class FaceService {
    
    let url = URL(string: Config().azureURL+"detect")!
    
    init() {
    }
    
    func request(img: UIImage, completion: @escaping(FaceServiceResponse) -> ()) {
        var request = URLRequest(url: url)
        request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
        request.setValue(Config().SubscriptionKey, forHTTPHeaderField:"Ocp-Apim-Subscription-Key")
        request.httpMethod = "POST"
        var imgResized = img.resizeImage(targetSize: CGSize(width: 500, height: 500))
        imgResized = imgResized.rotate(radians: .pi/2)
        #if DEBUG
//        var imgpreview = UIImageView(image: imgResized)
        #endif
        request.httpBody = imgResized.pngData()
        URLSession.shared.dataTask(with: request, completionHandler : { data, response, error in
            #if DEBUG
            if let data = data {
                if let jsonString = String(data: data, encoding: .utf8) {
                    print(jsonString)
                }
            }
            #endif
            let faceResponse = try? JSONDecoder().decode(Array<FaceServiceResponse>.self, from: data!)
            if faceResponse?.count ?? 0 > 0 {
                let response = faceResponse![0]
                completion(response)
            }
            else
            {
                completion(FaceServiceResponse(faceId: ""))
            }
           
            
        }).resume()
    }
    
}

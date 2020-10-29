//
//  DoorService.swift
//  smartdoor
//
//  Created by Lucas on 17/03/20.
//  Copyright © 2020 realize. All rights reserved.
//


import Foundation
import UIKit

struct DoorServiceResponse : Codable {
    //    var name : String?
    //    var valid : Bool?
    var relay_status: [String : String]?
    var pulse_final: String?

    
    init() {
        self.pulse_final = relay_status?["pulse_final"]
    }
}


class DoorService {
    let url = URL(string: Config().DOOR_IP+":3600/api/rasp/pulse")!
    init() {
    }
    
    func request(completion: @escaping(DoorServiceResponse) -> ()) {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue(Config().SubscriptionKey, forHTTPHeaderField:"Ocp-Apim-Subscription-Key")
        request.httpMethod = "POST"
        URLSession.shared.dataTask(with: request, completionHandler : { data, response, error in
            #if DEBUG
            if let data = data {
                if let jsonString = String(data: data, encoding: .utf8) {
                    print(jsonString)
                }
            }
            #endif
            let doorResponse = try? JSONDecoder().decode(DoorServiceResponse.self, from: data!)
//            if faceResponse?.count ?? 0 > 0 {
//                let response = faceResponse![0]
            completion(doorResponse ?? DoorServiceResponse())
//            }
//            else
//            {
//                completion(doorResponse(status: false))
//            }
           
        
        }).resume()
    }
    
}

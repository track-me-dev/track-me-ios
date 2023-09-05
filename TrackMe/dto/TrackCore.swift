//
//  TrackCore.swift
//  TrackMe
//
//  Created by 곽진현 on 2023/09/05.
//

import Foundation

struct TrackCore: Decodable {
    
    var path = [Dictionary<String, Double>]() // <latitude>:<value>, <longitude>:<value>, <elapsedTime>:<value>
    var records = [TrackRecord]()
}

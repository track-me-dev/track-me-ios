//
//  Track.swift
//  TrackMe
//
//  Created by 곽진현 on 2023/08/15.
//

import Foundation

struct Track: Decodable {
    let id: CLong
    let title: String
    var coordinates = [Dictionary<String, Double>]()
}

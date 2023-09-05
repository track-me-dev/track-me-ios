//
//  TrackRecord.swift
//  TrackMe
//
//  Created by 곽진현 on 2023/09/05.
//

import Foundation

struct TrackRecord: Decodable {
    let id: CLong
    let distance: Double
    let time: Double
}

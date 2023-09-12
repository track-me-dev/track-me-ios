//
//  Track.swift
//  TrackMe
//
//  Created by 곽진현 on 2023/08/15.
//

import Foundation

struct SearchTrackResponse: Decodable {
    let id: CLong
    var title: String
    var distance: Double
    
    // 백엔드 서버에서 일정 시각에 batch job으로 업데이트
    var averageSlope: Double?
    var lowestAltitude: Double?
    var highestAltitude: Double?
    
}

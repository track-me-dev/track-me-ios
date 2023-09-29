import Foundation

struct TrackDetailResponse: Decodable {
    var id: CLong
    var title: String
    var path = [Dictionary<String, Double>]() // <latitude>:<value>, <longitude>:<value>, <elapsedTime>:<value>
    var distance: Double
    var rank1stTime: Double
    
    // 백엔드 서버에서 일정 시각에 batch job으로 업데이트
    var averageSlope: Double?
    var lowestAltitude: Double?
    var highestAltitude: Double?
    
}

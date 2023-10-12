import Foundation

struct SearchTrackResponse: Decodable {
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case distance
        case averageSlope
        case lowestAltitude
        case highestAltitude
    }

    let id: CLong
    var title: String
    var distance: Double
    
    // 백엔드 서버에서 일정 시각에 batch job으로 업데이트
    var averageSlope: Double?
    var lowestAltitude: Double?
    var highestAltitude: Double?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(CLong.self, forKey: .id)
        self.title = try container.decode(String.self, forKey: .title)
        self.distance = try container.decode(Double.self, forKey: .distance)
        
        self.averageSlope = try container.decodeIfPresent(Double.self, forKey: .averageSlope)
        self.lowestAltitude = try container.decodeIfPresent(Double.self, forKey: .lowestAltitude)
        self.highestAltitude = try container.decodeIfPresent(Double.self, forKey: .highestAltitude)
    }
    
}

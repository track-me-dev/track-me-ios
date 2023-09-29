import Foundation

struct TrackRecordResponse: Decodable {
    
    let content: [TrackRecord]
    let pageable: Pageable
    let size: Int
    let number: Int
    let sort: Sort
    let numberOfElements: Int
    let first: Bool
    let last: Bool
    let empty: Bool
    
    struct Pageable: Decodable {
        let sort: Sort
        let offset: Int
        let pageSize: Int
        let pageNumber: Int
        let paged: Bool
        let unpaged: Bool
    }
    
    struct Sort: Decodable {
        let empty: Bool
        let sorted: Bool
        let unsorted: Bool
    }
}

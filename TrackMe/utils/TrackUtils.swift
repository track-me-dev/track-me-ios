//
//  TrackUtils.swift
//  TrackMe
//
//  Created by 곽진현 on 2023/08/16.
//

import Foundation
import SWXMLHash

class TrackUtils {
    
    static func getCoordinates(urlPath: String) -> [[String:Double]]? {
        
        let gpxString = readGPX(urlPath: urlPath)
        
        do {
            let xml = try XMLHash.parse(gpxString!)
            
            var coordinates = [Dictionary<String, Double>]()
            
            for wpt in xml["gpx"]["wpt"].all {
                if let latitude = Double(wpt.element?.attribute(by: "lat")?.text ?? ""),
                   let longitude = Double(wpt.element?.attribute(by: "lon")?.text ?? "") {
                    let coordinate = ["latitude":latitude, "longitude":longitude]
                    coordinates.append(coordinate)
                }
            }
            
            // Now `coordinates` contains an array of latitude and longitude tuples
            return coordinates
        } catch {
            print("Error parsing GPX data: \(error)")
        }
        return nil
    }
    
    private static func readGPX(urlPath: String) -> String? {
        guard let gpxURL = Bundle.main.url(forResource: urlPath, withExtension: "gpx"),
              let gpxData = try? Data(contentsOf: gpxURL),
              let gpxString = String(data: gpxData, encoding: .utf8) else {
            return nil
        }
        return gpxString
    }
}

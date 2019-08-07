//
//  GPXService.swift
//  GPX
//
//  Created by Adam Tootle on 8/3/19.
//  Copyright © 2019 Adam Tootle. All rights reserved.
//

import Foundation
import MapKit
import SWXMLHash

struct GPXServiceResponse {
    let startDate: Date?
    let endDate: Date?
    let locations: [[CLLocation]]?
    
    func createPolylines() -> [MKPolyline] {
        var polylines: [MKPolyline] = []
        
        if let locations = self.locations {
            for locationsArray in locations {
                var mapPoints: [MKMapPoint] = []
                
                for location in locationsArray {
                    let mapPoint = MKMapPoint(location.coordinate)
                    mapPoints.append(mapPoint)
                }
                
                let polyline = MKPolyline(points: &mapPoints, count: mapPoints.count)
                polylines.append(polyline)
            }
        }
        
        return polylines
    }
}

class GPXService {
    static func processGPX(path: String) -> GPXServiceResponse {
        var locations: [[CLLocation]] = []
        var startDate: Date?
        var endDate: Date?
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        do {
            let contents = try String(contentsOfFile: path)
            let xml = SWXMLHash.parse(contents)
            xml["gpx"]["trk"]["trkseg"].all.forEach { (trkseg) in
                var trackLocations: [CLLocation] = []
                
                trkseg["trkpt"].all.forEach({ (trkpt) in
                    if let latText = trkpt.element?.attribute(by: "lat")?.text,
                        let lonText = trkpt.element?.attribute(by: "lon")?.text,
                        let timeText = trkpt["time"].element?.text,
                        let elevationText = trkpt["ele"].element?.text{
                        let latitude = Double(latText)!
                        let longitude = Double(lonText)!
                        let elevation = Double(elevationText)!
                        let time = dateFormatter.date(from: timeText)!
                        let location = CLLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), altitude: elevation, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: time)
                        trackLocations.append(location)
                        
                        if startDate == nil {
                            startDate = time
                        }
                        
                        endDate = time
                    }
                    
                })
                
                locations.append(trackLocations)
            }
        } catch {
            // contents could not be loaded
        }
        
        return GPXServiceResponse(startDate: startDate, endDate: endDate, locations: locations)
    }
}

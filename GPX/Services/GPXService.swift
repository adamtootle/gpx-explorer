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

class GPXService {
    static func processGPX(path: String) -> (startDate: Date?, endDate: Date?, polylines: [MKPolyline]) {
        var places: [MKMapPoint] = []
        var startDate: Date?
        var endDate: Date?
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        if let filepath = Bundle.main.path(forResource: "track", ofType: "gpx") {
            do {
                let contents = try String(contentsOfFile: path)
                let xml = SWXMLHash.parse(contents)
                xml["gpx"]["trk"]["trkseg"].all.forEach { (trkseg) in
                    trkseg["trkpt"].all.forEach({ (trkpt) in
                        if let latText = trkpt.element?.attribute(by: "lat")?.text,
                            let lonText = trkpt.element?.attribute(by: "lon")?.text,
                            let timeText = trkpt["time"].element?.text {
                            let lat = Double(latText)!
                            let lon = Double(lonText)!
                            places.append(MKMapPoint(CLLocationCoordinate2D(latitude: lat, longitude: lon)))
                            
                            let time = dateFormatter.date(from: timeText)!
                            
                            if startDate == nil {
                                startDate = time
                            }
                            
                            endDate = time
                        }
                        
                    })
                }
            } catch {
                // contents could not be loaded
            }
        } else {
            // example.txt not found!
        }
        
        var locations = places.map { $0.coordinate }
        let polyline = MKPolyline(coordinates: &locations, count: locations.count)
        
        return (startDate: startDate, endDate: endDate, polylines: [polyline])
    }
}

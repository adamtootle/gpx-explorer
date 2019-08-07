//
//  GPXService.swift
//  GPX
//
//  Created by Adam Tootle on 8/3/19.
//  Copyright © 2019 Adam Tootle. All rights reserved.
//

import Foundation
import SWXMLHash
import CoreLocation
import GEOSwift

class GPXServiceResponse {
    var startDate: Date?
    var endDate: Date?
    var locations: [[CLLocation]]
    var northeastCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var southwestCoordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    
    init(startDate: Date?, endDate: Date?, locations: [[CLLocation]]) {
        self.startDate = startDate
        self.endDate = endDate
        self.locations = locations
        
        self.calculateCorners()
    }
    
    func calculateCorners() {
        var envelope: Envelope?
        if let locations = self.locations.first {
            let lineString = try! LineString(points: locations.map{Point(x: $0.coordinate.latitude, y: $0.coordinate.longitude)})
            let geometry = try! (try! lineString.envelope()).buffer(by: 0.001)
            envelope = try! geometry.envelope()
        }
        
        if let envelope = envelope {
            self.northeastCoordinate = CLLocationCoordinate2D(latitude: envelope.maxX, longitude: envelope.maxY)
            self.southwestCoordinate = CLLocationCoordinate2D(latitude: envelope.minX, longitude: envelope.minY)
        }
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

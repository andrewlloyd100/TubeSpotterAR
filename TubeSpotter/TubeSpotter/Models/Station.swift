//
//  Station.swift
//  TubeSpotter
//
//  Created by Andrew Lloyd on 29/03/2022.
//

import CoreLocation
import UIKit

struct TubeStation: Codable {
    let name: String
    private let latitude: String
    private let longitude: String
    
    enum CodingKeys: String, CodingKey {
        case name = "Station"
        case latitude = "Latitude"
        case longitude = "Longitude"
    }
    
    public var location: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: Double(latitude)!, longitude: Double(longitude)!)
    }
}

struct StationLineInfo: Codable {
    let tubeLine: TubeLine
    let from: String
    let to: String
    
    enum CodingKeys: String, CodingKey {
        case tubeLine = "Tube Line"
        case from = "From Station"
        case to = "To Station"
    }
}

enum TrainType: String {
    case tube = "tube"
    case overground = "overground"
    case dlr = "dlr"
    case nationalRail = "national-rail"
}

enum TubeLine: String, Codable {
    case bakerloo = "Bakerloo"
    case c2c = "C2C"
    case central = "Central"
    case chiltern = "Chiltern Railways"
    case circle = "Circle"
    case district = "District"
    case dlr = "DLR"
    case elizabeth = "Elizabeth"
    case greatNorthern = "Great Northern"
    case greatWestern = "Great Western"
    case greaterAnglia = "Greater Anglia"
    case hammersmith = "Hammersmith & City"
    case heathrowConnect = "Heathrow Connect"
    case heathrowExpress = "Heathrow Express"
    case jubilee = "Jubilee"
    case midland = "London Midland"
    case metropolitan = "Metropolitan"
    case northern = "Northern"
    case overground = "London Overground"
    case piccadilly = "Piccadilly"
    case southWestern = "South Western"
    case southEastern = "Southeastern"
    case southern = "Southern"
    case tflRail = "TfL Rail"
    case thameslink = "Thameslink"
    case tramlink = "Tramlink"
    case victoria = "Victoria"
    case waterlooAndCity = "Waterloo & City"
}

extension TubeLine {
    var color: UIColor {
        switch self {
        case .bakerloo:
            return .brown
        case .c2c:
            return .green
        case .central:
            return .red
        case .chiltern:
            return .brown
        case .circle:
            return .yellow
        case .district:
            return .green
        case .dlr:
            return .cyan
        case .elizabeth:
            return .purple
        case .greatNorthern:
            return .black
        case .greatWestern:
            return .black
        case .greaterAnglia:
            return .black
        case .hammersmith:
            return .systemPink
        case .heathrowConnect:
            return .systemTeal
        case .heathrowExpress:
            return .purple
        case .jubilee:
            return .gray
        case .midland:
            return .black
        case .metropolitan:
            return .purple
        case .northern:
            return .black
        case .overground:
            return .orange
        case .piccadilly:
            return .blue
        case .southWestern:
            return .orange
        case .southEastern:
            return .orange
        case .southern:
            return .orange
        case .tflRail:
            return .black
        case .thameslink:
            return .blue
        case .tramlink:
            return .blue
        case .victoria:
            return .blue
        case .waterlooAndCity:
            return .systemTeal
        }
    }
    
    var trainType: TrainType {
        switch self {
        case .bakerloo, .central, .circle, .district, .elizabeth, .hammersmith, .jubilee, .metropolitan, .northern, .piccadilly, .thameslink, .victoria, .waterlooAndCity:
            return .tube
        case .c2c, .chiltern, .greatNorthern, .greatWestern, .greaterAnglia, .heathrowConnect, .heathrowExpress, .midland, .southWestern, .southEastern, .southern, .tflRail, .tramlink:
            return .nationalRail
        case .dlr:
            return .dlr
        case .overground:
            return .overground
        }
    }
}

extension Array where Element == TubeLine {
    var trainTypes: [TrainType] {
        return self.map({ $0.trainType })
    }
}


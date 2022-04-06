//
//  TFLModels.swift
//  TubeSpotter
//
//  Created by Andrew Lloyd on 05/04/2022.
//

import Foundation

struct TFLNetwork: Codable {
    let id: String
    let name: String
    let modeName: String
    let lineStatuses: [LineStatus]
}

struct LineStatus: Codable {
    let statusSeverity: Int
    let statusSeverityDescription: String
    
    var status: Status {
        if statusSeverity > 9 {
            return .good
        }
        else if statusSeverity < 5 {
            return .notRunning
        }
        else {
            return .disrupted
        }
    }
}


enum Status {
    case good
    case disrupted
    case notRunning
}

//
//  ContentFetcher.swift
//  TubeSpotter
//
//  Created by Andrew Lloyd on 05/04/2022.
//

import Foundation

struct ContentFetcher {

    
    enum NetworkError: Error {
        case invalidURL
        case missingData
    }
    
    static func fetchLineStatuses() async throws -> [TFLNetwork] {
        
        let modes = [TrainType.tube.rawValue, TrainType.overground.rawValue, TrainType.dlr.rawValue, TrainType.nationalRail.rawValue]
        let param = modes.joined(separator: ",")
        //TODO - Set TFL API Key here
        guard let url = URL(string: "https://api.tfl.gov.uk/Line/Mode/\(param)/status?app_key=xxxxxxxxx") else {
            throw NetworkError.invalidURL
        }

        // Use the async variant of URLSession to fetch data
        // Code might suspend here
        let (data, _) = try await URLSession.shared.data(from: url)

        // Parse the JSON data
        let results = try JSONDecoder().decode([TFLNetwork].self, from: data)
        return results
    }
    
    static func parseStations() async throws -> [TubeStation] {

        guard let url = Bundle.main.url(forResource: "debugTubeStations", withExtension: "json") else {
            throw NetworkError.invalidURL
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let jsonData = try decoder.decode([TubeStation].self, from: data)
        return jsonData
    }
    
    static func parseLineInfo() async throws -> [StationLineInfo] {
        guard let url = Bundle.main.url(forResource: "stationLineInfo", withExtension: "json") else {
            throw NetworkError.invalidURL
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        let jsonData = try decoder.decode([StationLineInfo].self, from: data)
        return jsonData
    }
    
}

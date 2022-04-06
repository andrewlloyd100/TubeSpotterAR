//
//  ViewController+Alert.swift
//  TubeSpotter
//
//  Created by Andrew Lloyd on 01/04/2022.
//

import UIKit
import ARKit

extension ViewController {
    func alertUser(withTitle title: String, message: String, actions: [UIAlertAction]? = nil) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            if let actions = actions {
                actions.forEach { alert.addAction($0) }
            } else {
                alert.addAction(UIAlertAction(title: "OK", style: .default))
            }
            self.present(alert, animated: true)
        }
    }
}

extension ARGeoTrackingStatus.StateReason {
    var description: String {
        switch self {
        case .none: return "None"
        case .notAvailableAtLocation: return "Geotracking is unavailable here. Please return to your previous location to continue"
        case .needLocationPermissions: return "App needs location permissions"
        case .worldTrackingUnstable: return "Limited tracking"
        case .geoDataNotLoaded: return "Downloading localization imagery. Please wait"
        case .devicePointedTooLow: return "Point the camera at a nearby building"
        case .visualLocalizationFailed: return "Point the camera at a building unobstructed by trees or other objects"
        case .waitingForLocation: return "ARKit is waiting for the system to provide a precise coordinate for the user"
        case .waitingForAvailabilityCheck: return "ARKit is checking Location Anchor availability at your locaiton"
        @unknown default: return "Unknown reason"
        }
    }
}

extension ARGeoTrackingStatus.Accuracy {
    var description: String {
        switch self {
        case .undetermined: return "Undetermined"
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        @unknown default: return "Unknown"
        }
    }
}

extension ARCamera.TrackingState.Reason {
    var description: String {
        switch self {
        case .initializing: return "Initializing"
        case .excessiveMotion: return "Too much motion"
        case .insufficientFeatures: return "Insufficient features"
        case .relocalizing: return "Relocalizing"
        @unknown default: return "Unknown"
        }
    }
}

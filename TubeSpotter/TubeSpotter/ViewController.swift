//
//  ViewController.swift
//  TubeSpotter
//
//  Created by Andrew Lloyd on 15/03/2022.
//

import UIKit
import RealityKit
import ARKit
import CoreLocation
import Combine

class ViewController: UIViewController, ARSessionDelegate {
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet var arView: ARView!
    let coachingOverlay = ARCoachingOverlayView()
    
    var allStations: [TubeStation] = []
    var lineInfo: [StationLineInfo] = []
    var lineStatuses: [TFLNetwork] = []
    
    var closeStations: [TubeStation] = []
    
    private var cancellables = Set<AnyCancellable>()
    let locationManager = CLLocationManager()
    var lastResetLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spinner.startAnimating()
        setupContent()
    }
    
    //MARK: - Location
    func setupLocation() {
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()

        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()

        DispatchQueue.global().async {
            if CLLocationManager.locationServicesEnabled() {
                self.locationManager.delegate = self
                self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
                self.locationManager.startUpdatingLocation()
            }
        }
    }
    
    //MARK: - Station Fetching
    private func setupContent() {
        // Start an async task
        Task {
            do {
                self.lineStatuses = try await ContentFetcher.fetchLineStatuses()
                self.allStations = try await ContentFetcher.parseStations()
                self.lineInfo = try await ContentFetcher.parseLineInfo()
                self.startSession()
            } catch {
                print("Content fetch failed with error: \(error)")
                let retry = UIAlertAction(title: "Retry", style: .default) { (_) in
                    self.setupContent()
                }
                self.alertUser(withTitle: "Content unavailable",
                               message: "Content fetch failed with error: \(error)",
                               actions: [retry])
            }
        }
    }
    
    private func startSession() {
        spinner.stopAnimating()
        spinner.isHidden = true
        arView.isHidden = false
        
        // Set this view controller as the session's delegate.
        arView.session.delegate = self
        
        setupCoachingOverlay()
        setupLocation()
        restartSession()

        //rotate stations to look at camera
        arView.scene.subscribe(to: SceneEvents.Update.self) { [self] _ in
            for anchor in self.arView.scene.anchors {
                if let entity = anchor as? AnchorEntity {
                    entity.billboard(targetPosition: arView.cameraTransform.translation)
                }
            }
        }.store(in: &cancellables)
    }
    
    private func tubeLinesForStation(name: String) -> [PlacemarkLineInfo] {
        let array = lineInfo
                    .filter({ $0.from == name })
                    .map({ $0.tubeLine })
        let tubeLines = Array(Set(array))
        var result: [PlacemarkLineInfo] = []
        for line in tubeLines {
            let status = lineStatuses.first(where: { $0.id == line.rawValue.lowercased().replacingOccurrences(of: " & ", with: "-")
                                                                                        .replacingOccurrences(of: " ", with: "-")
            })
            result.append(PlacemarkLineInfo(tubeLine: line,
                                            status: status?.lineStatuses.first))
        }
        return result
    }
    
    func restartSession() {
        // Check geo-tracking location-based availability.
        ARGeoTrackingConfiguration.checkAvailability { (available, error) in
            print("Geo Available: \(available)")
            if !available {
                let errorDescription = error?.localizedDescription ?? ""
                let recommendation = "Please try again in an area where geotracking is supported."
                let restartSession = UIAlertAction(title: "Restart Session", style: .default) { (_) in
                    self.restartSession()
                }
                self.alertUser(withTitle: "Geotracking unavailable",
                               message: "\(errorDescription)\n\(recommendation)",
                               actions: [restartSession])
            }
        }
        
        // Re-run the ARKit session.
        let geoTrackingConfig = ARGeoTrackingConfiguration()
        geoTrackingConfig.planeDetection = [.horizontal]
        arView.session.run(geoTrackingConfig)
        arView.scene.anchors.removeAll()
    }
    
    func addARBuildingTags() {
        arView.scene.anchors.removeAll()
        for station in closeStations {
            addGeoAnchor(at: station.location, name: station.name)
        }
    }
    
    var isGeoTrackingLocalized: Bool {
        if let status = arView.session.currentFrame?.geoTrackingStatus, status.state == .localized {
            return true
        }
        return false
    }
    
    func addGeoAnchor(at location: CLLocationCoordinate2D, name: String, altitude: CLLocationDistance? = nil) {
        //dont bother adding the same anchor if it already exists
        guard arView.scene.anchors.filter({ $0.name == name }).isEmpty else { return }
        
        var geoAnchor: ARGeoAnchor!
        if let altitude = altitude {
            geoAnchor = ARGeoAnchor(name: name, coordinate: location, altitude: altitude)
        } else {
            geoAnchor = ARGeoAnchor(name: name, coordinate: location)
        }
        
        addGeoAnchor(geoAnchor)
    }
    
    func addGeoAnchor(_ geoAnchor: ARGeoAnchor) {
        
        // Don't add a geo anchor if Core Location isn't sure yet where the user is.
        guard isGeoTrackingLocalized else {
            alertUser(withTitle: "Cannot add geo anchor", message: "Unable to add geo anchor because geotracking has not yet localized.")
            return
        }
        arView.session.add(anchor: geoAnchor)
    }
    
    // MARK: - ARSessionDelegate
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        for geoAnchor in anchors.compactMap({ $0 as? ARGeoAnchor }) {
            let lines = tubeLinesForStation(name: geoAnchor.name ?? "")
            let entity = Entity.placemarkEntity(for: geoAnchor, tubeLines: lines)
            self.arView.scene.addAnchor(entity)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        DispatchQueue.main.async {
            // Present an alert informing about the error that has occurred.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                self.restartSession()
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    /// - Tag: GeoTrackingStatus
    func session(_ session: ARSession, didChange geoTrackingStatus: ARGeoTrackingStatus) {
        
        var text = ""
        // In localized state, show geotracking accuracy
        if geoTrackingStatus.state == .localized {
            addARBuildingTags()
            text += "Accuracy: \(geoTrackingStatus.accuracy.description)"
        } else {
            // Otherwise show details why geotracking couldn't localize (yet)
            switch geoTrackingStatus.stateReason {
            case .none:
                break
            case .worldTrackingUnstable:
                let arTrackingState = session.currentFrame?.camera.trackingState
                if case let .limited(arTrackingStateReason) = arTrackingState {
                    text += "\n\(geoTrackingStatus.stateReason.description): \(arTrackingStateReason.description)."
                } else {
                    fallthrough
                }
            default: text += "\n\(geoTrackingStatus.stateReason.description)."
            }
        }
        print(text)
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        print("locations = \(locValue.latitude) \(locValue.longitude)")
        
        guard isGeoTrackingLocalized else { return }
        if let currentLocation = manager.location {
            //only reset tags if we've moved more than 30 meters
            if let lastLocation = lastResetLocation {
                if currentLocation.distance(from: lastLocation) < 30 {
                    return
                }
            }
            lastResetLocation = currentLocation
            closeStations.removeAll()
            for station in allStations {
                if currentLocation.distance(from: CLLocation(latitude: station.location.latitude,
                                                             longitude: station.location.longitude)) < 800 {
                    closeStations.append(station)
                }
            }
        }
        addARBuildingTags()
    }
}

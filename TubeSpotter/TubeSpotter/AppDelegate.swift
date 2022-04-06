//
//  AppDelegate.swift
//  TubeSpotter
//
//  Created by Andrew Lloyd on 15/03/2022.
//

import UIKit
import ARKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        /* Check whether the device supports geotracking. Present
         an error-message view controller, if not. */
        if !ARGeoTrackingConfiguration.isSupported {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            window?.rootViewController = storyboard.instantiateViewController(withIdentifier: "unsupportedDeviceMessage")
        }
        return true
    }

}


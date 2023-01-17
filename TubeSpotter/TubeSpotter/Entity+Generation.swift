//
//  Entity+Generation.swift
//  TubeSpotter
//
//  Created by Andrew Lloyd on 01/04/2022.
//

import ARKit
import RealityKit
import Combine

extension Entity {
    /// Billboards the entity to the targetPosition which should be provided in world space.
    func billboard(targetPosition: SIMD3<Float>) {
        look(at: targetPosition, from: position(relativeTo: nil), relativeTo: nil)
    }
}

struct PlacemarkLineInfo {
    let tubeLine: TubeLine
    let status: LineStatus?
}

extension Entity {
    
    static func placemarkEntity(for arAnchor: ARAnchor) -> AnchorEntity {
        
        let placemarkAnchor = AnchorEntity(anchor: arAnchor)
        let indicator = generateNameIndicator(text: arAnchor.name ?? "Untitled")
        placemarkAnchor.addChild(indicator)
        
        //30 meters from the ground
        indicator.setPosition(SIMD3<Float>(0, 30, 0),
                              relativeTo: placemarkAnchor)
        
        //rotate to face where I want
        let radians = 90.0 * Float.pi / 2
        let orientation = simd_quatf.init(angle: radians, axis: SIMD3<Float>(0, 1, 0))
        indicator.setOrientation(orientation, relativeTo: placemarkAnchor)
        
        return placemarkAnchor
    }
    
    
    static func placemarkEntity(for arAnchor: ARAnchor,
                                tubeLines: [PlacemarkLineInfo]) -> AnchorEntity {
        
        let meterSpacing:Float = 7
        let placemarkAnchor = AnchorEntity(anchor: arAnchor)
        let topHeightFromGround: Float = 15 + (meterSpacing * Float(tubeLines.count))
        var currentHeight = topHeightFromGround

        let indicator = generateNameIndicator(text: arAnchor.name ?? "Untitled")
        placemarkAnchor.addChild(indicator)
        indicator.setPosition(SIMD3<Float>(0, currentHeight, 0),
                              relativeTo: placemarkAnchor)
        currentHeight -= meterSpacing
        
        //rotate
        let radians = 90.0 * Float.pi / 2
        let orientation = simd_quatf.init(angle: radians, axis: SIMD3<Float>(0, 1, 0))
        indicator.setOrientation(orientation, relativeTo: placemarkAnchor)
        

        for line in tubeLines {
            switch line.tubeLine.trainType {
            case .tube:
                if let logoEntity = try! UndergroundLogo.loadScene().findEntity(named: "logo") {
                    placemarkAnchor.addChild(logoEntity)
                    logoEntity.setPosition(SIMD3<Float>(0, currentHeight - 1, 0),
                                          relativeTo: placemarkAnchor)
                }
            case .overground:
                if let logoEntity = try! OvergroundLogo.loadScene().findEntity(named: "logo") {
                    placemarkAnchor.addChild(logoEntity)
                    logoEntity.setPosition(SIMD3<Float>(0, currentHeight - 1, 0),
                                          relativeTo: placemarkAnchor)
                }
            case .nationalRail:
                if let logoEntity = try! NationalRailLogo.loadScene().findEntity(named: "logo") {
                    placemarkAnchor.addChild(logoEntity)
                    logoEntity.setPosition(SIMD3<Float>(0, currentHeight - 1, 0),
                                          relativeTo: placemarkAnchor)
                }
            case .dlr:
                if let logoEntity = try! DLRLogo.loadScene().findEntity(named: "logo") {
                    placemarkAnchor.addChild(logoEntity)
                    logoEntity.setPosition(SIMD3<Float>(0, currentHeight - 1, 0),
                                          relativeTo: placemarkAnchor)
                }
            }
            let lineIndicator = generateLineIndicator(line: line.tubeLine)
            placemarkAnchor.addChild(lineIndicator)
            lineIndicator.setPosition(SIMD3<Float>(-3, currentHeight, 0),
                                      relativeTo: placemarkAnchor)
            lineIndicator.setOrientation(orientation, relativeTo: placemarkAnchor)
            
            if let status = line.status {
                switch status.status {
                case.good:
                    if let logoEntity = try! Check.loadScene().findEntity(named: "logo") {
                        placemarkAnchor.addChild(logoEntity)
                        logoEntity.setPosition(SIMD3<Float>(-4, currentHeight - 2, 0),
                                              relativeTo: placemarkAnchor)
                    }
                case .disrupted:
                    if let logoEntity = try! Warning.loadScene().findEntity(named: "logo") {
                        placemarkAnchor.addChild(logoEntity)
                        logoEntity.setPosition(SIMD3<Float>(-4, currentHeight - 2, 0),
                                              relativeTo: placemarkAnchor)
                    }
                case .notRunning:
                    if let logoEntity = try! Cross.loadScene().findEntity(named: "logo") {
                        placemarkAnchor.addChild(logoEntity)
                        logoEntity.setPosition(SIMD3<Float>(-4, currentHeight - 2, 0),
                                              relativeTo: placemarkAnchor)
                    }
                }
                let lineIndicator = generateStatusIndicator(status: status)
                placemarkAnchor.addChild(lineIndicator)
                lineIndicator.setPosition(SIMD3<Float>(-5, currentHeight - 1.5, 0),
                                          relativeTo: placemarkAnchor)
                lineIndicator.setOrientation(orientation, relativeTo: placemarkAnchor)
            }
            
            currentHeight -= meterSpacing
        }

        return placemarkAnchor
    }
    
    static func generateSphereIndicator(radius: Float) -> Entity {
        let indicatorEntity = Entity()

        let innerSphere = ModelEntity.blueSphere.clone(recursive: true)
        indicatorEntity.addChild(innerSphere)
        let outerSphere = ModelEntity.transparentSphere.clone(recursive: true)
        indicatorEntity.addChild(outerSphere)

        return indicatorEntity
    }
    
    static func generateNameIndicator(text: String) -> Entity {
        let indicatorEntity = Entity()

        let text = ModelEntity.stationNameText(text.uppercased()).clone(recursive: true)
        indicatorEntity.addChild(text)
        
        return indicatorEntity
    }
    
    static func generateLineIndicator(line: TubeLine) -> Entity {
        let indicatorEntity = Entity()

        let text = ModelEntity.lineNameText(line.rawValue,
                                            color: line.color).clone(recursive: true)
        indicatorEntity.addChild(text)
        
        return indicatorEntity
    }
    
    static func generateStatusIndicator(status: LineStatus) -> Entity {
        let indicatorEntity = Entity()

        var color: UIColor = .green
        switch status.status {
        case .good:
            color = #colorLiteral(red: 0, green: 0.4706119895, blue: 0.2078071833, alpha: 1)
        case .disrupted:
            color = .orange
        case .notRunning:
            color = .red
        }
        let text = ModelEntity.statusNameText(status.statusSeverityDescription,
                                            color: color).clone(recursive: true)
        indicatorEntity.addChild(text)
        
        return indicatorEntity
    }
    
    static func loadEntityAsync(anchor: AnchorEntity) {
      // Load the asset asynchronously
      var cancellable: AnyCancellable? = nil
      cancellable = Entity.loadModelAsync(named: "LondonMap")
        .sink(receiveCompletion: { error in
          print("Unexpected error: \(error)")
          cancellable?.cancel()
        }, receiveValue: { entity in
          anchor.addChild(entity)
          cancellable?.cancel()
        })
    }
    
    func move(by translation: SIMD3<Float>, scale: SIMD3<Float>, after delay: TimeInterval, duration: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            var transform: Transform = .identity
            transform.translation = self.transform.translation + translation
            transform.scale = self.transform.scale * scale
            self.move(to: transform, relativeTo: self.parent, duration: duration, timingFunction: .easeInOut)
        }
    }
}

extension ModelEntity {
    static let blueSphere = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.7), materials: [UnlitMaterial(color: #colorLiteral(red: 0.2196078449, green: 0.007843137719, blue: 0.8549019694, alpha: 1))])
    static let redSphere = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.7), materials: [UnlitMaterial(color: #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1))])
    static let transparentSphere = ModelEntity(
        mesh: MeshResource.generateSphere(radius: 0.1),
        materials: [SimpleMaterial(color: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.25), roughness: 0.3, isMetallic: true)])
    static let blueShape = ModelEntity(
        mesh: MeshResource.generateBox(width: 1500, height: 500, depth: 500, cornerRadius: 2, splitFaces: false),
        materials:  [UnlitMaterial(color: #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1))])
    
    static func stationNameText(_ text: String) -> ModelEntity {
        ModelEntity(mesh: MeshResource.generateText(text,
                                                    extrusionDepth: 0.2,
                                                    font: .boldSystemFont(ofSize: 4),
                                                    containerFrame: CGRect.zero,
                                                    alignment: .center,
                                                    lineBreakMode: .byCharWrapping),
                    materials: [UnlitMaterial(color: #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1))])
    }
    
    static func lineNameText(_ text: String, color: UIColor) -> ModelEntity {
        ModelEntity(mesh: MeshResource.generateText(text,
                                                    extrusionDepth: 0.2,
                                                    font: .systemFont(ofSize: 2),
                                                    containerFrame: CGRect.zero,
                                                    alignment: .center,
                                                    lineBreakMode: .byCharWrapping),
                    materials: [UnlitMaterial(color: color)])
    }
    
    static func statusNameText(_ text: String, color: UIColor) -> ModelEntity {
        ModelEntity(mesh: MeshResource.generateText(text,
                                                    extrusionDepth: 0.2,
                                                    font: .systemFont(ofSize: 1),
                                                    containerFrame: CGRect.zero,
                                                    alignment: .center,
                                                    lineBreakMode: .byCharWrapping),
                    materials: [UnlitMaterial(color: color)])
    }
}

//
//  ARMapView.swift
//  GPX
//
//  Created by Adam Tootle on 8/4/19.
//  Copyright © 2019 Adam Tootle. All rights reserved.
//

import UIKit
import Mapbox
import SceneKit
import ARKit

import MapKit
import MapboxSceneKit

class ARMapView: UIView, ARSCNViewDelegate, ARSessionDelegate {
    var minLat = 0.0
    var minLon = 0.0
    var maxLat = 0.0
    var maxLon = 0.0
    
    @IBOutlet weak var sceneView: ARSCNView!
    
    var scene: SCNScene = SCNScene()
    
    var terrainNode: TerrainNode?
    var terrainNodeScale = SCNVector3(0.0003, 0.0003, 0.0003)
    
    var trackpoints:[CLLocationCoordinate2D]?
    let cameraNode = SCNNode()
    
    func renderScene(northeastCoordinate: CLLocationCoordinate2D, southwestCoordinate: CLLocationCoordinate2D, gpxResponse: GPXServiceResponse) {
        self.maxLat = northeastCoordinate.latitude
        self.maxLon = northeastCoordinate.longitude
        
        self.minLat = southwestCoordinate.latitude
        self.minLon = southwestCoordinate.longitude
        
        // Start the view's AR session with a configuration that uses the rear camera,
        // device position and orientation tracking, and plane detection.
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)
        
        // Set a delegate to track the number of plane anchors for providing UI feedback.
        sceneView.session.delegate = self
        sceneView.delegate = self
        
        // Prevent the screen from being dimmed after a while as users will likely
        // have long periods of interaction without touching the screen or buttons.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Show debug UI to view performance metrics (e.g. frames per second).
//        sceneView.showsStatistics = true
        
        setupSceneView()
        createTerrain {
            if let locations = gpxResponse.locations {
                for locationsArray in locations {
                    self.terrainNode?.addPolyline(coordinates: locationsArray, radius: 5.0, color: .red)
                }
            }
        }
    }
    
    func setupSceneView(){
        let lightNode = SCNNode()
        let light = SCNLight()
        light.type = .ambient
        light.intensity = 10
        lightNode.light = light
//        self.sceneView.scene.rootNode.addChildNode(lightNode)
    }
    
    func createTerrain(completionHandler: @escaping () -> Void) {
        terrainNode = TerrainNode(minLat: minLat, maxLat: maxLat,
                                  minLon: minLon, maxLon: maxLon)
        if let terrainNode = terrainNode {
            terrainNode.scale = terrainNodeScale // Scale down map
            terrainNode.geometry?.materials = defaultMaterials()
            self.sceneView.scene.rootNode.addChildNode(terrainNode)
            
            terrainNode.position = SCNVector3(0, 0, 0)
            
            let finishLoadingTerrainAndTexture: (UIImage) -> Void = { image in
                terrainNode.geometry?.materials[4].diffuse.contents = image
                
                completionHandler()
            };
            
            terrainNode.fetchTerrainAndTexture(
                minWallHeight: 10.0,
                multiplier: 1.0,
                enableDynamicShadows: true,
                textureStyle: "adamtootle/cjyzd3ygk0c491cmo0309nr1p",
                heightProgress: nil,
                heightCompletion: { (error) in
                    
                },
                textureProgress: { (progress, total) in
                    print("textureProgress \(progress) \(total)")
                },
                textureCompletion: { (textureImage, error) in
                    if let textureImage = textureImage {
                        finishLoadingTerrainAndTexture(textureImage)
                    }
                })
        }
    }
    
    // Create default materials for each side of the terrain node
    func defaultMaterials() -> [SCNMaterial] {
        let groundImage = SCNMaterial()
        groundImage.diffuse.contents = UIColor.darkGray
        groundImage.name = "Ground texture"
        
        let sideMaterial = SCNMaterial()
        sideMaterial.diffuse.contents = UIColor.darkGray
        sideMaterial.isDoubleSided = true
        sideMaterial.name = "Side"
        
        let bottomMaterial = SCNMaterial()
        bottomMaterial.diffuse.contents = UIColor.black
        bottomMaterial.name = "Bottom"
        
        return [sideMaterial, sideMaterial, sideMaterial, sideMaterial, groundImage, bottomMaterial]
    }
}

// MARK: ARSessionDelegate

extension ARMapView {
    /// - Tag: PlaceARContent
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
    }
    
    /// - Tag: UpdateARContent
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
    }
    
    // MARK: - ARSessionObserver
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required.
        resetTracking()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Remove optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            // Present an alert informing about the error that has occurred.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                self.resetTracking()
            }
            alertController.addAction(restartAction)
//            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Private methods
    private func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        sceneView.debugOptions = [.showFeaturePoints]
    }
}

//
//  ViewController.swift
//  ARKit Test
//
//  Created by Warren Hansen on 8/4/21.
//

import UIKit
import RealityKit
import Firebase
import ARKit

class ViewController: UIViewController, ARSessionDelegate, ARSCNViewDelegate {
    
  
    @IBOutlet var sceneView: ARSCNView!
    
    let email = "whansen1@mac.com"
    let password = "123456"
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signIn()
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // AR experiences typically involve moving the device without
        // touch input for some time, so prevent auto screen dimming.
        UIApplication.shared.isIdleTimerDisabled = true
        
        // "Reset" to run the AR session for the first time.
        resetTracking()
    }
    
    /// - Tag: ARFaceTrackingSetup
    func resetTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        if #available(iOS 13.0, *) {
            configuration.maximumNumberOfTrackedFaces = ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces
        }
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
    }
    
    // Auto-hide the home indicator to maximize immersion in AR experiences.
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    // Hide the status bar to maximize immersion in AR experiences.
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func createNewUser() {
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("we had an error creating a user \(error)")
            }
            print("new user set")
        }
    }
    
    func signIn() {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
          guard let strongSelf = self else { return }
            print(authResult)
            print("Strong self signed in: \(strongSelf.email)")
        }
    }
}

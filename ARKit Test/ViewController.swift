//
//  ViewController.swift
//  ARKit Test
//
//  Created by Warren Hansen on 8/4/21.
//

import UIKit
import RealityKit
import Firebase

class ViewController: UIViewController {
    
    @IBOutlet var arView: ARView!
    
    let email = "whansen1@mac.com"
    let password = "123456"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signIn()
        // Load the "Box" scene from the "Experience" Reality File
        let boxAnchor = try! Experience.loadBox()
        
        // Add the box anchor to the scene
        arView.scene.anchors.append(boxAnchor)
        
        
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

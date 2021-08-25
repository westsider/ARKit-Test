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
import CoreMotion



class AlignViewController: UIViewController, ARSessionDelegate  {
            
    @IBOutlet weak var arView: ARView!
    
    let email = "whansen1@mac.com"
    let password = "123456"
    var analysis = ""
    var guides: Experience.Guides!
    let segueName = "profileSegue"
    var selectedImage: UIImage?
    var dot: Dot?
    
    // code created ARView
    // MARK: - TODO -use ar view to dosplay face mesh
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        signIn()
        guard ARFaceTrackingConfiguration.isSupported else { fatalError() }
        arView.session.delegate = self
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = true
        let configuration = ARFaceTrackingConfiguration()
        
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        // set up guides
        let arAnchor = try! Experience.loadGuides()
        arView.scene.anchors.append(arAnchor)
        guides = arAnchor
        
        // add circle for center
        let width = view.frame.width * 0.50
        let height = width * 1.4
        let frame = CGRect(x: 0, y: 0, width: width, height: height)
        let crosshairDrawing = Dot(frame: frame)
        crosshairDrawing.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(crosshairDrawing)
        crosshairDrawing.center = CGPoint(x: view.frame.size.width  / 2,
                                   y: view.frame.size.height / 2)
        
    }
    

    override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
        arView.session.pause()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let image = selectedImage else { return }
        if let target = segue.destination as? ProfileViewController {
            target.selectedImage = selectedImage
        }
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

extension AlignViewController {
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        
        guard guides != nil else { return }
        
        let arFrame = session.currentFrame!
        if arFrame.anchors.count < 1 { return }
        guard let faceAnchor = arFrame.anchors[0] as? ARFaceAnchor else { return }
        
        let projectionMatrix = arFrame.camera.projectionMatrix(for: .portrait, viewportSize: arView.bounds.size, zNear: 0.001, zFar: 1000)
        let viewMatrix = arFrame.camera.viewMatrix(for: .portrait)

        let projectionViewMatrix = simd_mul(projectionMatrix, viewMatrix)
        let modelMatrix = faceAnchor.transform
        let mvpMatrix = simd_mul(projectionViewMatrix, modelMatrix)

        // This allows me to just get a .x .y .z rotation from the matrix, without having to do crazy calculations
        let newFaceMatrix = SCNMatrix4.init(mvpMatrix)
        let faceNode = SCNNode()
        faceNode.transform = newFaceMatrix
        let rotation = vector_float3(faceNode.worldOrientation.x, faceNode.worldOrientation.y, faceNode.worldOrientation.z)

        let yaw = -rotation.y*3
        let pitch = -rotation.x*3
        let roll = rotation.z*1.5

        let yawS = String(format: "%.2f", -rotation.y*3 )
        let pitchS = String(format: "%.2f", -rotation.x*3  )
        let rollS =  String(format: "%.2f", rotation.z*1.5 )

        var pan = false
        var tilt = false
        var rolly = false

        if pitch > -0.02 && pitch < 0.02 {
            tilt = true
        } else { tilt = false }

        if yaw > -0.12 && yaw < -0.0 {
            pan = true
        } else { pan = false }

        if roll > -0.06 && roll < 0.06 {
            rolly = true
        } else { rolly = false }

        if pan && tilt && rolly {
            print("LOCKED")
            _ = TextHelp.makeText(textAnchor: guides, message: "LOCKED")
            captureImage()
        } else {
            let message =  String("\(pan ? "" : "yaw \(yawS)") \(tilt ? "" : "\npitch \(pitchS)") \(rolly ? "" : "\nroll \(rollS)")")
            print(message)
            _ = TextHelp.makeText(textAnchor: guides, message: message)
        }
        
    }
    
    func captureImage() {
        if let pixelBuffer = arView.session.currentFrame?.capturedImage {
            arView.session.pause()
            let image = UIImage(ciImage: CIImage(cvPixelBuffer: pixelBuffer))
            self.selectedImage = image
            self.performSegue(withIdentifier: self.segueName, sender: nil)
        }
    }
}

class TextHelp {
    static func makeText(textAnchor: Experience.Guides, message: String) -> Experience.Guides? {
        print(message)
        let textEntity: Entity =  (textAnchor.infoSign?.children[0].children[0])!
        var textModelComponent: ModelComponent = (textEntity.components[ModelComponent])!
        guard let myFont = UIFont(name: "Helvetica-Light", size: 0.05) else { return nil }
        
        textModelComponent.mesh = .generateText(message,
                                                extrusionDepth: 0.0,
                                                font: myFont,
                                                containerFrame: CGRect.zero,
                                                alignment: .center,
                                                lineBreakMode: .byCharWrapping)
        textAnchor.infoSign?.children[0].children[0].components.set(textModelComponent)
        return textAnchor
    }
    
    
    static func getDegrees() -> String {
        let manager = CMMotionManager()
        var angle = "NA"
        if manager.isDeviceMotionAvailable {
            manager.deviceMotionUpdateInterval = 0.01
            manager.startDeviceMotionUpdates(to: OperationQueue.main) {
                (data, error) in
                if let data = data {
                    let rotation = atan2(data.gravity.x, data.gravity.y) - .pi
                    let rotS = String(rotation)
                    angle =  rotS
                }
            }
        }
        return angle
    }
}

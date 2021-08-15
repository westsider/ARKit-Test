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



class ViewController: UIViewController, ARSessionDelegate  {
            
    @IBOutlet weak var arView: ARView!
    
    let email = "whansen1@mac.com"
    let password = "123456"
    var analysis = ""
    var guides: Experience.Guides!
    
    
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
    
//    internal func drawRingFittingInsideView(rect: CGRect) -> CAShapeLayer {
//        let desiredLineWidth:CGFloat = 4    // Your desired value
//        let hw:CGFloat = desiredLineWidth/2
//        
//        let circlePath = UIBezierPath(ovalIn: rect.insetBy(dx: hw,dy: hw))
//        let shapeLayer = CAShapeLayer()
//        shapeLayer.path = circlePath.cgPath
//        shapeLayer.fillColor = UIColor.clear.cgColor
//        shapeLayer.strokeColor = UIColor.red.cgColor
//        shapeLayer.lineWidth = desiredLineWidth
//        return shapeLayer
//    }
}

extension ViewController {
    
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
        } else {
            let message =  String("\(pan ? "" : "yaw \(yawS)") \(tilt ? "" : "\npitch \(pitchS)") \(rolly ? "" : "\nroll \(rollS)")")
            print(message)
            _ = TextHelp.makeText(textAnchor: guides, message: message)
        }
        
    }
    // display face mesh
//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//
//        let faceMesh = ARSCNFaceGeometry(device: arView.)
//        let node = SCNNode(geometry: faceMesh)
//        node.geometry?.firstMaterial?.fillMode = .lines
//        node.geometry?.firstMaterial?.diffuse.contents = UIColor.lightGray
//        node.opacity = 0.5
//
//        //node.addChildNode(arAnchor)
//
//        return node
//    }
//    
//    // update face mesh
//    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        if let faceAnchor = anchor as? ARFaceAnchor, let faceGeometry = node.geometry as? ARSCNFaceGeometry {
//            faceGeometry.update(from: faceAnchor.geometry)
//            expression(anchor: faceAnchor)
//        }
//    }
//    
//    // read facial input
//    func expression(anchor: ARFaceAnchor) {
//        // 1
//        let smileLeft = anchor.blendShapes[.mouthSmileLeft]
//        let smileRight = anchor.blendShapes[.mouthSmileRight]
//        let cheekPuff = anchor.blendShapes[.cheekPuff]
//        let tongue = anchor.blendShapes[.tongueOut]
//        self.analysis = ""
//     
//        // 2
//        if ((smileLeft?.decimalValue ?? 0.0) + (smileRight?.decimalValue ?? 0.0)) > 0.9 {
//            self.analysis += "You are smiling. "
//        }
//     
//        if cheekPuff?.decimalValue ?? 0.0 > 0.1 {
//            self.analysis += "Your cheeks are puffed. "
//        }
//     
//        if tongue?.decimalValue ?? 0.0 > 0.1 {
//            self.analysis += "Don't stick your tongue out! "
//        }
//        print(analysis)
//    }
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

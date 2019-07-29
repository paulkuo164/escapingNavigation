/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import ARKit
import SceneKit
import UIKit
import CoreLocation

class ViewController: UIViewController,CLLocationManagerDelegate {
    
    // MARK: IBOutlets
    
    @IBOutlet var sceneView: VirtualObjectARView!
    
    @IBOutlet weak var skView: SKView!
    @IBOutlet weak var addObjectButton: UIButton!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!

    // MARK: - UI Elements
    var lm:CLLocationManager!
    var focusSquare = FocusSquare()
    var exitPath = ExitPath()
    var modelScene = SKScene()
    let startNode = SKShapeNode(circleOfRadius: 3)
    var faceAngle = CLLocationDirection()   //獲取設備的方向
    let locationManager = CLLocationManager()
    var isPathPlaced = false
    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return childViewControllers.lazy.flatMap({ $0 as? StatusViewController }).first!
    }()
    
    // MARK: - ARKit Configuration Properties
    
    
    /// A type which manages gesture manipulation of virtual content in the scene.
    lazy var virtualObjectInteraction = VirtualObjectInteraction(sceneView: sceneView)
    
    /// Coordinates the loading and unloading of reference nodes for virtual objects.
    let virtualObjectLoader = VirtualObjectLoader()
    
    /// Marks if the AR experience is available for restart.
    var isRestartAvailable = true
    
    /// A serial queue used to coordinate adding or removing nodes from the scene.
    let updateQueue = DispatchQueue(label: "escaping navigation")
    
    var screenCenter: CGPoint {
        let bounds = sceneView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        //sceneView.session.configuration?.worldAlignment = ARConfiguration.WorldAlignment.gravityAndHeading
        return sceneView.session
    }
    
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Set up exitPath
        exitPath.read()
        let obstacleNodes = exitPath.buildModel()
       
        obstacleNodes.forEach{node in                     //將回傳的SKShapeNode加到modelScene
            modelScene.addChild(node)
        }
        
        modelScene.anchorPoint = CGPoint(x: 0.75, y: 0.3)
        modelScene.size = CGSize(width: 250, height: 100) //螢幕右上方的小地圖（長寬）
        modelScene.backgroundColor = UIColor.white //螢幕右上方的小地圖(背景)
        //skView.alpha = 0.5
        skView.presentScene(modelScene)        //螢幕右上方的小地圖
        
        //Set up location manager for beacons
        if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self){  //先判斷硬體是否支援接收iBeacon訊號，若支援的話，則要求使用者使用GPS。
            if CLLocationManager.authorizationStatus() != CLAuthorizationStatus.authorizedAlways{
                locationManager.requestAlwaysAuthorization()
            }
        }
          locationManager.delegate = self;
        exitPath.startBeaconMonitoring(regions: exitPath.regionList, isMonitor: true, locationManager: locationManager)
        
        //Set up location manager for phone heading
        lm = CLLocationManager()
        lm.delegate = self
        lm.startUpdatingHeading()
        
       let timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(fire), userInfo: nil, repeats: true)
        
    
      //  sceneView.delegate = self   //出現anchor
        //sceneView.session.delegate = self
        // Set up scene content.
        //setupCamera()
        
      //  sceneView.scene.rootNode.addChildNode(focusSquare)
            /*
    
         The `sceneView.automaticallyUpdatesLighting` option creates an
         ambient light source and modulates its intensity. This sample app
         instead modulates a global lighting environment map for use with
         physically based materials, so disable automatic lighting.
 
        sceneView.automaticallyUpdatesLighting = false
        if let environmentMap = UIImage(named: "Models.scnassets/sharedImages/environment_blur.exr") {
            sceneView.scene.lightingEnvironment.contents = environmentMap
        }

        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showVirtualObjectSelectionViewController))
        // Set the delegate to ensure this gesture is only used when there are no virtual objects in the scene.
        tapGesture.delegate = self
        sceneView.addGestureRecognizer(tapGesture)
  */
    }
    @objc func fire()
    {
        
        startNode.removeFromParent()
        let position = exitPath.positioning()   //現在位置
        startNode.name = "startnode"
        startNode.position = CGPoint(x:Double(position!.x),y:Double(position!.y)) //算出使用者位置
        startNode.fillColor = UIColor.red
        modelScene.addChild(startNode)
        skView.presentScene(modelScene)
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Prevent the screen from being dimmed to avoid interuppting the AR experience.
		UIApplication.shared.isIdleTimerDisabled = true

        // Start the `ARSession`.
        resetTracking()
        
        // 1. 還沒有詢問過用戶以獲得權限
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }
            // 2. 用戶不同意
        else if CLLocationManager.authorizationStatus() == .denied {
            
        }
            // 3. 用戶已經同意
        else if CLLocationManager.authorizationStatus() == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

        session.pause()
	}
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        faceAngle = newHeading.magneticHeading
    }
    // MARK: - Scene content setup

    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }

        /*
         Enable HDR camera settings for the most realistic appearance
         with environmental lighting and physically based materials.
         */
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
    }

    // MARK: - Session management
    
    /// Creates a new AR configuration to run on the `session`.
	func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
		session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        statusViewController.scheduleMessage("按+放置路徑", inSeconds: 7.5, messageType: .planeEstimation)
	}

    // MARK: - Focus Square

	func updateFocusSquare() {
        let isObjectVisible = virtualObjectLoader.loadedObjects.contains { object in
            return sceneView.isNode(object, insideFrustumOf: sceneView.pointOfView!)
        }
        
        if isObjectVisible {
            focusSquare.hide()
        } else {
            focusSquare.unhide()
            statusViewController.scheduleMessage("請左右移動手機", inSeconds: 5.0, messageType: .focusSquare)
        }
        
        // We should always have a valid world position unless the sceen is just being initialized.
        guard let (worldPosition, planeAnchor, _) = sceneView.worldPosition(fromScreenPosition: screenCenter, objectPosition: focusSquare.lastPosition) else {
            updateQueue.async {
                self.focusSquare.state = .initializing
                self.sceneView.pointOfView?.addChildNode(self.focusSquare)
            }
            addObjectButton.isHidden = true
            return
        }
        
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
            let camera = self.session.currentFrame?.camera
            
            if let planeAnchor = planeAnchor {
                self.focusSquare.state = .planeDetected(anchorPosition: worldPosition, planeAnchor: planeAnchor, camera: camera)
            } else {
                self.focusSquare.state = .featuresDetected(anchorPosition: worldPosition, camera: camera)
            }
            if self.isPathPlaced{
                self.sceneView.scene.rootNode.childNodes.forEach{node in
                    node.position.y = self.self.focusSquare.lastPosition!.y
                    self.isPathPlaced = false     //為了使路徑不會持續根據anchor更新
                }
            }
        }
        addObjectButton.isHidden = false
        statusViewController.cancelScheduledMessage(for: .focusSquare)
	}
    
	// MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // Blur the background.
        blurView.isHidden = false
        
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.blurView.isHidden = true
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
    
    //MARK: - Beacon
    
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if state == CLRegionState.inside{
            if CLLocationManager.isRangingAvailable(){
                manager.startRangingBeacons(in: (region as! CLBeaconRegion))
            }else{
                print("不支援ranging")
            }
        }else{
            manager.stopRangingBeacons(in: (region as! CLBeaconRegion))
            print("不支援ranging")
        }
    }
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        if CLLocationManager.isRangingAvailable(){
            manager.startRangingBeacons(in: (region as! CLBeaconRegion))
        }else{
            print("不支援ranging")
        }
    }
    
    //The location manager calls this method whenever there is a boundary transition for a region.
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        manager.stopRangingBeacons(in: (region as! CLBeaconRegion))
        print("不支援ranging")
    }
    func locationManager(_ manager: CLLocationManager, didRangeBeacons beacons: [CLBeacon], in region: CLBeaconRegion) {
        beacons.forEach{detectedbeacon in
            exitPath.beaconList.forEach{beacon in
                if (detectedbeacon.proximityUUID == UUID(uuidString:beacon.uuid)! && detectedbeacon.major == NSNumber(value: Float(beacon.major)!)){
                    beacon.accuracy = CGFloat(detectedbeacon.accuracy/(0.3048*0.3048))
                    print(beacon.uuid+"("+beacon.major+")"+":")
                    print(beacon.accuracy*0.3048)
                }
            }
        }
        if (beacons.count > 0){
            if let nearstBeacon = beacons.first{
                
                var proximity = ""
                switch nearstBeacon.proximity {
                case CLProximity.immediate:
                    proximity = "Very close"
                case CLProximity.near:
                    proximity = "Near"
                case CLProximity.far:
                    proximity = "Far"
                default:
                    proximity = "Unknown"
                }

            }
        }
    }

}

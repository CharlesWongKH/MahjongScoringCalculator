import UIKit
import SceneKit
import ARKit
import Vision

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    /// Concurrent queue to be used for model predictions
    let predictionQueue = DispatchQueue(label: "predictionQueue",
                                        qos: .userInitiated,
                                        attributes: [],
                                        autoreleaseFrequency: .inherit,
                                        target: nil)

    /// The ARSceneView
    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet weak var calculateButton: UIButton!
    
    @IBAction func calculateScore(_ sender: Any) {
        
    }
    
    /// Layer used to host detectionOverlay layer
    var rootLayer: CALayer!
    /// The detection overlay layer used to render bounding boxes
    var detectionOverlay: CALayer!

    /// Whether the current frame should be skipped (in terms of model predictions)
    var shouldSkipFrame = 0
    /// How often (in terms of camera frames) should the app run predictions
    let predictEvery = 3

    /// Vision request for the detection model
    var mahjongDetectionRequest: VNCoreMLRequest!
    
    var mahjongData: [String] = []

    /// Flag used to decide whether to draw bounding boxes for detected objects
    var showBoxes = true {
        didSet {
            if !showBoxes {
                removeBoxes()
            }
        }
    }

    /// Size of the camera image buffer (used for overlaying boxes)
    var bufferSize: CGSize! {
        didSet {
            if bufferSize != nil {
                if oldValue == nil {
                    setupLayers()
                } else if oldValue != bufferSize {
                    updateDetectionOverlaySize()
                }
            }

        }
    }

    /// The last known image orientation
    /// When the image orientation changes, the buffer size used for rendering boxes needs to be adjusted
    var lastOrientation: CGImagePropertyOrientation = .right

    var lastObservations = [VNRecognizedObjectObservation]()

    enum RollState {
        case other
        case started
        case ended
    }

    var rollState = RollState.other

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the view's delegate
        sceneView.delegate = self

        // Set the session's delegate
        sceneView.session.delegate = self

        // Create a new scene
        let scene = SCNScene()

        // Set the scene to the view
        sceneView.scene = scene

        // Get the root layer so in order to draw rectangles
        rootLayer = sceneView.layer

        // Load the detection models
        guard let detector = try? VNCoreMLModel(for: MahJong_Object_Detector().model) else {
            print("Failed to load detector!")
            return
        }

        // Use a threshold provider to specify custom thresholds for the object detector.
        detector.featureProvider = ThresholdProvider()

        mahjongDetectionRequest = VNCoreMLRequest(model: detector) { [weak self] request, error in
            self?.detectionRequestHandler(request: request, error: error)
        }
        mahjongDetectionRequest.imageCropAndScaleOption = .scaleFill
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Disable dimming for demo
        UIApplication.shared.isIdleTimerDisabled = true

        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Pause the view's session
        sceneView.session.pause()
    }

    func bounds(for observation: VNRecognizedObjectObservation) -> CGRect {
        let boundingBox = observation.boundingBox
        let fixedBoundingBox = CGRect(x: boundingBox.origin.x,
                                      y: 1.0 - boundingBox.origin.y - boundingBox.height,
                                      width: boundingBox.width,
                                      height: boundingBox.height)

        return VNImageRectForNormalizedRect(fixedBoundingBox, Int(sceneView.frame.width), Int(sceneView.frame.height))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        if segue.destination is ResultViewController
        {
            let vc = segue.destination as? ResultViewController
            vc?.tileDataset = mahjongData
        }
    }

    func detectionRequestHandler(request: VNRequest, error: Error?) {
        // Perform several error checks before proceeding
        if let error = error {
            print("An error occurred with the vision request: \(error.localizedDescription)")
            return
        }
        guard let request = request as? VNCoreMLRequest else {
            print("Vision request is not a VNCoreMLRequest")
            return
        }
        guard let observations = request.results as? [VNRecognizedObjectObservation] else {
            print("Request did not return recognized objects: \(request.results?.debugDescription ?? "[No results]")")
            return
        }

        guard !observations.isEmpty else {
            removeBoxes()
            if !lastObservations.isEmpty {
                DispatchQueue.main.async {
                    self.infoLabel.text = ""
                }
            }
            lastObservations = []
            rollState = .other
            return
        }

        if showBoxes && rollState != .ended {
            drawBoxes(observations: observations)
        }

        rollState = hasRollEnded(observations: observations) ? .ended : .started

        if rollState == .ended {
            var sortableValues = [(value: String, xPosition: CGFloat)]()

            for observation in observations {
                guard let topLabelObservation = observation.labels.first else {
                    print("Object observation has no labels")
                    continue
                }
                
                sortableValues.append((value: topLabelObservation.identifier, xPosition: observation.boundingBox.midX))


//                if let intValue = Int(topLabelObservation.identifier) {
//                    sortableValues.append((value: intValue, xPosition: observation.boundingBox.midX))
//                }
            }

            let mahjongValues = sortableValues.sorted { $0.xPosition < $1.xPosition }.map { $0.value }
            
//            print("/// \(mahjongValues)")
            
            mahjongData = mahjongValues

            DispatchQueue.main.async {
                self.infoLabel.text = "\(mahjongValues.count)"
            }
        }
    }

    func hasRollEnded(observations: [VNRecognizedObjectObservation]) -> Bool {
        if lastObservations.count != observations.count {
            lastObservations = observations
            return false
        }
        var matches = 0
        for newObservation in observations {
            for oldObservation in lastObservations {
                if newObservation.labels.first?.identifier == oldObservation.labels.first?.identifier &&
                    intersectionOverUnion(oldObservation.boundingBox, newObservation.boundingBox) > 0.85 {
                    matches += 1
                }
            }
        }
        lastObservations = observations
        return matches == observations.count
    }
}

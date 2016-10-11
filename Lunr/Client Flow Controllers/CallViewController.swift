import UIKit
import Quickblox
import Parse

class CallViewController: UIViewController {
    // remote video
    @IBOutlet weak var remoteVideoView: QBRTCRemoteVideoView!
    @IBOutlet weak var labelRemote: UILabel!
    
    // local video
    @IBOutlet weak var localVideoView: UIView!
    @IBOutlet weak var labelLocal: UILabel!
    var videoCapture: QBRTCCameraCapture?
        
    // call controls
    @IBOutlet weak var buttonCall: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load video view
        self.loadVideoViews()

        // listen for incoming video stream
        self.listenFor(NotificationType.VideoSession.StreamInitialized.rawValue, action: #selector(attachVideoToStream(_:)), object: nil)
        self.listenFor(NotificationType.VideoSession.VideoReceived.rawValue, action: #selector(receiveVideoFromStream(_:)), object: nil)

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "", style: .Done, target: self, action: #selector(nothing))
    }

    // MARK: - Video
    func loadVideoViews() {
        // initialize own video view
        let width: UInt = UInt(self.localVideoView.frame.size.width)
        let height: UInt = UInt(self.localVideoView.frame.size.height)
        let videoFormat = QBRTCVideoFormat(width: width, height: height, frameRate: 30, pixelFormat: .Format420f)
        self.videoCapture = QBRTCCameraCapture(videoFormat: videoFormat, position: .Front)
        self.videoCapture!.previewLayer.frame = self.localVideoView.bounds
        self.videoCapture!.startSession()
        self.localVideoView.layer.insertSublayer(self.videoCapture!.previewLayer, atIndex: 0)
        
        // tells provider that video stream is ready and should attach it
        self.notify(NotificationType.VideoSession.VideoReady.rawValue, object: nil, userInfo: nil )

        // check to see if session has already received a video track
        if let videoTrack = SessionService.sharedInstance.remoteVideoTrack {
            self.remoteVideoView.setVideoTrack(videoTrack)
        }
    }

    // MARK: - own video
    func attachVideoToStream(notification: NSNotification) {
        guard let userInfo = notification.userInfo else {
            print ("cannot load video")
            return
        }
        
        guard let mediaStream: QBRTCMediaStream = userInfo["stream"] as? QBRTCMediaStream else { return }
        
        mediaStream.videoTrack.videoCapture = self.videoCapture
    }
    
    // MARK: - incoming video
    func receiveVideoFromStream(notification: NSNotification) {
        guard let userInfo = notification.userInfo else {
            print ("cannot load video")
            return
        }
        
        guard let videoTrack: QBRTCVideoTrack = userInfo["track"] as? QBRTCVideoTrack else { return }
        
        self.remoteVideoView.setVideoTrack(videoTrack)
    }
    
    // MARK: Session
    func endCall() {
        self.stopListeningFor(NotificationType.VideoSession.StreamInitialized.rawValue)
        self.stopListeningFor(NotificationType.VideoSession.VideoReceived.rawValue)
        
        SessionService.sharedInstance.endCall()
        
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // Main action button
    @IBAction func didClickButton(button: UIButton) {
        // for now, create a call object and end the call and go to review
        self.endCall()
    }

    // Back button action on navigation item
    func nothing() {
        // don't let user click back
    }

    /*
    var currentCall: Call?
    var sessionStart: NSDate?
    var sessionEnd: NSDate?

    // resulting call
    var call: Call?
    

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Segue.Call.GoToFeedback.rawValue {
            if let controller = segue.destinationViewController as? FeedbackViewController {
                controller.call = self.call
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.refreshState()
    }
     
    // UI states
    func refreshState() {
        
        switch state {
        case .NoSession:
            self.labelRemote.text = "No call in session"
            self.buttonCall.enabled = false
            self.buttonCall.alpha = 0.5
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .Done, target: self, action: #selector(didClickBack))
        case .Disconnected:
            self.labelRemote.text = "Click to start call"
            self.buttonCall.enabled = true
            self.buttonCall.alpha = 1
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .Done, target: self, action: #selector(didClickBack))
        case .Joining:
            self.labelRemote.text = "Calling..."
            self.buttonCall.enabled = false
            self.buttonCall.alpha = 0.5
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Done, target: self, action: #selector(didClickBack))
        case .Connected:
            self.labelRemote.text = "Connected! Click to end call"
            self.buttonCall.enabled = true
            self.buttonCall.alpha = 1
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .Done, target: self, action: #selector(didClickBack))
        default:
            self.labelRemote.text = "Current state: \(state)"
            break
        }
    }
    
    func loadUser() {
        if let pfUserId = targetPFUserId {
            QBUserService.getQBUUserForPFUserId(pfUserId, completion: { (result) in
                self.targetQBUUser = result
                
                if self.shouldInitiateCall {
                    self.startCall()
                    self.shouldInitiateCall = false
                }
            })
        }
    }
    
    func close() {
        self.navigationController?.popViewControllerAnimated(true)
        QBNotificationService.sharedInstance.clearDialog()
    }
    
}

// MARK: - Call actions
extension CallViewController {
    
    func endCall() {
        self.session?.hangUp(nil)
        sessionEnd = NSDate()
        // TODO: end video stream
        
        // create the call object. TODO: this should be done when the call is started
        guard let providerId = targetPFUserId else { return }
        guard let start = sessionStart else { return }
        guard let duration = sessionEnd?.timeIntervalSinceDate(start) else { return }
        
        CallService.sharedInstance.postNewCall(providerId, duration: duration as Double, totalCost: 45) { (call, error) in
            if let error = error {
                self.simpleAlert("Could not end call", defaultMessage: "There was an error saving your call.", error: error, completion: { 
                    // TODO: dismiss?
                })
            }
            else {
                // Go to feedback
                self.call = call
                self.performSegueWithIdentifier(Segue.Call.GoToFeedback.rawValue, sender: nil)
            }
        }
    }
 */
}


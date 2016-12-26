import UIKit
import Quickblox
import Parse

class CallViewController: UIViewController {
    // remote video
    @IBOutlet weak var remoteVideoView: QBRTCRemoteVideoView!
    
    // local video
    @IBOutlet weak var localVideoView: UIView!
    @IBOutlet weak var labelLocal: UILabel!
    var videoCapture: QBRTCCameraCapture?
        
    // call controls
    @IBOutlet weak var buttonCall: UIButton!
    @IBOutlet weak var buttonFlip: UIButton!
    
    var user: User?
    var recipient: QBUUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        user = PFUser.current() as? User
        
        // load video view
        self.loadVideoViews()

        // listen for incoming video stream
        self.listenFor(NotificationType.VideoSession.StreamInitialized.rawValue, action: #selector(attachVideoToStream(_:)), object: nil)
        self.listenFor(NotificationType.VideoSession.VideoReceived.rawValue, action: #selector(receiveVideoFromStream(_:)), object: nil)
        self.listenFor(NotificationType.VideoSession.HungUp.rawValue, action: #selector(endCall), object: nil)
        self.listenFor(NotificationType.VideoSession.CallCreationFailed.rawValue, action: #selector(callCreationFailed(_:)), object: nil)

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(leftBarButtonAction))
        
        if let user = user, user.isProvider {
            self.buttonCall.isHidden = true
        }
        else {
            let hangup = UIImage(named: "hang-up")?.withRenderingMode(.alwaysTemplate)
            self.buttonCall.setImage(hangup, for: .normal)
            self.buttonCall.tintColor = UIColor.lunr_beige()
        }
        let flip = UIImage(named: "camera-flip")?.withRenderingMode(.alwaysTemplate)
        self.buttonFlip.setImage(flip, for: .normal)
        self.buttonFlip.tintColor = UIColor.lunr_beige()
        
        if let name = recipient?.fullName {
            self.title = "Waiting for \(name)"
        }
        
        QBRTCSoundRouter.instance().initialize()
        QBRTCSoundRouter.instance().setCurrentSoundRoute(.speaker)
    }

    // MARK: - Video
    func loadVideoViews() {
        // initialize own video view
        let width: UInt = UInt(self.localVideoView.frame.size.width)
        let height: UInt = UInt(self.localVideoView.frame.size.height)
        let videoFormat = QBRTCVideoFormat(width: width, height: height, frameRate: 30, pixelFormat: .format420f)
        self.videoCapture = QBRTCCameraCapture(videoFormat: videoFormat, position: .front)
        self.videoCapture!.previewLayer.frame = self.localVideoView.bounds
        self.videoCapture!.startSession()
        self.localVideoView.layer.insertSublayer(self.videoCapture!.previewLayer, at: 0)
        
        // tells provider that video stream is ready and should attach it
        self.notify(NotificationType.VideoSession.VideoReady.rawValue, object: nil, userInfo: nil )

        // check to see if session has already received a video track
        if let videoTrack = SessionService.sharedInstance.remoteVideoTrack {
            self.remoteVideoView.setVideoTrack(videoTrack)
        }
    }

    // MARK: - own video
    func attachVideoToStream(_ notification: Notification) {
        guard let userInfo = notification.userInfo else {
            print ("cannot load video")
            return
        }
        
        guard let mediaStream: QBRTCMediaStream = userInfo["stream"] as? QBRTCMediaStream else { return }
        
        mediaStream.videoTrack.videoCapture = self.videoCapture
    }
    
    // MARK: - incoming video
    func receiveVideoFromStream(_ notification: Notification) {
        guard let userInfo = notification.userInfo else {
            print ("cannot load video")
            return
        }
        
        guard let videoTrack: QBRTCVideoTrack = userInfo["track"] as? QBRTCVideoTrack else { return }
        
        self.remoteVideoView.setVideoTrack(videoTrack)
        self.title = "Connected"
    }
    
    // MARK: Session
    func endCall(_ wasConnected: Bool) {
        self.stopListeningFor(NotificationType.VideoSession.StreamInitialized.rawValue)
        self.stopListeningFor(NotificationType.VideoSession.VideoReceived.rawValue)
        self.stopListeningFor(NotificationType.VideoSession.HungUp.rawValue)
        self.stopListeningFor(NotificationType.VideoSession.CallCreationFailed.rawValue)
        
        SessionService.sharedInstance.endCall()

        self.videoCapture?.stopSession()
        
        // TODO: manage call summary in client/provider classes
        if let user = user, user.isProvider {
            guard wasConnected else {
                self.simpleAlert("Call was disconnected", message: "No one else joined the call.", completion: {
                    self.navigationController?.dismiss(animated: true, completion: nil)
                })
                return
            }
        }
        
        if let user = user, !user.isProvider {
            
        }
        
        if let call = CallService.sharedInstance.currentCall {
            self.goToFeedback(call)
        }
        else {
            CallService.sharedInstance.queryCallWithId(CallService.sharedInstance.currentCallId, completion: { (result, error) in
                self.goToFeedback(result)
            })
        }
    }
    
    func goToFeedback(_ call: Call?) {
        guard let call = call else { return } // TODO: handle error
        guard let user = PFUser.current() as? User else { return }
        if user.isProvider {
            CallService.sharedInstance.updateCall(call, completion: { (result, error) in
                if error != nil {
                    // TODO: store total cost into another object
                    print("Call save error: \(error)")
                    self.simpleAlert("Could not save call", message: "There was an error saving this call. Please let us know") {
                        self.performSegue(withIdentifier: "GoToFeedback", sender: call)
                    }
                }
                else {
                    self.performSegue(withIdentifier: "GoToFeedback", sender: result)
                }
            })
        }
        else {
            // temporarily update call
            CallService.sharedInstance.updateCall(call, shouldSave: false, completion: { (result, error) in
                self.performSegue(withIdentifier: "GoToFeedback", sender: call)
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? FeedbackViewController, let call = sender as? Call {
            controller.call = call
        }
    }
    
    // Main action button
    @IBAction func didClickButton(_ button: UIButton) {
        if button == self.buttonCall {
            let alertController = UIAlertController(
                title: "End the call?",
                message: "Do you want to end the video session?",
                preferredStyle: .alert
            )
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let openAction = UIAlertAction(title: "Hang Up", style: .destructive) { action in
                // for now, create a call object and end the call and go to review
                self.endCall(SessionService.sharedInstance.state == .Connected)
            }
            
            alertController.addAction(cancelAction)
            alertController.addAction(openAction)
            present(alertController, animated: true, completion: nil)
        }
        else if button == self.buttonFlip {
            if self.videoCapture?.currentPosition() == .front {
                self.videoCapture?.selectCameraPosition(.back)
            }
            else {
                self.videoCapture?.selectCameraPosition(.front)
            }
        }
    }

    // Back button action on navigation item
    @IBAction func leftBarButtonAction() {
        // don't let user click back
    }
    
    func close() {
        self.navigationController?.popViewController(animated: true)
    }

    // Call creation failed (Provider)
    func callCreationFailed(_ notification: Notification) {
        let userInfo = notification.userInfo
        let error = userInfo?["error"] as? NSError
        self.simpleAlert("Could not initiate call", defaultMessage: "There was an error creating starting a new call", error: error, completion: {
            self.endCall(false)
        })
    }
    

    deinit {
        print("here")
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

 */
}


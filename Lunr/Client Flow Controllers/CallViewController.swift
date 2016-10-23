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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // load video view
        self.loadVideoViews()

        // listen for incoming video stream
        self.listenFor(NotificationType.VideoSession.StreamInitialized.rawValue, action: #selector(attachVideoToStream(_:)), object: nil)
        self.listenFor(NotificationType.VideoSession.VideoReceived.rawValue, action: #selector(receiveVideoFromStream(_:)), object: nil)
        self.listenFor(NotificationType.VideoSession.HungUp.rawValue, action: #selector(endCall), object: nil)
        self.listenFor(NotificationType.VideoSession.CallCreationFailed.rawValue, action: #selector(callCreationFailed(_:)), object: nil)

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: self, action: #selector(leftBarButtonAction))
        
        if let user = PFUser.currentUser() as? User where user.isProvider {
            self.buttonCall.hidden = true
        }
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
    func endCall(wasConnected: Bool) {
        self.stopListeningFor(NotificationType.VideoSession.StreamInitialized.rawValue)
        self.stopListeningFor(NotificationType.VideoSession.VideoReceived.rawValue)
        self.stopListeningFor(NotificationType.VideoSession.HungUp.rawValue)
        self.stopListeningFor(NotificationType.VideoSession.CallCreationFailed.rawValue)
        
        SessionService.sharedInstance.endCall()

        self.videoCapture?.stopSession()
        
        guard wasConnected else {
            self.simpleAlert("Call was disconnected", message: "No one else joined the call.", completion: { 
                self.close()
            })
            return
        }
        
        if let call = CallService.sharedInstance.currentCall {
            self.displayCallSummary()
        }
        else {
            CallService.sharedInstance.queryCallWithId(CallService.sharedInstance.currentCallId, completion: { (result, error) in
                self.displayCallSummary()
            })
        }
    }
    
    func displayCallSummary() {
        guard let user = PFUser.currentUser() as? User else { return }
        guard let call = CallService.sharedInstance.currentCall else { return } // TODO: handle errors
        guard let start = call.date else { return }
        guard let rate = call.rate as? Double else { return }
        
        let duration = NSDate().timeIntervalSinceDate(start)
        let minutes = round(duration / 60)
        
        call.totalCost = minutes * rate
        let message = "Total duration: \(round(minutes)) Estimated cost: \(call.totalCostString)"
        self.simpleAlert("Call summary", message: message) { 
            if user.isProvider {
                print("provider screen")
                // save the call
                call.saveInBackgroundWithBlock({ (success, error) in
                    if let _ = error {
                        // TODO: store total cost into another object
                        self.simpleAlert("Could not save call", message: "There was an error saving this call. Please let us know") {
                        }
                    }
                    else {
                        self.close()
                    }
                })
            }
            else {
                print("client screen")
                if user.isProvider {
                    self.close()
                }
                else {
                    // go to feedback
                }
            }
        }
        
    }
    
    // Main action button
    @IBAction func didClickButton(button: UIButton) {
        // for now, create a call object and end the call and go to review
        self.endCall(SessionService.sharedInstance.state == .Connected)
    }

    // Back button action on navigation item
    @IBAction func leftBarButtonAction() {
        // don't let user click back
    }
    
    func close() {
        self.navigationController?.popViewControllerAnimated(true)
    }

    // Call creation failed (Provider)
    func callCreationFailed(notification: NSNotification) {
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


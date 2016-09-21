import UIKit
import Quickblox
import Parse

// Selector Syntatic sugar: https://medium.com/swift-programming/swift-selector-syntax-sugar-81c8a8b10df3#.a6ml91o38
private extension Selector {
    // private to only this swift file
    static let didClickBack =
        #selector(CallViewController.didClickBack)
    static let didClickButton =
        #selector(CallViewController.didClickButton(_:))
}

enum CallState {
    case NoSession // session token to QuickBlox does not exist or expired
    case Disconnected // no chatroom/webrtc joined
    case Joining // currently joining the chatroom
    case Waiting // in the chat but no one else is; sending call signal
    case Connected // both people are in
}

class CallViewController: UIViewController {
    var targetPFUser: PFUser? {
        didSet {
            self.loadUser()
        }
    }
    var targetQBUUser: QBUUser? {
        didSet {
            self.refreshState()
        }
    }
    
    var currentCall: Call?
    var session: QBRTCSession?
    var incomingSession: QBRTCSession?
    var sessionStart: NSDate?
    var sessionEnd: NSDate?

    var videoCapture: QBRTCCameraCapture?
    var state: CallState = .Disconnected

    // remote video
    @IBOutlet weak var remoteVideoView: QBRTCRemoteVideoView!
    @IBOutlet weak var labelRemote: UILabel!
    
    // local video
    @IBOutlet weak var localVideoView: UIView!
    @IBOutlet weak var labelLocal: UILabel!
    
    // call controls
    @IBOutlet weak var buttonCall: UIButton!
    
    // resulting call
    var call: Call?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // for now, no calling
        self.buttonCall.enabled = false
        QBRTCClient.initializeRTC()
        QBRTCClient.instance().addDelegate(self)
        self.state = .Disconnected

        QBChat.instance().addDelegate(self)
        if !QBChat.instance().isConnected {
            self.state = .NoSession // on startup, button is disabled
            
            self.state = .Joining // TODO: not actually joining here
            QBUserService.sharedInstance.refreshSession({ (success) in
                if !success {
                    self.simpleAlert("Failed user session", message: "Please log in again.", completion: {
                        self.navigationController?.popViewControllerAnimated(true)
                    })
                }
                else {
                    // TODO: allow user to connect when button is clicked instead of automatically connecting
                    self.state = .Connected // TODO: this is faking the connected state
                    self.refreshState()
                }
            })
        }
        else {
            // load video view
            self.loadVideoView()
            self.state = .Connected // TODO: this is faking the connected state
            self.refreshState()
        }

        sessionStart = NSDate()
    }

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
        if let pfUser = targetPFUser {
            QBUserService.getQBUUserFor(pfUser, completion: { (result) in
                self.targetQBUUser = result
            })
        }
    }
    
    func close() {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    // Back button action on navigation item
    func didClickBack() {
        switch state {
        case .Joining:
            endCall()
        case .Connected:
            self.endCall()
        default:
            self.close()
        }
    }
    
    // Main action button
    @IBAction func didClickButton(button: UIButton) {
        /*
        if self.state == .Disconnected {
            self.startCall()
        }
        else {
            self.endCall()
        }
        */
        
        // for now, create a call object and end the call and go to review
        self.endCall()
    }
}

// MARK: - Call actions
extension CallViewController {
    func startCall() {
        guard let user = self.targetQBUUser else {
            self.simpleAlert("Calling disabled", message: "Could not find QBUUser to call", completion: {
            })
            return
        }
        
        // create and start session
        let id = user.ID
        let newSession: QBRTCSession = QBRTCClient.instance().createNewSessionWithOpponents([id], withConferenceType: QBRTCConferenceType.Video)
        self.session = newSession
        self.session!.startCall(nil)
        
        self.state = .Joining
        self.refreshState()
    }
    
    func endCall() {
        self.session?.hangUp(nil)
        sessionEnd = NSDate()
        // TODO: end video stream
        
        // create the call object. TODO: this should be done when the call is started
        guard let provider = targetPFUser as? User else { return }
        guard let start = sessionStart else { return }
        guard let duration = sessionEnd?.timeIntervalSinceDate(start) else { return }
        
        CallService.sharedInstance.postNewCall(provider, duration: duration as Double, totalCost: 45) { (call, error) in
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
}

extension CallViewController: QBChatDelegate{
    // MARK: - QBChatDelegate - initial connection
    func chatDidNotConnectWithError(error: NSError?) {
        print("error: \(error)")
    }
    
    func chatDidConnect() {
        print("didconnect")
    }
}

extension CallViewController: QBRTCClientDelegate {
    // MARK: - QBRTCClientDelegate
    //
    // MARK: Outbound connections
    func session(session: QBRTCSession!, acceptedByUser userID: NSNumber!, userInfo: [NSObject : AnyObject]!) {
        print("call accepted")
        
    }
    
    func session(session: QBRTCSession!, rejectedByUser userID: NSNumber!, userInfo: [NSObject : AnyObject]!) {
        print("call rejected")

        self.endCall()
    }
    
    // MARK: Inbound connections - only for provider?
    func didReceiveNewSession(session: QBRTCSession!, userInfo: [NSObject : AnyObject]!) {
        self.incomingSession = session
        if (self.session != nil) {
            // automatically reject call if a session exists
            return
        }

        let userId = self.incomingSession!.initiatorID as UInt
        QBRequest.userWithID(userId, successBlock: { (response, user) in
            print("Incoming call from a known user with id \(user?.ID)")
        }) { (response) in
            print("UserID could not be loaded")
        }
    }
    
    // MARK: All connections
    func session(session: QBRTCSession!, hungUpByUser userID: NSNumber!, userInfo: [NSObject : AnyObject]!) {
        print("session hung up")
        self.endCall()
    }
    
    func sessionDidClose(session: QBRTCSession!) {
        print("Session closed")
        // notified when all remotes are inactive
        self.session = nil
        
        self.state = .Disconnected
        self.refreshState()
    }
    
    // MARK: - Video
    func loadVideoView() {
        let width: UInt = UInt(self.localVideoView.frame.size.width)
        let height: UInt = UInt(self.localVideoView.frame.size.height)
        let videoFormat = QBRTCVideoFormat(width: width, height: height, frameRate: 30, pixelFormat: .Format420f)
        self.videoCapture = QBRTCCameraCapture(videoFormat: videoFormat, position: .Front)
        self.videoCapture!.previewLayer.frame = self.localVideoView.bounds
        self.videoCapture!.startSession()
        self.localVideoView.layer.insertSublayer(self.videoCapture!.previewLayer, atIndex: 0)
    }

    func session(session: QBRTCSession!, initializedLocalMediaStream mediaStream: QBRTCMediaStream!) {
        mediaStream.videoTrack.videoCapture = self.videoCapture
    }
    
    func session(session: QBRTCSession!, receivedRemoteVideoTrack videoTrack: QBRTCVideoTrack!, fromUser userID: NSNumber!) {
        self.remoteVideoView.setVideoTrack(videoTrack)
    }
}


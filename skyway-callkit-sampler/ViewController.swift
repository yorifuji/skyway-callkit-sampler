//
//  ViewController.swift
//  skyway-callkit-sampler
//
//  Created by yorifuji on 2019/08/06.
//  Copyright © 2019 yorifuji. All rights reserved.
//

import UIKit
import CallKit
import SkyWay
import AVFoundation

class ViewController: UIViewController {

    fileprivate var peer: SKWPeer?
    fileprivate var dataConnection: SKWDataConnection?
    fileprivate var mediaConnection: SKWMediaConnection?
    fileprivate var localStream: SKWMediaStream?
    fileprivate var remoteStream: SKWMediaStream?

    @IBOutlet weak var myPeerIdLabel: UILabel!
    @IBOutlet weak var localStreamView: SKWVideo!
    @IBOutlet weak var remoteStreamView: SKWVideo!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var endCallButton: UIButton!

    let callCenter = CallCenter(supportsVideo: true)

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.callButton.isEnabled = false
        self.endCallButton.isEnabled = false
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if AppDelegate.shared.skywayAPIKey == nil || AppDelegate.shared.skywayDomain == nil {
            let alert = UIAlertController(title: "エラー", message: "APIKEYかDOMAINが設定されていません", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default)
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
            return
        }

        checkPermissionAudio()
        callCenter.setup(self)
        setup()
    }

    @IBAction func tapCall(){
        guard let peer = self.peer else {
            return
        }

        showPeersDialog(peer) { peerId in
            self.callCenter.StartCall(true)
            self.connect(targetPeerId: peerId)
        }
    }

    @IBAction func tapEndCall(){
        self.dataConnection?.close()
        self.mediaConnection?.close()
        self.changeConnectionStatusUI(connected: false)
        self.callCenter.EndCall()
    }

    func changeConnectionStatusUI(connected:Bool){
        if connected {
            self.callButton.isEnabled = false
            self.endCallButton.isEnabled = true
        }else{
            self.callButton.isEnabled = true
            self.endCallButton.isEnabled = false
        }
    }
}

// MARK: skyway

extension ViewController {

    func setup(){
        let option: SKWPeerOption = SKWPeerOption.init();
        option.key = AppDelegate.shared.skywayAPIKey
        option.domain = AppDelegate.shared.skywayDomain

        peer = SKWPeer(options: option)

        if let _peer = peer {
            self.setupPeerCallBacks(peer: _peer)
            self.setupStream(peer: _peer)
        }else{
            let alert = UIAlertController(title: "エラー", message: "PeerのOpenに失敗しました", preferredStyle: .alert)
            let ok = UIAlertAction(title: "OK", style: .default)
            alert.addAction(ok)
            self.present(alert, animated: true, completion: nil)
        }
    }

    func setupStream(peer:SKWPeer){
        SKWNavigator.initialize(peer);
        let constraints:SKWMediaConstraints = SKWMediaConstraints()
        self.localStream = SKWNavigator.getUserMedia(constraints)
        self.localStream?.addVideoRenderer(self.localStreamView, track: 0)
    }

    func call(targetPeerId:String){
        let option = SKWCallOption()
        if let mediaConnection = self.peer?.call(withId: targetPeerId, stream: self.localStream, options: option){
            self.mediaConnection = mediaConnection
            self.setupMediaConnectionCallbacks(mediaConnection: mediaConnection)
        }else{
            print("failed to call :\(targetPeerId)")
        }
    }

    func connect(targetPeerId:String){
        let options = SKWConnectOption()
        options.serialization = SKWSerializationEnum.SERIALIZATION_BINARY
        if let dataConnection = peer?.connect(withId: targetPeerId, options: options){
            self.dataConnection = dataConnection
            self.setupDataConnectionCallbacks(dataConnection: dataConnection)
        }else{
            print("failed to connect data connection")
        }
    }

    func showPeersDialog(_ peer: SKWPeer, handler: @escaping (String) -> Void) {
        peer.listAllPeers() { peers in
            if let peerIds = peers as? [String] {
                if peerIds.count <= 1 {
                    let alert = UIAlertController(title: "接続中のPeerId", message: "接続先がありません", preferredStyle: .alert)
                    let noAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
                    alert.addAction(noAction)
                    self.present(alert, animated: true, completion: nil)

                }
                else {
                    let alert = UIAlertController(title: "接続中のPeerId", message: "接続先を選択してください", preferredStyle: .alert)
                    for peerId in peerIds{
                        if peerId != peer.identity {
                            let peerIdAction = UIAlertAction(title: peerId, style: .default, handler: { (alert) in
                                handler(peerId)
                            })
                            alert.addAction(peerIdAction)
                        }
                    }
                    let noAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
                    alert.addAction(noAction)
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
}

// MARK: skyway callbacks

extension ViewController{

    func setupPeerCallBacks(peer:SKWPeer) {

        // MARK: PEER_EVENT_ERROR
        peer.on(SKWPeerEventEnum.PEER_EVENT_ERROR) { obj in
            if let error = obj as? SKWPeerError {
                print("\(error)")
            }
        }

        // MARK: PEER_EVENT_OPEN
        peer.on(SKWPeerEventEnum.PEER_EVENT_OPEN) { obj in
            if let peerId = obj as? String{
                DispatchQueue.main.async {
                    self.myPeerIdLabel.text = peerId
                    self.changeConnectionStatusUI(connected: false)
                }
                print("your peerId: \(peerId)")
            }
        }

        // MARK: PEER_EVENT_CALL
        peer.on(SKWPeerEventEnum.PEER_EVENT_CALL) { obj in
            if let connection = obj as? SKWMediaConnection{
                self.setupMediaConnectionCallbacks(mediaConnection: connection)
                self.mediaConnection = connection
                connection.answer(self.localStream)
            }
        }

        // MARK: PEER_EVENT_CONNECTION
        peer.on(SKWPeerEventEnum.PEER_EVENT_CONNECTION) { obj in
            if let connection = obj as? SKWDataConnection{
                if self.dataConnection == nil { // may be callee
                    self.callCenter.IncomingCall(true)
                }
                self.dataConnection = connection
                self.setupDataConnectionCallbacks(dataConnection: connection)
            }
        }
    }

    func setupMediaConnectionCallbacks(mediaConnection:SKWMediaConnection){

        // MARK: MEDIACONNECTION_EVENT_STREAM
        mediaConnection.on(SKWMediaConnectionEventEnum.MEDIACONNECTION_EVENT_STREAM) { obj in
            if let msStream = obj as? SKWMediaStream{
                self.remoteStream = msStream
                DispatchQueue.main.async {
                    self.remoteStream?.addVideoRenderer(self.remoteStreamView, track: 0)
                }
                self.changeConnectionStatusUI(connected: true)
                self.callCenter.Connected()
            }
        }

        // MARK: MEDIACONNECTION_EVENT_CLOSE
        mediaConnection.on(SKWMediaConnectionEventEnum.MEDIACONNECTION_EVENT_CLOSE) { obj in
            if let _ = obj as? SKWMediaConnection{
                DispatchQueue.main.async {
                    self.remoteStream?.removeVideoRenderer(self.remoteStreamView, track: 0)
                    self.remoteStream = nil
                    self.dataConnection = nil
                    self.mediaConnection = nil
                }
                self.changeConnectionStatusUI(connected: false)
                self.callCenter.EndCall()
            }
        }
    }

    func setupDataConnectionCallbacks(dataConnection:SKWDataConnection){
        // MARK: DATACONNECTION_EVENT_OPEN
        dataConnection.on(SKWDataConnectionEventEnum.DATACONNECTION_EVENT_OPEN) { obj in
            self.changeConnectionStatusUI(connected: true)
        }

        // MARK: DATACONNECTION_EVENT_CLOSE
        dataConnection.on(SKWDataConnectionEventEnum.DATACONNECTION_EVENT_CLOSE) { obj in
            print("close data connection")
            self.dataConnection = nil
            self.changeConnectionStatusUI(connected: false)
            self.callCenter.EndCall()
        }
    }
}

// MARK: CXProviderDelegate

extension ViewController: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {

    }

    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        callCenter.Connecting()
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        if let peer = self.dataConnection?.peer {
            self.call(targetPeerId: peer)
        }
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        self.dataConnection?.close()
        self.mediaConnection?.close()
        action.fulfill()
    }
}

extension ViewController {
    func checkPermissionAudio() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            break
        case .denied:
            let alert = UIAlertController(title: "マイクの許可", message: "アプリの設定画面からマイクの使用を許可してください", preferredStyle: .alert)
            let settings = UIAlertAction(title: "設定を開く", style: .default) { result in
                UIApplication.shared.open(URL(string:UIApplication.openSettingsURLString)!)
            }
            alert.addAction(settings)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alert, animated: true, completion: nil)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { result in
                print("getAudioPermission: \(result)")
            }
        case .restricted:
            let alert = UIAlertController(title:nil, message: "マイクの使用が制限されています（通話することができません）", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true, completion: nil)
        @unknown default:
            break
        }
    }
}


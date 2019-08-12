//
//  CallCenter.swift
//  swift_skyway
//
//  Created by yorifuji on 2019/08/04.
//

import Foundation
import AVFoundation
import CallKit

class CallCenter: NSObject {

    private let controller = CXCallController()
    private let provider: CXProvider
    private var uuid = UUID()

    init(supportsVideo: Bool) {
        let providerConfiguration = CXProviderConfiguration(localizedName: "SkyWay(CallKit)")
        providerConfiguration.supportsVideo = supportsVideo
        provider = CXProvider(configuration: providerConfiguration)
    }

    func setup(_ delegate: CXProviderDelegate) {
        provider.setDelegate(delegate, queue: nil)
    }

    func StartCall(_ hasVideo: Bool = false) {
        uuid = UUID()
        let handle = CXHandle(type: .generic, value: "花子さん")
        let startCallAction = CXStartCallAction(call: uuid, handle: handle)
        startCallAction.isVideo = hasVideo
        let transaction = CXTransaction(action: startCallAction)
        controller.request(transaction) { error in
            if let error = error {
                print("CXStartCallAction error: \(error.localizedDescription)")
            }
        }
    }

    func IncomingCall(_ hasVideo: Bool = false) {
        uuid = UUID()
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: "太郎さん")
        update.hasVideo = hasVideo
        provider.reportNewIncomingCall(with: uuid, update: update) { error in
            if let error = error {
                print("reportNewIncomingCall error: \(error.localizedDescription)")
            }
        }
    }

    func EndCall() {
        let action = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: action)
        controller.request(transaction) { error in
            if let error = error {
                print("CXEndCallAction error: \(error.localizedDescription)")
            }
        }
    }

    func Connecting() {
        provider.reportOutgoingCall(with: uuid, startedConnectingAt: nil)
    }

    func Connected() {
        provider.reportOutgoingCall(with: uuid, connectedAt: nil)
    }

    func ConfigureAudioSession() {
        // Setup AudioSession
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playAndRecord, mode: .voiceChat, options: [])
    }
}


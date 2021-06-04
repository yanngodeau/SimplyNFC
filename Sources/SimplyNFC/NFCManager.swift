//
//  Reader.swift
//  SimplyNFC
//
//  Created by Yann Godeau on 18/05/2021.
//

import Foundation
import CoreNFC

open class NFCManager: NSObject {
    public typealias DidBecomeActive = (NFCManager) -> Void
    public typealias DidDetect = (NFCManager, Result<NFCNDEFMessage?, NFCError>) -> Void

    private enum NFCAction {
        case read
        case write(message: NFCNDEFMessage)
    }

    // MARK: - Properties

    open private(set) var session: NFCNDEFReaderSession?
    private var didBecomeActive: DidBecomeActive?
    private var didDetect: DidDetect?
    private var sessionConnect = NFCNDEFReaderSession.connect
    private var action: NFCAction?

    // MARK: - Functions

    /// Starts reading NFC tag
    /// - Parameter didBecomeActive: Gets called when the manager has started reading
    /// - Parameter didDetect: Gets called when the manager detects NFC tag or occurs some errors
    open func read(didBecomeActive: DidBecomeActive? = nil, didDetect: @escaping DidDetect) {
        guard NFCNDEFReaderSession.readingAvailable else {
            self.didDetect?(self, .failure(.unavailable))
            return
        }
        let session = NFCNDEFReaderSession(delegate: self,
                                           queue: nil,
                                           invalidateAfterFirstRead: true)
        action = .read
        startSession(session: session, didBecomeActive: didBecomeActive, didDetect: didDetect)
    }

    /// Starts writing on NFC tag
    /// - Parameter message: The message to write
    /// - Parameter didBecomeActive: Gets called when the manager has started writing
    /// - Parameter didDetect: Gets called when the manager detects NFC tag or occurs some errors
    open func write(message: NFCNDEFMessage, didBecomeActive: DidBecomeActive? = nil, didDetect: @escaping DidDetect) {
        guard NFCNDEFReaderSession.readingAvailable else {
            self.didDetect?(self, .failure(.unavailable))
            return
        }
        let session = NFCNDEFReaderSession(delegate: self,
                                           queue: nil,
                                           invalidateAfterFirstRead: false)
        action = .write(message: message)
        startSession(session: session, didBecomeActive: didBecomeActive, didDetect: didDetect)
    }

    /// Sets a custom message alert that provides more context about how your app uses NFC reader mode
    /// - Parameter alertMessage: The alert message
    open func setMessage(_ alertMessage: String) {
        session?.alertMessage = alertMessage
    }

    // MARK: - Private functions

    private func invalidate(errorMessage: String?) {
        if errorMessage != nil {
            session?.invalidate(errorMessage: errorMessage!)
        } else {
            session?.invalidate()
        }
        session = nil
        didBecomeActive = nil
        didDetect = nil
    }

    private func startSession(session: NFCNDEFReaderSession,
                              didBecomeActive: DidBecomeActive?,
                              didDetect: @escaping DidDetect) {
        self.session = session
        self.didBecomeActive = didBecomeActive
        self.didDetect = didDetect
        session.begin()
    }

}

// MARK: - NFCNDEFReaderSessionDelegate
extension NFCManager: NFCNDEFReaderSessionDelegate {

    public func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        if let error = error as? NFCReaderError,
           error.code != .readerSessionInvalidationErrorFirstNDEFTagRead &&
            error.code != .readerSessionInvalidationErrorUserCanceled {
            self.didDetect?(self, .failure(.invalidated(errorDescription: error.localizedDescription)))
        }
        self.session = nil
        self.didBecomeActive = nil
        self.didDetect = nil
    }

    public func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        self.didBecomeActive?(self)
    }

    public func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // Not used
    }

    public func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        guard tags.count == 1, let tag = tags.first else {
            DispatchQueue.global().asyncAfter(deadline: .now() + .microseconds(500)) {
                session.restartPolling()
            }
            return
        }

        sessionConnect(session)(tag) { [weak self] error in
            guard let self = self else { return }

            if error != nil {
                self.didDetect?(self, .failure(.invalidated(errorDescription: error!.localizedDescription)))
                self.invalidate(errorMessage: error?.localizedDescription)
                return
            }

            tag.queryNDEFStatus { status, capacity, error in
                switch (status, self.action) {
                case (.notSupported, _):
                    self.didDetect?(self, .failure(.notSupported))
                    self.invalidate(errorMessage: error?.localizedDescription)

                case (.readOnly, _):
                    self.didDetect?(self, .failure(.readOnly))

                case (.readWrite, .read):
                    tag.readNDEF { message, error in
                        if error != nil {
                            self.didDetect?(self, .failure(.invalidated(errorDescription: error!.localizedDescription)))
                            self.invalidate(errorMessage: error?.localizedDescription)
                            return
                        }
                        self.didDetect?(self, .success(message))
                        self.invalidate(errorMessage: error?.localizedDescription)
                    }

                case (.readWrite, .write(let message)):
                    guard message.length <= capacity else {
                        self.didDetect?(self, .failure(.invalidPayloadSize))
                        self.invalidate(errorMessage: "Invalid payload size")
                        return
                    }

                    tag.writeNDEF(message) { error in
                        if error != nil {
                            self.didDetect?(self, .failure(.invalidated(errorDescription: error!.localizedDescription)))
                            self.invalidate(errorMessage: error!.localizedDescription)
                            return
                        }
                        self.didDetect?(self, .success(message))
                        self.invalidate(errorMessage: error?.localizedDescription)
                    }
                default:
                    return
                }
            }
        }
    }
}

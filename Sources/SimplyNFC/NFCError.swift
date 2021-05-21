//
//  NFCError.swift
//  SimplyNFC
//
//  Created by Yann Godeau on 18/05/2021.
//

import Foundation

public enum NFCError: Error {
    case unavailable
    case notSupported
    case readOnly
    case invalidPayloadSize
    case invalidated(errorDescription: String)
}

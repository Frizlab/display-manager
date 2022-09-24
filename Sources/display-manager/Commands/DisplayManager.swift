/*
 * DisplayManager.swift
 * Created by François Lamboley on 2022/03/15. */

import CoreGraphics
import Foundation

import ArgumentParser



@main
struct DisplayManager : AsyncParsableCommand {
	
	func run() async throws {
		var count: UInt32 = 0
		let err1 = CGGetOnlineDisplayList(32, nil, &count)
		guard err1 == .success else {
			throw Err.cgError(err1)
		}
		guard count > 0 else {
			return
		}
		let displayIDsPtr = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: Int(count))
		defer {displayIDsPtr.deallocate()}
		let err2 = CGGetOnlineDisplayList(count, displayIDsPtr, &count)
		guard err2 == .success else {
			throw Err.cgError(err1)
		}
		guard count > 0 else {
			return
		}
		let displayIDs = (displayIDsPtr..<displayIDsPtr.advanced(by: Int(count))).reduce([], { $0 + [$1.pointee] })
		print(displayIDs)
	}
	
}

enum DisplayManagerError : Error {
	case cgError(CGError)
}
typealias Err = DisplayManagerError

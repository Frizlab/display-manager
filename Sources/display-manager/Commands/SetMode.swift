import CoreGraphics
import Foundation

import ArgumentParser



struct SetMode : AsyncParsableCommand {
	
	static let configuration: CommandConfiguration = .init(
		commandName: "set-mode",
		abstract: "Set the mode (resolution, refresh rate, etc.) of one or more displays.",
		aliases: ["set-resolution", "mode", "res"]
	)
	
	@Argument
	var targetMode: DisplayModeDescription
	
	@Argument
	var displaySelectors: [DisplaySelector] = [.main]
	
	func run() async throws {
		print(targetMode)
		print(displaySelectors)
		
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

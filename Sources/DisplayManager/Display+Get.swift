import CoreGraphics
import Foundation



public extension Display {
	
	static func getAll() throws -> [Display] {
		try getAll(matching: [.all])
	}
	
	static func getAll(matching selectors: Set<DisplaySelector>) throws -> [Display] {
		guard !selectors.isEmpty else {
			return []
		}
		guard !selectors.contains(.all) else {
			return try Self.getAllDisplayIDs().map(Display.init(id:))
		}
		
		let mainDisplayID = CGMainDisplayID()
		
		var _externalDisplayIDs: [CGDirectDisplayID]?
		var externalDisplayIDs: [CGDirectDisplayID] {
			get throws {
				if let _externalDisplayIDs {
					return _externalDisplayIDs
				}
				let result = try Self.getSortedListOfExternalDisplayIDs(mainDisplayID: mainDisplayID)
				_externalDisplayIDs = result
				return result
			}
		}
		
		return try selectors.flatMap{ selector -> [CGDirectDisplayID] in
			switch selector {
				case .main:
					return [mainDisplayID]
					
				case .external(let idx):
					let idx = idx - 1
					let externalDisplayIDs = try externalDisplayIDs
					guard idx >= 0, idx < externalDisplayIDs.count else {
						throw Err.outOfBoundsDisplay(idx + 1)
					}
					return [externalDisplayIDs[idx]]
					
				case .all:
					assertionFailure("This case should already have been handled.")
					return try Self.getAllDisplayIDs()
			}
		}.map(Display.init(id:))
	}
	
	private static func getAllDisplayIDs() throws -> [CGDirectDisplayID] {
		var count: UInt32 = 0
		let err1 = CGGetOnlineDisplayList(0, nil, &count)
		guard err1 == .success else {
			throw Err.cgError(err1)
		}
		guard count > 0 else {
			return []
		}
		let bufferSize = count + 5
		let displayIDsPtr = UnsafeMutablePointer<CGDirectDisplayID>.allocate(capacity: Int(bufferSize))
		defer {displayIDsPtr.deallocate()}
		let err2 = CGGetOnlineDisplayList(bufferSize, displayIDsPtr, &count)
		guard err2 == .success else {
			throw Err.cgError(err1)
		}
		guard count > 0 else {
			/* Note: This should not happen, unless we have a very unlikely race where all the displays becomes offline after we have retrieved the list of displays… */
			return []
		}
		if count >= bufferSize {
			/* If the count returned is the same as at least the buffer size,
			 *  that means (at least 5) new displays have come online since the first call to CGGetOnlineDisplayList
			 *  that retrieved the list of online displays.
			 * We print a message to warn of the potential loss of online displays.
			 * Note: count should NEVER be greater than buffer size! */
			logger.warning("Potentially dropping online displays due to race.")
		}
		return (displayIDsPtr..<displayIDsPtr.advanced(by: Int(count))).reduce([], { $0 + [$1.pointee] })
	}
	
	private static func getSortedListOfExternalDisplayIDs(mainDisplayID: CGDirectDisplayID) throws -> [CGDirectDisplayID] {
		let displayIDs = try Self.getAllDisplayIDs()
		return displayIDs.filter{ $0 != mainDisplayID }.sorted()
	}
	
}

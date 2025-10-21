import CoreGraphics
import Foundation
import IOKit

import Logging



struct Display {
	
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
	
	var id: CGDirectDisplayID
	
	init(id: CGDirectDisplayID) {
		self.id = id
	}
	
	func getAllModes(onlyUsableForDesktopGUI: Bool = true, withDuplicatesLowResolution: Bool = true, withInvalid: Bool = false) throws -> [CGDisplayMode] {
		/* For some unknown reason, the mere presence of the kCGDisplayShowDuplicateLowResolutionModes key will enable duplicate low-resolution modes in the output of CGDisplayCopyAllDisplayModes.
		 * I tried a lot of different values (kCFBooleanFalse, nil, NSNumber(value: 0), 2 -1…) and found none that did not activate that.
		 * So we remove the key when we do not want the low resolution modes… */
		let options: [CFString: Any] = [
			kCGDisplayShowDuplicateLowResolutionModes: withDuplicatesLowResolution ? kCFBooleanTrue : nil
		].compactMapValues(\.self)
		guard let cfModes = CGDisplayCopyAllDisplayModes(id, options as CFDictionary?) else {
			throw Err.internalError(message: "Invalid display ID.")
		}
		guard let modes = cfModes as? [CGDisplayMode] else {
			throw Err.internalError(message: "Invalid return value from CGDisplayCopyAllDisplayModes: not an array of CGDisplayMode.")
		}
		return modes.filter{ mode in
			(!onlyUsableForDesktopGUI || mode.isUsableForDesktopGUI()) &&
			( withInvalid             || mode.isValid)
		}
	}
	
	func getDefaultMode() throws -> CGDisplayMode {
		let candidates = try {
			let candidatesNoLow = try getAllModes(onlyUsableForDesktopGUI: false, withDuplicatesLowResolution: false).filter(\.isDefault)
			if !candidatesNoLow.isEmpty {
				return candidatesNoLow
			}
			return try getAllModes(onlyUsableForDesktopGUI: false, withDuplicatesLowResolution: true).filter(\.isDefault)
		}()
		guard let result = candidates.first else {
			throw Err.noDefaultDisplayFound
		}
		guard candidates.count == 1 else {
			throw Err.internalError(message: "More than one default display found.")
		}
		return result
	}
	
	func getCurrentMode() throws -> CGDisplayMode {
		guard let mode = CGDisplayCopyDisplayMode(id) else {
			throw Err.internalError(message: "Invalid display ID.")
		}
		return mode
	}
	
	/* Adapted from <https://medium.com/@zpcat/how-to-get-displays-device-name-by-iokit-in-mac-os-x-f91f42e8955>. */
	func getIOServiceInfoDictionary() throws -> [String: AnyObject] {
		var serialPortIterator: io_iterator_t = 0
		let matching = IOServiceMatching("IOFramebuffer") /* Note: Also works with “IODisplay” and “IODisplayConnect”. */
		guard IOServiceGetMatchingServices(kIOMasterPortDefault, matching, &serialPortIterator) == KERN_SUCCESS,
				serialPortIterator != 0
		else {
			throw Err.internalError(message: "Cannot get serial port iterator.")
		}
		defer {IOObjectRelease(serialPortIterator)}
		
		struct IOIterator : IteratorProtocol {
			let serialPortIterator: io_iterator_t
			func next() -> io_service_t? {
				let service = IOIteratorNext(serialPortIterator)
				guard service != 0 else {
					return nil
				}
				return service
			}
		}
		
		let iterator = IOIterator(serialPortIterator: serialPortIterator)
		while let ioService = iterator.next() {
//			var dictionaryPtr: Unmanaged<CFDictionary>?
//			let ret = IODisplayCopyParameters(ioService, 0, &dictionaryPtr)
//			print(dictionaryPtr?.takeRetainedValue())
			guard let info = IODisplayCreateInfoDictionary(ioService, UInt32(kIODisplayOnlyPreferredName)).takeRetainedValue() as? [String: AnyObject] else {
				Logger(label: "Display").warning("Failed retrieving IO info dictionary for IO service. Skipping this service.")
				continue
			}
			
			/* Note: We take the first that matches w/o checking if another would (which should never happen). */
			if CGDisplayVendorNumber(id) == info[kDisplayVendorID] as? UInt32,
				CGDisplayModelNumber(id)  == info[kDisplayProductID] as? UInt32,
				CGDisplaySerialNumber(id) == info[kDisplaySerialNumber] as? UInt32 ?? 0
			{
				return info
			}
		}
		
		throw Err.internalError(message: "IOService not found for display ID.")
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
			Logger(label: "Display").warning("Potentially dropping online displays due to race.")
		}
		return (displayIDsPtr..<displayIDsPtr.advanced(by: Int(count))).reduce([], { $0 + [$1.pointee] })
	}
	
	private static func getSortedListOfExternalDisplayIDs(mainDisplayID: CGDirectDisplayID) throws -> [CGDirectDisplayID] {
		let displayIDs = try Self.getAllDisplayIDs()
		return displayIDs.filter{ $0 != mainDisplayID }.sorted()
	}
	
}

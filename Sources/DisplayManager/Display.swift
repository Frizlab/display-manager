import CoreGraphics
import Foundation
import IOKit

import Logging



public struct Display : Equatable, Sendable {
	
	public var id: CGDirectDisplayID
	
	public init(id: CGDirectDisplayID) {
		self.id = id
	}
	
	/* Adapted from <https://medium.com/@zpcat/how-to-get-displays-device-name-by-iokit-in-mac-os-x-f91f42e8955>.
	 * Only works on Intel devices, most likely (or on macOS before 26).
	 * Kept because it is interesting code, but should not be used. */
	@available(*, deprecated, message: "This is unreliable af! It waaay to close to the hardware.")
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
				logger.warning("Failed retrieving IO info dictionary for IO service. Skipping this service.")
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
	
}

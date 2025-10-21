import CoreGraphics
import Foundation
import IOKit

import Logging



/* Adapted from <https://medium.com/@zpcat/how-to-get-displays-device-name-by-iokit-in-mac-os-x-f91f42e8955>. */
extension CGDirectDisplayID {
	
	func getIOService() throws -> io_service_t {
		var serialPortIterator: io_iterator_t = 0
		let matching = IOServiceMatching("IODisplayConnect")
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
			guard let info = IODisplayCreateInfoDictionary(ioService, UInt32(kIODisplayOnlyPreferredName)).takeRetainedValue() as NSDictionary as? [String: AnyObject] else {
				Logger(label: "CGDirectDisplayID+Utils").warning("Failed retrieving IO info dictionary for IO service. Skipping this service.")
				continue
			}
			
			if CGDisplayVendorNumber(self) == info[kDisplayVendorID] as? UInt32,
				CGDisplayModelNumber(self)  == info[kDisplayProductID] as? UInt32,
				CGDisplaySerialNumber(self) == info[kDisplaySerialNumber] as? UInt32
			{
				return ioService
			}
		}
		
		throw Err.internalError(message: "IOService not found for display ID.")
	}
	
}

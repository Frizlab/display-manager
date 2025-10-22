import CoreGraphics
import Foundation
import IOKit

import Logging



public struct Display : Equatable, Sendable {
	
	public var id: CGDirectDisplayID
	
	public init(id: CGDirectDisplayID) {
		self.id = id
	}
	
//	func getHighestMode(hiDPIFilter: HiDPIFilter, onlyUsableForDesktopGUI: Bool = true) throws -> CGDisplayMode {
//		let allModes = try getAllModes(onlyUsableForDesktopGUI: onlyUsableForDesktopGUI)
//		throw Err.internalError(message: "Not Implemented")
//	}
	
	/*
    def highestMode(self, hidpi=0):
        """
        :param hidpi: HiDPI code. 0 returns everything, 1 returns only non-HiDPI, and 2 returns only HiDPI.
        :return: The Quartz "DisplayMode" interface with the highest display resolution for this display.
        """
        highest = None
        for mode in self.allModes:
            if highest:
                if mode > highest and self.__rightHidpi(mode, hidpi):
                    highest = mode
            else:  # highest hasn't been set yet, so anything is the highest
                highest = mode

        if highest:
            return highest
        else:
            if hidpi == 1:
                raise DisplayError(
                    "Display \"{}\" cannot be set to any non-HiDPI resolutions".format(self.tag))
            elif hidpi == 2:
                raise DisplayError(
                    "Display \"{}\" cannot be set to any HiDPI resolutions".format(self.tag))
            else:
                raise DisplayError(
                    "Display \"{}\"\'s resolution cannot be set".format(self.tag))

    def closestMode(self, width, height, refresh=0, hidpi=0):
        """
        :param width: Desired width
        :param height: Desired height
        :param refresh: Desired refresh rate
        :param hidpi: HiDPI code. 0 returns everything, 1 returns only non-HiDPI, and 2 returns only HiDPI
        :return: The closest Quartz "DisplayMode" interface possible for this display.
        """
        # Which criteria does it match (in addition to width and height)?
        both = []           # matches HiDPI and refresh
        onlyHidpi = []      # matches HiDPI
        onlyRefresh = []    # matches refresh

        for mode in self.allModes:
            if mode.width == width and mode.height == height:
                if self.__rightHidpi(mode, hidpi) and mode.refresh == refresh:
                    both.append(mode)
                elif self.__rightHidpi(mode, hidpi):
                    onlyHidpi.append(mode)
                elif mode.refresh == refresh:
                    onlyRefresh.append(mode)

        # Return the nearest match, with HiDPI matches preferred over refresh matches
        for modes in [both, onlyHidpi, onlyRefresh]:
            if modes:
                return modes[0]

        raise DisplayError(
            "Display \"{}\" cannot be set to {}x{}".format(self.tag, width, height)
        )
	 */
	
	/* Adapted from <https://medium.com/@zpcat/how-to-get-displays-device-name-by-iokit-in-mac-os-x-f91f42e8955>.
	 * Only works on Intel devices, most likely (or on macOS before 26). */
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

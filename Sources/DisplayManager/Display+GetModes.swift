import CoreGraphics
import Foundation



public extension Display {
	
	func getCurrentMode() throws -> CGDisplayMode {
		guard let mode = CGDisplayCopyDisplayMode(id) else {
			throw Err.internalError(message: "Invalid display ID.")
		}
		return mode
	}
	
	func getDefaultMode() throws -> CGDisplayMode {
		let candidates = try getAllModes(onlyUsableForDesktopGUI: false, withInvalid: true, withUnsafe: true).filter(\.isDefault)
		guard let result = candidates.first else {
			throw Err.noDefaultDisplayFound
		}
		guard candidates.count == 1 else {
			throw Err.internalError(message: "More than one default display found.")
		}
		return result
	}
	
	/** Retrieve all the display modes for the receiver. */
	func getAllModes(onlyUsableForDesktopGUI: Bool = true, withInvalid: Bool = false, withUnsafe: Bool = false) throws -> [CGDisplayMode] {
		/* See DisplayModeGroup for an explanation of the algorithm used in this method. */
		
		guard let cfModesWithDuplicates = CGDisplayCopyAllDisplayModes(id, [kCGDisplayShowDuplicateLowResolutionModes: kCFBooleanTrue] as CFDictionary) else {
			throw Err.internalError(message: "Invalid display ID.")
		}
		guard let modesWithDuplicates = cfModesWithDuplicates as? [CGDisplayMode] else {
			throw Err.internalError(message: "Invalid return value from CGDisplayCopyAllDisplayModes: not an array of CGDisplayMode.")
		}
		
		let modeGroups = DisplayModeGroup.from(modesWithDuplicates)
		
		/* For some unknown reason, the mere presence of the kCGDisplayShowDuplicateLowResolutionModes key will enable duplicate low-resolution modes in the output of CGDisplayCopyAllDisplayModes.
		 * I tried a lot of different values (kCFBooleanFalse, nil, NSNumber(value: 0), 2 -1…) and found none that did not activate that.
		 * So we remove the key when we do not want the low resolution modes… */
		guard let cfModesNoDuplicates = CGDisplayCopyAllDisplayModes(id, [:] as CFDictionary) else {
			throw Err.internalError(message: "Invalid display ID (but it was previously ok? that’s super weird…).")
		}
		guard let modesNoDuplicates = cfModesNoDuplicates as? [CGDisplayMode] else {
			throw Err.internalError(message: "Invalid return value from CGDisplayCopyAllDisplayModes: not an array of CGDisplayMode.")
		}
		
		return DisplayModeGroup.consolidate(modeGroups, withNoDuplicatesModes: modesNoDuplicates)
			.filter{ mode in
				(!onlyUsableForDesktopGUI || mode.isUsableForDesktopGUI()) &&
				( withInvalid             || mode.isValid) &&
				( withUnsafe              || mode.isSafeForHardware)
			}
			.sorted{ $0.ioDisplayModeID < $1.ioDisplayModeID }
	}
	
}

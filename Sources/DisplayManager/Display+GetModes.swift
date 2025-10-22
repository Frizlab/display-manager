import CoreGraphics
import Foundation



public extension Display {
	
	func getMode(matching modeDescription: DisplayModeDescription, hiDPIFilter: HiDPIFilter = .noHiDPIFilter) throws -> CGDisplayMode {
		switch modeDescription {
			case .default: return try getDefaultMode()
			case .highest: return try getHighestMode(hiDPIFilter: hiDPIFilter)
			case .explicit(let x, let y, let refreshRate):
				return try getHighestModeMatching(width: x, height: y, refreshRate: refreshRate, hiDPIFilter: hiDPIFilter)
		}
	}
	
	func getCurrentMode() throws -> CGDisplayMode {
		guard let mode = CGDisplayCopyDisplayMode(id) else {
			throw Err.internalError(message: "Invalid display ID.")
		}
		return mode
	}
	
	func getDefaultMode() throws -> CGDisplayMode {
		let modes = try getAllModes(onlyUsableForDesktopGUI: false, withInvalid: true, withUnsafe: true)
		guard !modes.isEmpty else {
			throw Err.displayHasNoModes
		}
		let candidates = modes.filter(\.isDefault)
		guard let result = candidates.first else {
			throw Err.noDefaultDisplayModeFound
		}
		guard candidates.count == 1 else {
			throw Err.internalError(message: "More than one default display found.")
		}
		return result
	}
	
	func getHighestMode(hiDPIFilter: HiDPIFilter = .noHiDPIFilter, onlyUsableForDesktopGUI: Bool = true, withInvalid: Bool = false, withUnsafe: Bool = false) throws -> CGDisplayMode {
		let modes = try getAllModes(hiDPIFilter: hiDPIFilter, onlyUsableForDesktopGUI: onlyUsableForDesktopGUI, withInvalid: withInvalid, withUnsafe: withUnsafe)
		let highestMode = modes.sorted(by: areModesSorted).last
		guard let highestMode else {
			throw Err.displayHasNoModes
		}
		return highestMode
	}
	
	func getHighestModeMatching(width: Int, height: Int, refreshRate: Double?, hiDPIFilter: HiDPIFilter = .noHiDPIFilter, onlyUsableForDesktopGUI: Bool = true, withInvalid: Bool = false, withUnsafe: Bool = false) throws -> CGDisplayMode {
		let modes = try getAllModes(hiDPIFilter: hiDPIFilter, onlyUsableForDesktopGUI: onlyUsableForDesktopGUI, withInvalid: withInvalid, withUnsafe: withUnsafe)
		guard !modes.isEmpty else {
			throw Err.displayHasNoModes
		}
		let highestMatch = modes
			.filter{ mode in
				mode.width == width && mode.height == height && (refreshRate.map{ mode.refreshRate == $0 } ?? true)
			}
			.sorted(by: areModesSorted)
			.last
		guard let highestMatch else {
			throw Err.noMatchingDisplayModeFound
		}
		return highestMatch
	}
	
	/** Retrieve all the display modes for the receiver. */
	func getAllModes(hiDPIFilter: HiDPIFilter = .noHiDPIFilter, onlyUsableForDesktopGUI: Bool = true, withInvalid: Bool = false, withUnsafe: Bool = false) throws -> [CGDisplayMode] {
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
				mode.matchesHiDPIFilter(hiDPIFilter) &&
				(!onlyUsableForDesktopGUI || mode.isUsableForDesktopGUI()) &&
				( withInvalid             || mode.isValid) &&
				( withUnsafe              || mode.isSafeForHardware)
			}
	}
	
	private func areModesSorted(_ mode1: CGDisplayMode, _ mode2: CGDisplayMode) -> Bool {
		/* We prioritize HiDPI resolutions (put them at the end).
		 * For the same width/height for a mode, the user will effectively have a higher resolution for the HiDIP one (greater pixel width/height).
		 * We cannot only sort on pixel width/height either: the resolution for a given pixel width/height will probably be there twice: once in HiDPI, the other in normal resolution… */
		switch (mode1.isHiDPI, mode2.isHiDPI) {
			case (false, true): return true
			case (true, false): return false
			case (false, false), (true, true):
				let weight1 = mode1.width * mode1.height
				let weight2 = mode2.width * mode2.height
				if weight1 == weight2 {
					return mode1.refreshRate < mode2.refreshRate
				}
				return weight1 < weight2
		}
	}
	
}

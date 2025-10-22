import CoreGraphics
import Foundation



/**
 A group of display mode, that have the same `ioDisplayModeID`.
 
 Why?  
 CGDisplay APIs are weird to say the least…
 
 To retrieve the list of display modes available for a given display,
  one should call `CGDisplayCopyAllDisplayModes`.
 
 So far so good.
 
 On `M*` series Macs (or some other unknown reasons), not all possible modes are returned by this function.
 In particular, the _default_ mode for the display is not returned!
 
 To fix this, we should add the (undocumented) `kCGDisplayShowDuplicateLowResolutionModes` option when calling the method.
 
 However, on non-`M*` series Macs (or whatever actual discriminator), we get spammed with a lot of duplicate modes when doing that (duh).
 
 The good thing is, AFAICT, all the duplicate modes have the same `ioDisplayModeID`, so we can filter them out.
 However which of the two modes should we filter out?
 
 To answer that, we call `CGDisplayCopyAllDisplayModes` again, but this time w/o the low resolution modes.
 
 Then we iterate on all our `DisplayModeGroup` and remove the modes not present in the normal resolution modes if there is at least another mode in the group.
 
 Finally we should be left with an array of `DisplayModeGroup` that all contain only one mode.
 
 Interestingly, using the deprecated `CGDisplayAvailableModes` function (not available in Swift) works great without any hackery… */
struct DisplayModeGroup {
	
	static func from(_ modes: [CGDisplayMode]) -> [DisplayModeGroup] {
		var res = [DisplayModeGroup]()
		for mode in modes {
			add(mode, to: &res)
		}
		return res
	}
	
	static func add(_ mode: CGDisplayMode, to groups: inout [DisplayModeGroup]) {
		for (idx, group) in groups.enumerated() {
			var group = group
			if group.add(mode) {
				groups[idx] = group
				return
			}
		}
		groups.append(DisplayModeGroup(mode: mode))
	}
	
	static func consolidate(_ groups: [DisplayModeGroup], withNoDuplicatesModes modes: [CGDisplayMode]) -> [CGDisplayMode] {
		var groups = groups
		for mode in modes {
			var found = false
			for (idx, group) in groups.enumerated() {
				if group.ioDisplayModeID == mode.ioDisplayModeID {
					if group.modes.count > 2 {
						logger.warning("Potentially dropping valid display mode from modes list.", metadata: [
							"modes_in_group": .array(group.modes.map{ "\($0)" }),
							"remaining_mode": "\(mode)",
						])
					}
					groups[idx] = DisplayModeGroup(mode: mode)
					found = true
					break
				}
			}
			if !found {
				logger.warning("Mode from no duplicates unexpectedly not found in nodes with duplicates! Adding to list of modes returned.", metadata: ["mode": "\(mode)"])
				groups.append(DisplayModeGroup(mode: mode))
			}
		}
		return groups.compactMap{ group in
			if group.modes.count > 1 {
				logger.warning("Found a display mode group remaining with more than one mode. Returning first mode only.", metadata: [
					"modes_in_group": .array(group.modes.map{ "\($0)" }),
					"remaining_mode": "\(group.modes.first!)",
				])
			}
			return group.modes.first
		}
	}
	
	private(set) var modes: [CGDisplayMode]
	
	init(mode: CGDisplayMode) {
		self.modes = [mode]
	}
	
	var ioDisplayModeID: Int32? {
		return modes.first!.ioDisplayModeID
	}
	
	mutating func add(_ mode: CGDisplayMode) -> Bool {
		guard mode.ioDisplayModeID == modes.first!.ioDisplayModeID else {
			return false
		}
		modes.append(mode)
		return true
	}
	
}

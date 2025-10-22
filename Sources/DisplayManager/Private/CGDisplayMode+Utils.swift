import CoreGraphics
import Foundation
import IOKit



extension CGDisplayMode {
	
	var isDefault: Bool {
		return (ioFlags & UInt32(kDisplayModeDefaultFlag)) != 0
	}
	
	var isNative: Bool {
		(ioFlags & UInt32(kDisplayModeNativeFlag)) != 0
	}
	
	var isValid: Bool {
		(ioFlags & UInt32(kDisplayModeValidFlag)) != 0
	}
	
	var isSafeForHardware: Bool {
		(ioFlags & UInt32(kDisplayModeSafeFlag)) != 0
	}
	
	var isHiDPI: Bool {
		width < pixelWidth && height < pixelHeight
	}
	
}

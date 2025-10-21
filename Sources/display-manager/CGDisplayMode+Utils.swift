import CoreGraphics
import Foundation
import IOKit



extension CGDisplayMode {
	
	var isDefault: Bool {
		return (ioFlags & UInt32(kDisplayModeDefaultFlag)) != 0
	}
	
}

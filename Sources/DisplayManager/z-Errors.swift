import CoreGraphics
import Foundation



public enum DisplayManagerError : Error {
	
	case cgError(CGError)
	case outOfBoundsDisplay(Int)
	
	case displayHasNoModes
	case noDefaultDisplayModeFound
	
	case internalError(message: String)
	
}
typealias Err = DisplayManagerError

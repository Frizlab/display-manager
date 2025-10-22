import CoreGraphics
import Foundation



public enum DisplayManagerError : Error {
	
	case cgError(CGError)
	case outOfBoundsDisplay(Int)
	
	case noDefaultDisplayFound
	
	case internalError(message: String)
	
}
typealias Err = DisplayManagerError

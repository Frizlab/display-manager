import CoreGraphics
import Foundation



typealias Err = DisplayManagerError
enum DisplayManagerError : Error {
	
	case cgError(CGError)
	case outOfBoundsDisplay(Int)
	
}

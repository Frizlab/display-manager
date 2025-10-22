import CoreGraphics
import Foundation
import IOKit

import Logging



public struct Display : Equatable, Sendable {
	
	public var id: CGDirectDisplayID
	
	public init(id: CGDirectDisplayID) {
		self.id = id
	}
	
}

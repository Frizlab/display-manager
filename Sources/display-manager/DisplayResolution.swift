import Foundation

import ArgumentParser



enum DisplayResolution : Equatable {
	
	case `default`
	case highest
	case explicit(x: UInt, y: UInt)
	
}

extension DisplayResolution : RawRepresentable {
	
	var rawValue: String {
		switch self {
			case .default: return "default"
			case .highest: return "highest"
			case .explicit(let x, let y): return "\(x)×\(y)"
		}
	}
	
	init?(rawValue: String) {
		switch rawValue {
			case "default": self = .default
			case "highest": self = .highest
			case let str:
				let components = str.components(separatedBy: CharacterSet(charactersIn: "×x"))
				guard components.count == 2 else {
					return nil
				}
				guard let x = UInt(components[0]),
						let y = UInt(components[1])
				else {
					return nil
				}
				self = .explicit(x: x, y: y)
		}
	}
	
}

extension DisplayResolution : ExpressibleByArgument {}

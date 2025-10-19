import Foundation

import ArgumentParser



enum DisplayMode : Equatable {
	
	case `default`
	case highest
	case explicit(x: Int, y: Int, refreshRate: Double?)
	
}

extension DisplayMode : RawRepresentable {
	
	var rawValue: String {
		switch self {
			case .default: return "default"
			case .highest: return "highest"
			case .explicit(let x, let y, let r): return "\(x)×\(y)" + (r.map{ ":\($0)" } ?? "")
		}
	}
	
	init?(rawValue: String) {
		switch rawValue {
			case "default": self = .default
			case "highest": self = .highest
			case let str:
				let refreshRate: Double?
				let componentsRefreshRate = str.components(separatedBy: ":")
				switch componentsRefreshRate.count {
					case 1:
						refreshRate = nil
					case 2:
						guard let r = Double(componentsRefreshRate[1]) else {
							return nil
						}
						refreshRate = r
					default:
						return nil
				}
				
				let componentsResolution = componentsRefreshRate[0].components(separatedBy: CharacterSet(charactersIn: "×x"))
				guard componentsResolution.count == 2 else {
					return nil
				}
				guard let x = Int(componentsResolution[0]),
						let y = Int(componentsResolution[1])
				else {
					return nil
				}
				self = .explicit(x: x, y: y, refreshRate: refreshRate)
		}
	}
	
}

extension DisplayMode : ExpressibleByArgument {}

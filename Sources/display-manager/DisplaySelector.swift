import Foundation

import ArgumentParser



enum DisplaySelector : Hashable {
	
	case all
	case main
	case external(Int)
	
}

extension DisplaySelector : RawRepresentable {
	
	static let externalDisplayPrefix = "ext"
	
	var rawValue: String {
		switch self {
			case .all:  return "all"
			case .main: return "main"
			case .external(let i): return "\(Self.externalDisplayPrefix)\(i)"
		}
	}
	
	init?(rawValue: String) {
		switch rawValue {
			case "all":  self = .all
			case "main": self = .main
			case let str where str.hasPrefix(Self.externalDisplayPrefix):
				let idxStr = str[str.index(str.startIndex, offsetBy: Self.externalDisplayPrefix.count)...]
				guard let idx = Int(idxStr) else {
					return nil
				}
				self = .external(idx)
			default:
				return nil
		}
	}
	
}

extension DisplaySelector : ExpressibleByArgument {}

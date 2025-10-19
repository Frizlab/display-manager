import Foundation

import ArgumentParser



enum HiDPIFilter : Equatable {
	
	case noHiDPIFilter
	case onlyHiDPI
	case noHiDPI
	
}

extension HiDPIFilter : EnumerableFlag {
}

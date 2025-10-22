import CoreGraphics
import Foundation

import ArgumentParser
import Logging

import DisplayManager



struct ShowModes : AsyncParsableCommand {
	
	static let configuration: CommandConfiguration = .init(
		commandName: "show-modes",
		abstract: "Show the modes (resolution, refresh rate, etc.) of one or more displays.",
		aliases: ["show-resolutions", "show"]
	)
	
	@Flag
	var hiDPIFilter: HiDPIFilter = .noHiDPIFilter
	
	enum ModeFilter : String, CaseIterable, ExpressibleByArgument {
		case current, `default`, highest, available
	}
	@Argument
	var modeFilter: ModeFilter = .current
	
	@Argument
	var displaySelectors: [DisplaySelector] = [.main]
	
	func run() async throws {
		DisplayManager.bootstrap()
		
		var outputString = ""
		let displays = try Display.getAllWithResolvedSelector(matching: Set(displaySelectors))
		for (display, selector) in displays {
			let modes = try {
				switch modeFilter {
					case .current: return try [display.getCurrentMode()]
					case .default: return try [display.getDefaultMode()]
					case .highest: return try [display.getHighestMode(hiDPIFilter: hiDPIFilter)]
					case .available: return try display.getAllModesSortedAscending(hiDPIFilter: hiDPIFilter)
				}
			}()
			
			outputString += "Display \(selector.rawValue):\n"
			for mode in modes {
				outputString += "  - \(displayModeToString(mode))\n"
			}
			outputString += "\n"
		}
		print(outputString, terminator: "")
	}
	
	private func displayModeToString(_ mode: CGDisplayMode) -> String {
		let isHiDPI = mode.width < mode.pixelWidth && mode.height < mode.pixelHeight
		var res = "\(mode.width)×\(mode.height)"
		if mode.pixelWidth != mode.width || mode.pixelHeight != mode.height {
			res += " (\(isHiDPI ? "HiDPI:" : "") \(mode.pixelWidth)×\(mode.pixelHeight))"
		}
		res += " \(mode.refreshRate)Hz"
		/* TODO: Rotation */
		return res
	}
	
}

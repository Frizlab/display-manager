import CoreGraphics
import Foundation

import ArgumentParser

import DisplayManager



struct SetMode : AsyncParsableCommand {
	
	static let configuration: CommandConfiguration = .init(
		commandName: "set-mode",
		abstract: "Set the mode (resolution, refresh rate, etc.) of one or more displays.",
		aliases: ["set-resolution", "mode", "res"]
	)
	
	@Flag
	var hiDPIFilter: HiDPIFilter = .noHiDPIFilter
	
	@Argument
	var targetMode: DisplayModeDescription
	
	@Argument
	var displaySelectors: [DisplaySelector] = [.main]
	
	func run() async throws {
		DisplayManager.bootstrap()
		
		let displays = try Display.getAll(matching: Set(displaySelectors))
		
		guard let display = displays.first, displays.count == 1 else {
			print("Oh no!")
			return
		}
		
		print(try display.getAllModes().count)
//		print(try display.getDefaultMode())
		print(try display.getHighestMode())
//		return DPMDisplay.playground()
	}
	
}

import CoreGraphics
import Foundation

import ArgumentParser



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
//		print(try displays.map{ try $0.getAllModes(withDuplicatesLowResolution: true).count })
		print(try displays.map{ try $0.getDefaultMode() })
	}
	
}

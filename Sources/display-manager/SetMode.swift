import CoreGraphics
import Foundation

import ArgumentParser
import Logging

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
		
		var success = true
		let displays = try Display.getAll(matching: Set(displaySelectors))
		for display in displays {
			do {
				let mode = try display.getMode(matching: targetMode, hiDPIFilter: hiDPIFilter)
				print(mode)
			} catch {
				logger.warning("Failed setting mode for a display.", metadata: ["display": "\(display)", "error": "\(error)"])
				success = false
			}
		}
		
		guard success else {
			throw ExitCode(1)
		}
	}
	
}

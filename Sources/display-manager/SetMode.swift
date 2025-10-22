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
				
				var config: CGDisplayConfigRef?
				let beginConfigError = CGBeginDisplayConfiguration(&config)
				guard beginConfigError == .success, let config else {
					throw DisplayManagerError.cgError(beginConfigError)
				}
				let configError = CGConfigureDisplayWithDisplayMode(config, display.id, mode, nil)
				guard configError == .success else {
					if CGCancelDisplayConfiguration(config) != .success {
						logger.error("Failed cancelling display configuration. There ain’t nothing I can do though…")
					}
					throw DisplayManagerError.cgError(configError)
				}
				let completeConfigError = CGCompleteDisplayConfiguration(config, .permanently)
				guard completeConfigError == .success else {
					throw DisplayManagerError.cgError(configError)
				}
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

import Foundation

import ArgumentParser
import CLTLogger
import Logging



@main
struct DisplayManager : AsyncParsableCommand {
	
	static let configuration: CommandConfiguration = .init(
		commandName: "display-manager",
		abstract: "Manage your displays via the command-line.",
		subcommands: [
			SetMode.self,
			ShowModes.self,
		]
	)
	
	static func bootstrap() {
		LoggingSystem.bootstrap(CLTLogger.init, metadataProvider: nil)
	}
	
}

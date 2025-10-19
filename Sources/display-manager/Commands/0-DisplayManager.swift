import Foundation

import ArgumentParser



@main
struct DisplayManager : AsyncParsableCommand {
	
	static let configuration: CommandConfiguration = .init(
		commandName: "display-manager",
		abstract: "Manage your displays via the command-line.",
		subcommands: [
			SetMode.self,
		]
	)
	
}

// swift-tools-version:5.7
import PackageDescription


let commonSwiftSettings: [SwiftSetting] = [
	.unsafeFlags(["-Xfrontend", "-strict-concurrency=complete"])
	/* Swift 5.8+ only. */
//	.enableExperimentalFeature("StrictConcurrency")
]

let package = Package(
	name: "display-manager",
	platforms: [.macOS(.v10_15)],
	products: [.executable(name: "display-manager", targets: ["display-manager"])],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.1.0")
	],
	targets: [
		.executableTarget(name: "display-manager", dependencies: [
			.product(name: "ArgumentParser", package: "swift-argument-parser")
		], swiftSettings: commonSwiftSettings)
	]
)

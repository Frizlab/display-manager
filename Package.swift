// swift-tools-version:5.6
import PackageDescription


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
		])
	]
)

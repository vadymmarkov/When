// swift-tools-version:4.0
import PackageDescription

let package = Package(
	name: "When",
	products: [
		.library(name: "When", targets: ["When"]),
		],
	targets: [
		.target(
			name: "When",
			dependencies: [],
			path: "./Sources/When"),
	]
)
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Hello",
    platforms: [
      .iOS(.v13),
      .macOS(.v10_15),
      .tvOS(.v13),
      .watchOS(.v6),
    ],
    products: [
        .library(
            name: "Extractor",
            targets: ["Extractor"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.76.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent-sqlite-driver.git", from: "4.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.13.0"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
        .package(
            url: "https://github.com/Flight-School/AnyCodable",
            from: "0.6.0"
        ),    
    ],
    targets: [
        .target(name: "App", dependencies: [
            .product(name: "Vapor", package: "vapor"),
            "SwiftSoup",
            "Extractor",
            .product(name: "Fluent", package: "fluent"),
            .product(name: "FluentSQLiteDriver", package: "fluent-sqlite-driver"),
        ]),
        .testTarget(name: "AppTests", dependencies: ["App"]),
        .target(
            name: "Extractor",
            dependencies: [
                "SwiftSoup",
                .product(name: "Parsing", package: "swift-parsing"),
                "AnyCodable"
            ]
        ),
        .testTarget(
            name: "ExtractorTests",
            dependencies: ["Extractor", "SwiftSoup", "AnyCodable"]
        ),
    ]
)

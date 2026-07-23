// swift-tools-version: 6.0
//
//  CricketCore — Phase 0: data & freshness contract.
//  Pure Swift + Foundation/Observation. No CoreBluetooth / App Intents /
//  FoundationModels — those live in the app (Phase 1/2) behind the SensorFeed seam.
//
//  tools-version 6.0 ⇒ Swift 6 language mode ⇒ complete strict concurrency (NFR-4).
//  Platform floors here are the library minimum only; the app target pins iOS 27.
//
import PackageDescription

let package = Package(
    name: "CricketCore",
    platforms: [
        .iOS(.v18),     // library floor only (Observation needs 17+); app pins iOS 27
        .macOS(.v15),   // host platform for `swift test`
    ],
    products: [
        .library(name: "CricketCore", targets: ["CricketCore"]),
    ],
    targets: [
        .target(name: "CricketCore"),
        .testTarget(name: "CricketCoreTests", dependencies: ["CricketCore"]),
    ]
)

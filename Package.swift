// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Braintree",
    platforms: [.iOS(.v14)],
    products: [
        .library(
            name: "BraintreeAmericanExpress",
            targets: ["BraintreeAmericanExpress"]
        ),
        .library(
            name: "BraintreeApplePay",
            targets: ["BraintreeApplePay"]
        ),
        .library(
            name: "BraintreeCard",
            targets: ["BraintreeCard"]
        ),
        .library(
            name: "BraintreeCore",
            targets: ["BraintreeCore2"]
        ),
        .library(
            name: "BraintreeDataCollector",
            targets: ["BraintreeDataCollector", "PPRiskMagnes"]
        ),
        .library(
            name: "BraintreePaymentFlow",
            targets: ["BraintreePaymentFlow", "PPRiskMagnes"]
        ),
        .library(
            name: "BraintreePayPal",
            targets: ["BraintreePayPal", "PPRiskMagnes"]
        ),
        .library(
            name: "BraintreePayPalNativeCheckout",
            targets: ["BraintreePayPalNativeCheckout"]
        ),
        .library(
            name: "BraintreeSEPADirectDebit",
            targets: ["BraintreeSEPADirectDebit"]
        ),
        .library(
            name: "BraintreeThreeDSecure",
            targets: ["BraintreeThreeDSecure", "CardinalMobile", "PPRiskMagnes"]
        ),
        .library(
            name: "BraintreeVenmo",
            targets: ["BraintreeVenmo"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "BraintreeAmericanExpress",
            dependencies: ["BraintreeCore2"]
        ),
        .target(
            name: "BraintreeApplePay",
            dependencies: ["BraintreeCore2"]
        ),
        .target(
            name: "BraintreeCard",
            dependencies: ["BraintreeCore2"],
            publicHeadersPath: "Public"
        ),
        .target(
            name: "BraintreeCore2",
            dependencies: ["BraintreeCoreBinary"]
        ),
        .binaryTarget(
            name: "BraintreeCoreBinary",
            path: "Frameworks/XCFrameworks/BraintreeCoreBinary.xcframework"
        ),
        .target(
            name: "BraintreeDataCollector",
            dependencies: ["BraintreeCore2", "PPRiskMagnes"]
        ),
        .target(
            name: "BraintreePaymentFlow",
            dependencies: ["BraintreeCore2", "BraintreeDataCollector"],
            publicHeadersPath: "Public"
        ),
        .target(
            name: "BraintreePayPal",
            dependencies: ["BraintreeCore2", "BraintreeDataCollector"],
            publicHeadersPath: "Public"
        ),
        .target(
            name: "BraintreePayPalNativeCheckout",
            dependencies: ["BraintreeCore2", "BraintreePayPal", "PayPalCheckout"],
            path: "Sources/BraintreePayPalNativeCheckout"
        ),
        .binaryTarget(
            name: "PayPalCheckout",
            url: "https://github.com/paypal/paypalcheckout-ios/releases/download/0.110.0/PayPalCheckout.xcframework.zip",
            checksum: "e9895c202b090a7bde5c47685e96aef68b6f334e3f3798a79dd49b32c81fe130"
        ),
        .target(
            name: "BraintreeSEPADirectDebit",
            dependencies: ["BraintreeCore2"],
            path: "Sources/BraintreeSEPADirectDebit"
        ),
        .target(
            name: "BraintreeThreeDSecure",
            dependencies: ["BraintreePaymentFlow", "BraintreeCard", "CardinalMobile", "PPRiskMagnes"],
            publicHeadersPath: "Public",
            cSettings: [.headerSearchPath("V2UICustomization")]
        ),
        .binaryTarget(
            name: "CardinalMobile",
            path: "Frameworks/XCFrameworks/CardinalMobile.xcframework"
        ),
        .target(
            name: "BraintreeVenmo",
            dependencies: ["BraintreeCore2"],
            publicHeadersPath: "Public"
        ),
        .binaryTarget(
            name: "PPRiskMagnes",
            path: "Frameworks/XCFrameworks/PPRiskMagnes.xcframework"
        )
    ]
)

import XCTest
import BraintreeCore
@testable import BraintreePayPalNative

class BTPayPalNativeRequest_Tests : XCTestCase {

    private var configuration: BTConfiguration!

    override func setUp() {
        super.setUp()
        let json = BTJSON(value: [
            "paypalEnabled": true,
            "paypal": [
                "environment": "offline"
            ]
        ])

        configuration = BTConfiguration(json: json)
    }

    // MARK: - landingPageTypeAsString

    func testLandingPageTypeAsString_whenLandingPageTypeIsNotSpecified_returnNil() {
        let request = BTPayPalNativeRequest(payPalReturnURL: "returnURL")
        XCTAssertNil(request.landingPageTypeAsString)
    }

    func testLandingPageTypeAsString_whenLandingPageTypeIsBilling_returnsBilling() {
        let request = BTPayPalNativeRequest(payPalReturnURL: "returnURL")
        request.landingPageType = .billing
        XCTAssertEqual(request.landingPageTypeAsString, "billing")
    }

    func testLandingPageTypeAsString_whenLandingPageTypeIsLogin_returnsLogin() {
        let request = BTPayPalNativeRequest(payPalReturnURL: "returnURL")
        request.landingPageType = .login
        XCTAssertEqual(request.landingPageTypeAsString, "login")
    }

    // MARK: - parametersWithConfiguration

    func testParametersWithConfiguration_returnsAllParams() {
        let request = BTPayPalNativeRequest(payPalReturnURL: "returnURL")
        request.isShippingAddressRequired = true
        request.displayName = "Display Name"
        request.landingPageType = .login
        request.localeCode = "locale-code"
        request.merchantAccountID = "merchant-account-id"
        request.isShippingAddressEditable = true

        request.lineItems = [BTPayPalNativeLineItem(quantity: "1", unitAmount: "1", name: "item", kind: .credit)]

        let parameters = request.parameters(with: configuration)
        guard let experienceProfile = parameters["experience_profile"] as? [String : Any] else { XCTFail(); return }

        XCTAssertEqual(experienceProfile["no_shipping"] as? Bool, false)
        XCTAssertEqual(experienceProfile["brand_name"] as? String, "Display Name")
        XCTAssertEqual(experienceProfile["landing_page_type"] as? String, "login")
        XCTAssertEqual(experienceProfile["locale_code"] as? String, "locale-code")
        XCTAssertEqual(parameters["merchant_account_id"] as? String, "merchant-account-id")
        XCTAssertEqual(experienceProfile["address_override"] as? Bool, false)
        XCTAssertEqual(parameters["line_items"] as? [[String : String]], [["quantity": "1",
                                                                           "unit_amount": "1",
                                                                           "name": "item",
                                                                           "kind": "credit"]])

        XCTAssertEqual(parameters["return_url"] as? String, "sdk.ios.braintree://onetouch/v1/success")
        XCTAssertEqual(parameters["cancel_url"] as? String, "sdk.ios.braintree://onetouch/v1/cancel")
    }

    func testParametersWithConfiguration_whenDisplayNameNotSet_usesDisplayNameFromConfig() {
        let request = BTPayPalNativeRequest(payPalReturnURL: "returnURL")

        let json = BTJSON(value: [
            "paypalEnabled": true,
            "paypal": [
                "environment": "offline",
                "displayName": "my display name"
            ]
        ])

        configuration = BTConfiguration(json: json)
        let parameters = request.parameters(with: configuration)
        guard let experienceProfile = parameters["experience_profile"] as? [String : Any] else { XCTFail(); return }

        XCTAssertEqual(experienceProfile["brand_name"] as? String, "my display name")
    }

    func testParametersWithConfiguration_whenShippingAddressIsRequiredNotSet_returnsNoShippingTrue() {
        let request = BTPayPalNativeRequest(payPalReturnURL: "returnURL")
        // no_shipping = true should be the default.

        let parameters = request.parameters(with: configuration)
        guard let experienceProfile = parameters["experience_profile"] as? [String : Any] else { XCTFail(); return }

        XCTAssertEqual(experienceProfile["no_shipping"] as? Bool, true)
    }

    func testParametersWithConfiguration_whenShippingAddressIsRequiredIsTrue_returnsNoShippingFalse() {
        let request = BTPayPalNativeRequest(payPalReturnURL: "returnURL")
        request.isShippingAddressRequired = true

        let parameters = request.parameters(with: configuration)
        guard let experienceProfile = parameters["experience_profile"] as? [String:Any] else { XCTFail(); return }
        XCTAssertEqual(experienceProfile["no_shipping"] as? Bool, false)
    }
}

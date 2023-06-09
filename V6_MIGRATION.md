# Braintree iOS v6 Migration Guide

See the [CHANGELOG](/CHANGELOG.md) for a complete list of changes. This migration guide outlines the basics for updating your client integration from v5 to v6.

_Documentation for v6 will be published to https://developer.paypal.com/braintree/docs once it is available for general release._

## Table of Contents

1. [Supported Versions](#supported-versions)
2. [Carthage](#carthage)
3. [Braintree Core](#braintree-core)
4. [Venmo](#venmo)
5. [PayPal](#paypal)
6. [PayPal Native Checkout](#paypal-native-checkout)
7. [Data Collector](#data-collector)
8. [Union Pay](#union-pay)
9. [SEPA Direct Debit](#sepa-direct-debit)
10. [Payment Flow](#payment-flow)
11. [American Express](#american-express)
12. [Apple Pay](#apple-pay)
13. [Card](#card)

## Supported Versions

v6 supports a minimum deployment target of iOS 14+. It requires the use of Xcode 14+ and Swift version 5.7+. If your application contains Objective-C code, the `Enable Modules` build setting must be set to `YES`.

## Carthage

v6 requires Carthage v0.38.0+, which adds support for xcframework binary dependencies.

```
carthage update --use-xcframeworks
```

## Braintree Core
`BTAppContextSwitchDriver` has been renamed to `BTAppContextSwitchClient`

`BTViewControllerPresentingDelegate` protocol functions `paymentDriver` are renamed to `paymentClient` now takes in the `client` parameter instead of `driver`:
```
public func paymentClient(_ client: Any, requestsDismissalOf viewController: UIViewController) {
    // implementation here
}

public func paymentClient(_ client: Any, requestsPresentationOf viewController: UIViewController) {
    // implementation here
}
```

## Venmo
`BTVenmoDriver` has been renamed to `BTVenmoClient`

`BTVenmoRequest` must now be initialized with a `paymentMethodUsage`. 

The possible values for `BTVenmoPaymentMethodUsage` include:
* `.multiUse` - the Venmo payment will be authorized for future payments and can be vaulted.
* `.singleUse` - the Venmo payment will be authorized for a one-time payment and cannot be vaulted.

`BTVenmoClient.tokenizeVenmoAccount(with:completion:)` has been renamed to `BTVenmoClient.tokenize(_:completion:)`

`BTVenmoClient.isiOSAppAvailableForAppSwitch()` has been renamed to `BTVenmoClient.isVenmoAppInstalled()`

```
let apiClient = BTAPIClient("<TOKENIZATION_KEY_OR_CLIENT_TOKEN>")
let venmoClient = BTVenmoClient(apiClient: apiClient)
let venmoRequest = BTVenmoRequest(paymentMethodUsage: .multiUse)
venmoRequest.profileID = "my-profile-id"
venmoRequest.vault = true

venmoClient.tokenize(venmoRequest) { venmoAccountNonce, error in
    guard let venmoAccountNonce = venmoAccountNonce else {
        // handle error
    }
    // send nonce to server
}
```

## PayPal
`BTPayPalDriver` has been renamed to `BTPayPalClient`

The property `BTPayPalRequest.activeWindow` has been removed

Removed `BTPayPalDriver.requestOneTimePayment` and `BTPayPalDriver.requestBillingAgreement` in favor of `BTPayPalClient.tokenize`:
```
let apiClient = BTAPIClient("<TOKENIZATION_KEY_OR_CLIENT_TOKEN>")
let payPalClient = BTPayPalClient(apiClient: apiClient)
let request = BTPayPalCheckoutRequest(amount: "1")

payPalClient.tokenize(request) { payPalAccountNonce, error in
    guard let payPalAccountNonce = payPalAccountNonce else {
        // handle error
    }
    // send nonce to server
}
```

`BTPayPalClient.tokenizePayPalAccount(with:completion:)` has been replaced with two methods called: `BTPayPalClient.tokenize(_:completion:)` taking in either a `BTPayPalCheckoutRequest` or `BTPayPalVaultRequest`

```
// BTPayPalCheckoutRequest
let apiClient = BTAPIClient("<TOKENIZATION_KEY_OR_CLIENT_TOKEN>")
let payPalClient = BTPayPalClient(apiClient: apiClient)
let request = BTPayPalCheckoutRequest(amount: "1")
payPalClient.tokenize(request) { payPalAccountNonce, error in 
    // handle response
}

// BTPayPalVaultRequest
let apiClient = BTAPIClient("<TOKENIZATION_KEY_OR_CLIENT_TOKEN>")
let payPalClient = BTPayPalClient(apiClient: apiClient)
let request = BTPayPalVaultRequest()
payPalClient.tokenize(request) { payPalAccountNonce, error in 
    // handle response
}
```

## PayPal Native Checkout
`BTPayPalNativeCheckoutClient.tokenizePayPalAccount(with:completion:` has been replaced with two methods called: `tokenize(_:completion:)` taking in either a `BTPayPalNativeCheckoutRequest` or `BTPayPalNativeVaultRequest`

```
// BTPayPalNativeCheckoutRequest
let apiClient = BTAPIClient("<TOKENIZATION_KEY_OR_CLIENT_TOKEN>")
let payPalNativeCheckoutClient = BTPayPalNativeCheckoutClient(apiClient: apiClient)
let request = BTPayPalNativeCheckoutRequest(amount: "1")
payPalNativeCheckoutClient.tokenize(request) { payPalNativeCheckoutAccountNonce, error in 
    // handle response
}

// BTPayPalNativeVaultRequest
let apiClient = BTAPIClient("<TOKENIZATION_KEY_OR_CLIENT_TOKEN>")
let payPalNativeCheckoutClient = BTPayPalNativeCheckoutClient(apiClient: apiClient)
let request = BTPayPalNativeVaultRequest()
payPalNativeCheckoutClient.tokenize(request) { payPalNativeCheckoutAccountNonce, error in 
    // handle response
}
```

## Data Collector
Note: Kount is no longer supported through the SDK in this version. Kount will continue to be supported in v5 of the SDK.

`PayPalDataCollector` module has been removed. All data collection for payment flows will use the `BraintreeDataCollector` module.

For merchants collecting device data for PayPal and Local Payment methods will now need to replace the `PayPalDataCollector` module with the `BraintreeDataCollector` module in their integration.

The new integration for collecting device data will look like the following:
```
let apiClient = BTAPIClient("<TOKENIZATION_KEY_OR_CLIENT_TOKEN>")
let dataCollector = BTDataCollector(apiClient: apiClient)

dataCollector.collectDeviceData { deviceData, error in
    // handle response
}
```

## Union Pay
The `BraintreeUnionPay` module, and all containing classes, was removed in v6. UnionPay cards can now be processed as regular cards, through the `BraintreeCard` module. You no longer need to manage card enrollment via SMS authorization. 

Now, you can tokenize just with the card details:

```
let apiClient = BTAPIClient("<TOKENIZATION_KEY_OR_CLIENT_TOKEN>")
let cardClient = BTCardClient(apiClient: apiClient)

let card = BTCard()
card.number = "4111111111111111"
card.expirationMonth = "12"
card.expirationYear = "2025"

cardClient.tokenize(card) { tokenizedCard, error in
    // handle response
}
```

## SEPA Direct Debit
We have removed the `context` parameter from the `BTSEPADirectDebit.tokenize()` method. Additionally, conformance to the `ASWebAuthenticationPresentationContextProviding` protocol is no longer needed.

`BTSEPADirectDebitClient.tokenize(request:context:completion:)` has been renamed to `BTSEPADirectDebitClient.tokenize(_:completion:)`

The updated `tokenize` method is as follows:
```
let apiClient = BTAPIClient("<TOKENIZATION_KEY_OR_CLIENT_TOKEN>")
let sepaDirectDebitClient = BTSEPADirectDebitClient(apiClient: apiClient)

sepaDirectDebitClient.tokenize(sepaDirectDebitRequest) { sepaDirectDebitNonce, error in
    // handle response
}
```

## Payment Flow
The following changes apply to both 3D Secure and Local Payment Methods as they both use the underlying Payment Flow module:

We have replaced `SFAuthenticationSession` with `ASWebAuthenticationSession` in the Local Payment Method and 3D Secure flows. With this change, you no longer need to register a URL Schemes for these flows or set a return URL via the `BTAppContextSwitcher.setReturnURLScheme()` method or handle app context switching via the `BTAppContextSwitcher.handleOpenURL(context: UIOpenURLContext)` or `BTAppContextSwitcher.handleOpenURL(URL)` methods.

Your view no longer needs to conform to the `BTViewControllerPresentingDelegate` protocol. The methods `BTPaymentFlowClient.paymentClient(BTPaymentFlowClient, requestsPresentationOfViewController: UIViewController)` and `BTPaymentFlowClient.paymentClient(BTPaymentFlowClient, requestsDismissalOfViewController: UIViewController)` have been removed. 

Additionally, you do not need to assign the `BTPaymentFlowClient.viewControllerPresentingDelegate` property in your view.

## American Express
`BTAmericanExpressClient.getRewardsBalance(forNonce:currencyIsoCode:completion:)` has been renamed to `BTAmericanExpressClient.getRewardsBalance(forNonce:currencyISOCode:completion:)`

## Apple Pay
`BTApplePayClient.tokenizeApplePay(_:completion:)` has been renamed to `BTApplePayClient.tokenize(_:completion:)`

`BTApplePayClient.paymentRequest()` has been renamed to `BTApplePayClient.makePaymentRequest()`

## Card
`BTCardClient.tokenizeCard(_:completion)` has been renamed to `BTCardClient.tokenize(_:completion)`

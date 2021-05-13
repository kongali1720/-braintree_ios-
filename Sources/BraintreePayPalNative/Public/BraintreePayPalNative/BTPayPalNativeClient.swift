import BraintreeCore
import PayPalCheckout

@objc public class BTPayPalNativeClient: NSObject {

    // MARK: - Public

    /**
     Domain for PayPal errors.
     */
    // TODO: - is this the right naming convention?
    @objc public static let errorDomain = "com.braintreepayments.BTPayPalNativeClientErrorDomain"

    /**
     Error codes associated with PayPal.
     */
    @objc public enum ErrorType: Int {
        /// Unknown error
        case unknown
        /// PayPal is disabled in configuration
        case disabled
        /// Invalid request, e.g. missing PayPal request
        case invalidRequest
        /// Braintree SDK is integrated incorrectly
        case integration
        /// Payment flow was canceled, typically initiated by the user when exiting early from the flow.
        case canceled
    }

    /**
     Initializes a PayPal client.

     - Parameter apiClient: The Braintree API client

     - Returns: A PayPal client
     */
    @objc public init(apiClient: BTAPIClient) {
        self.apiClient = apiClient
    }

    /**
     Tokenize a PayPal account for vault or checkout.

     @note You can use this as the final step in your order/checkout flow. If you want, you may create a transaction from your
     server when this method completes without any additional user interaction.

     On success, you will receive an instance of `BTPayPalAccountNonce`; on failure or user cancelation you will receive an error. If the user cancels out of the flow, the error code will be `BTPayPalDriverErrorTypeCanceled`.

     @param request Either a BTPayPalCheckoutRequest or a BTPayPalVaultRequest
     @param completionBlock This completion will be invoked exactly once when tokenization is complete or an error occurs.
    */
    // TODO: - use Error instead of NSError?
    @objc(tokenizePayPalAccountWithPayPalRequest:completion:)
    public func tokenizePayPalAccount(with request: BTPayPalNativeRequest, completion: @escaping (BTPayPalNativeAccountNonce?, NSError?) -> Void) {
        guard request is BTPayPalNativeCheckoutRequest || request is BTPayPalNativeVaultRequest else {
            let error = NSError(domain: BTPayPalNativeClient.errorDomain,
                                code: ErrorType.integration.rawValue,
                                userInfo: [NSLocalizedDescriptionKey: "BTPayPalNativeClient failed because request is not of type BTPayPalNativeCheckoutRequest or BTPayPalNativeVaultRequest."])

            completion(nil, error)
            return
        }

        constructBTPayPalNativeSDKRequest(with: request) { (nativeSDKRequest, error) in
            guard let nativeRequest = nativeSDKRequest, error == nil else {
                // call completion with error
                return
            }

            let payPalNativeConfig = CheckoutConfig(clientID: nativeRequest.payPalClientID,
                                                    returnUrl: request.payPalReturnURL,
                                                    createOrder: nil,
                                                    onApprove: nil,
                                                    onCancel: nil,
                                                    onError: nil,
                                                    environment: nativeRequest.environment)
        }
    }

    // MARK: - Internal

    struct BTPayPalNativeSDKRequest {
        let payPalClientID: String
        let environment: Int
        let orderID: String
    }

    private let apiClient: BTAPIClient

    func constructBTPayPalNativeSDKRequest(with request: BTPayPalNativeRequest, completion: @escaping (BTPayPalNativeSDKRequest?, NSError?) -> Void) {

        apiClient.fetchOrReturnRemoteConfiguration { configuration, error in
            if let err = error as NSError? {
                completion(nil, err)
                return
            }

            guard let config = configuration else {
                let configError = NSError(domain: BTPayPalNativeClient.errorDomain,
                                          code: ErrorType.unknown.rawValue,
                                          userInfo: [NSLocalizedDescriptionKey: "Failed to fetch Braintree configuration."])
                completion(nil, configError)
                return
            }

            guard config.json["paypalEnabled"].isTrue else {
                self.apiClient.sendAnalyticsEvent("ios.paypal-otc.preflight.disabled") // TODO: - change analytics events for native flow?
                let payPalDisabledError = NSError(domain: BTPayPalNativeClient.errorDomain,
                                                  code: ErrorType.disabled.rawValue,
                                                  userInfo: [NSLocalizedDescriptionKey: "PayPal is not enabled for this merchant",
                                                             NSLocalizedRecoverySuggestionErrorKey: "Enable PayPal for this merchant in the Braintree Control Panel"])
                completion(nil, payPalDisabledError)
                return
            }

            guard let payPalClientID = config.json["paypal"]["clientId"].asString() else {
                let clientIDError = NSError(domain: BTPayPalNativeClient.errorDomain,
                                            code: ErrorType.disabled.rawValue,
                                            userInfo: [NSLocalizedDescriptionKey: "Failed to fetch PayPalClientID from Braintree configuration."])
                completion(nil, clientIDError)
                return
            }

            guard let environment = config.environment, environment == "sandbox" || environment == "production" else {
                let environmentError = NSError(domain: BTPayPalNativeClient.errorDomain,
                                               code: ErrorType.unknown.rawValue,
                                               userInfo: [NSLocalizedDescriptionKey: "PayPal Native Checkout failed because an invalid environment identifier was retrieved from the configuration."])
                completion(nil, environmentError)
                return
            }

            let env = (environment == "production") ? 0 : 1

            self.apiClient.post(request.hermesPath, parameters: request.parameters(with: config)) { json, response, error in
                if var err = error as NSError? {
                    // TODO: are these errorDetails useful for merchant-facing errors? Should we continue parsing this error or instead return a static merchant-friendly message.
                    if let errorJSON = err.userInfo[NSLocalizedDescriptionKey].map({ BTJSON(value: $0) }),
                       let issue = errorJSON["paymentResources"]["errorDetails"].asArray()?.first?["issue"].asString(),
                       err.userInfo[NSLocalizedDescriptionKey] == nil {
                        var userInfo = err.userInfo
                        userInfo[NSLocalizedDescriptionKey] = issue
                        err = NSError(domain: err.domain, code: err.code, userInfo: userInfo)
                    }

                    completion(nil, err)
                    return
                }

                let approvalURL: URL
                if let url = json?["paymentResource"]["redirectUrl"].asURL() {
                    approvalURL = url
                } else if let url = json?["agreementSetup"]["approvalUrl"].asURL() {
                    approvalURL = url
                } else {
                    let error = NSError(domain: BTPayPalNativeClient.errorDomain,
                                        code: ErrorType.unknown.rawValue,
                                        userInfo: [NSLocalizedDescriptionKey: "Failed to fetch PayPal approvalURL."])
                    completion(nil, error)
                    return
                }

                let orderIDFromApprovalURL = URLComponents(url: approvalURL, resolvingAgainstBaseURL: false)?
                    .queryItems?
                    .first(where: { $0.name == "token" || $0.name == "ba_token" })?
                    .value

                guard let orderID = orderIDFromApprovalURL else {
                    let error = NSError(domain: BTPayPalNativeClient.errorDomain,
                                        code: ErrorType.unknown.rawValue,
                                        userInfo: [NSLocalizedDescriptionKey: "Failed to fetch PayPal order id."])
                    completion(nil, error)
                    return
                }

                let nativeSDKRequest = BTPayPalNativeSDKRequest(payPalClientID: payPalClientID, environment: env, orderID: orderID)
                completion(nativeSDKRequest, nil)
            }
        }
    }
}

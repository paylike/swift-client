# Paylike - high-level API library

[![build_test](https://github.com/kocsislaci/swift-client/actions/workflows/build_test.yml/badge.svg?branch=main)](https://github.com/kocsislaci/swift-client/actions/workflows/build_test.yml)

Client implementation for Swift.

This implementation is based on [Paylike/JS-Client](https://github.com/paylike/js-client)

## Install

__SPM__:
```swift
// dependencies: 
.package(url: "git@github.com:paylike/swift-client.git", .upToNextMajor(from: "0.2.0"))

// target:
.product(name: "PaylikeClient", package: "swift-client")
```

__Cocoapods__:
https://cocoapods.org/pods/PaylikeClient
```ruby
pod 'PaylikeClient'
```

## Usage

First you need to create a merchant account on [our platform](https://paylike.io)

Before you can start the payment flow you need to tokenize the card number and the CVC code of the given card you are trying to charge.

Example of tokenization:

```swift
import PaylikeClient

let client = PaylikeClient()

/**
    COMPLETION HANDLER BASED USAGE
    ------------------
*/
client.tokenize(type: PaylikeTokenizedTypes.PCN, value: "4100000000000000") { result in
    // Save tokenized card number...
}

/**
    ASYNC USAGE
    ------------------
*/
Task {
    let response = try await client.tokenize(type: PaylikeTokenizedTypes.PCN, value: "4100000000000000")
}

/**
    SYNC USAGE
    ----------
*/
client.tokenizeSync(type: PaylikeTokenizedTypes.PCSC, value: "123") { result in 
    // Save tokenized card security code...
}
```

After the tokenization is done, you can now start the payment flow. You need to collect 12 hints (assuming that TDS is enabled) before your payment is considered finished and committed. `paymentCreate` function is constructed to work in a recursive way automatically resolving challenges as much as possible.

For more information on the flow please check our [API reference](https://github.com/paylike/api-reference).

Example:

```swift
import PaylikeClient

/**
    ASYNC USAGE
    ----------
*/
// Previously got tokenized data:
let (numberToken, cvcToken) = ("RESULT_OF_TOKENIZE", "RESULT_OF_TOKENIZE")

let integrationKey = PaymentIntegration(merchantId: key)
let paymentAmount = PaymentAmount(currency: .EUR, value: 1, exponent: 0)
let expiry = try CardExpiry(month: 12, year: 26)
let card = PaymentCard(number: numberToken, code: cvcToken, expiry: expiry)
var createPaymentRequest = CreatePaymentRequest(with: card, merchantID: integrationKey)
createPaymentRequest.amount = paymentAmount

Task {
    let clientResponse = try await client.createPayment(with: &createPaymentRequest)
}
```

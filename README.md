# Paylike - high-level API library

[![build_test](https://github.com/kocsislaci/swift-client/actions/workflows/build_test.yml/badge.svg?branch=main)](https://github.com/kocsislaci/swift-client/actions/workflows/build_test.yml)

Client implementation for Swift.

This implementation is based on [Paylike/JS-Client](https://github.com/paylike/js-client)

## Install

__SPM__:
```swift
// dependencies: 
.package(url: "git@github.com:paylike/swift-client.git", .upToNextMajor(from: "0.1.0"))

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

let client = PaylikeClient(log: { item in
    print(item) // Item is encodable
})

/**
    FUTURE BASED USAGE
    ------------------
*/
let promise = client.tokenize(type: PaylikeTokenizedTypes.PCN, value: "4100000000000000")
var bag: Set<AnyCancellable> = []
promise.sink(receiveCompletion: { completion in
    switch completion {
    case .failure(let error):
        print(error)
    default:
        return
    }
}, receiveValue: { (cardNumberTokenized: String) in
    // Save tokenized card number....
}).store(in: &bag)

/**
    SYNC USAGE
    ----------
*/
let (cvcTokenized, error) = client.tokenizeSync(type: PaylikeTokenizedTypes.PCSC, value: "123")
```

After the tokenization is done, you can now start the payment flow. You need to collect 12 hints (assuming that TDS is enabled) before your payment is considered finished and committed. `paymentCreate` function is constructed to work in a recursive way automatically resolving challenges as much as possible.

For more information on the flow please check our [API reference](https://github.com/paylike/api-reference).

Example:

```swift
import PaylikeClient
import PaylikeMoney // This is required to create PaymentAmount structs

let (cardNumberTokenized, cvcTokenized) = ("RESULT_OF_TOKENIZE", "RESULT_OF_TOKENIZE")

/**
    FUTURE BASED USAGE
    ------------------
*/
let dto = PaymentRequestDTO(key: key)
dto.amount = try PaylikeMoney.fromDouble(currency: "EUR", n: 5.0)
dto.card = PaymentRequestCardDTO(number: cardNumberTokenized, month: 12, year: 26, code: cvcTokenized)
let promise = client.paymentCreate(payment: dto, hints: [])
var bag: Set<AnyCancellable> = []
promise.sink(receiveCompletion: { completion in
    switch completion {
    case .failure(let error):
        print(error)
    default:
        return
    }
}, receiveValue: { (response: PaylikeClientResponse) in
    /// Render HTML (to continue with TDS) or save authorization ID of the transaction
}).store(in: &bag)

/**
    SYNC USAGE
    ----------
*/
let (response, error) = client.paymentCreateSync(payment: dto, hints: [])
```

import PaylikeClient

extension TokenizeApplePayDataRequest : Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        
        let token: String = try container.decode(String.self, forKey: .token)
        
        self.init(token: token)
    }
    private enum Keys : String, CodingKey {
        case token
    }
}

extension TokenizeCardDataRequest : Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        
        let type: CardDataType = try container.decode(CardDataType.self, forKey: .type)
        let value: String = try container.decode(String.self, forKey: .value)
        
        self.init(type: type, value: value)
    }
    private enum Keys : String, CodingKey {
        case type
        case value
    }
}

extension CardDataType : Decodable {}

extension CreatePaymentResponse : Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        
        try container.encode(challenges, forKey: .challenges)
        try container.encode(hints, forKey: .hints)
        try container.encode(action, forKey: .action)
        try container.encode(method, forKey: .method)
        try container.encode(fields, forKey: .fields)
        try container.encode(timeout, forKey: .timeout)
        try container.encode(authorizationId, forKey: .authorizationId)
        try container.encode(transactionId, forKey: .transactionId)
    }
    
    private enum Keys : String, CodingKey {
        case challenges
        case hints
        case action
        case method
        case fields
        case timeout
        case authorizationId
        case transactionId
    }
}

extension ChallengeResponse : Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(path, forKey: .path)
    }
    
    private enum Keys : String, CodingKey {
        case name
        case type
        case path
    }
}

extension ChallengeTypes : Encodable {}

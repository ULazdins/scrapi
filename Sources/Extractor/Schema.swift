import Parsing

public enum Value: Equatable {
    case string, number, bool, attribute(String)
}

public indirect enum Schema: Equatable {
    case value(Value)
    case selector(String, Schema)
    case object([String: Schema])
    case array(String, Schema)
}

extension Schema: Codable {
    public func encode(to encoder: Encoder) throws {
        let string = try SchemaParser().print(self)
        var container = encoder.singleValueContainer()
        try container.encode(String(string))
    }
    
    public init(from decoder: Decoder) throws {
        let string = try decoder.singleValueContainer().decode(String.self)
        self = try SchemaParser().parse(string)
    }
}

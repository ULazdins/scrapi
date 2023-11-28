import Parsing

public enum Value {
    case string, number, bool
}

public indirect enum Schema: Equatable {
    case value(Value)
    case selector(String, Schema)
    case object([String: Schema])
//    case array(Self)
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

struct SchemaParser: ParserPrinter {
    var body: some ParserPrinter<Substring.UTF8View, Schema> {
        OneOf {
            ValueParser().map(.case(Output.value))
            SelectorString().map(.case(Output.selector))
            ObjectParser().map(.case(Output.object))
        }
    }
    
    struct ValueParser: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, Value> {
            OneOf {
                "Number".utf8.map(.case(Value.number))
                "String".utf8.map(.case(Value.string))
                "Boolean".utf8.map(.case(Value.bool))
            }
        }
    }
    
    struct JSONString: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, String> {
            "\"".utf8
            Many(into: "") { string, fragment in
                string.append(contentsOf: fragment)
            } decumulator: { string in
                string.map(String.init).reversed().makeIterator()
            } element: {
                OneOf {
                    Prefix(1) { $0.isUnescapedJSONStringByte }.map(.string)
                    
                    Parse {
                        "\\".utf8
                        
                        OneOf {
                            "\"".utf8.map { "\"" }
                            "\\".utf8.map { "\\" }
                            "/".utf8.map { "/" }
                            "b".utf8.map { "\u{8}" }
                            "f".utf8.map { "\u{c}" }
                            "n".utf8.map { "\n" }
                            "r".utf8.map { "\r" }
                            "t".utf8.map { "\t" }
                            ParsePrint(.unicode) {
                                Prefix(4) { $0.isHexDigit }
                            }
                        }
                    }
                }
            } terminator: {
                "\"".utf8
            }
        }
    }
    
    struct SelectorString: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, (String, Schema)> {
            JSONString()
            " -> ".utf8
            SchemaParser()
        }
    }
    
    struct ObjectParser: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, [String: Schema]> {
            "{".utf8
            Many(into: [String: Schema]()) { object, pair in
                let (name, value) = pair
                object[name] = value
            } decumulator: { object in
                (object.sorted(by: { $0.key < $1.key }) as [(String, Schema)])
                    .reversed()
                    .makeIterator()
            } element: {
                Whitespace()
                JSONString()
                Whitespace()
                ":".utf8
                SchemaParser()
            } separator: {
                ",".utf8
            } terminator: {
                "}".utf8
            }
        }
    }
    
    struct Array: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, Schema> {
            "[".utf8
            SchemaParser()
            "]".utf8
        }
    }
}


extension UTF8.CodeUnit {
    fileprivate var isHexDigit: Bool {
        (.init(ascii: "0") ... .init(ascii: "9")).contains(self)
        || (.init(ascii: "A") ... .init(ascii: "F")).contains(self)
        || (.init(ascii: "a") ... .init(ascii: "f")).contains(self)
    }
    
    fileprivate var isUnescapedJSONStringByte: Bool {
        self != .init(ascii: "\"") && self != .init(ascii: "\\") && self >= .init(ascii: " ")
    }
}

extension Conversion where Self == AnyConversion<Substring.UTF8View, String> {
    fileprivate static var unicode: Self {
        Self(
            apply: {
                UInt32(Substring($0), radix: 16)
                    .flatMap(UnicodeScalar.init)
                    .map(String.init)
            },
            unapply: {
                $0.unicodeScalars.first
                    .map { String(UInt32($0), radix: 16)[...].utf8 }
            }
        )
    }
}

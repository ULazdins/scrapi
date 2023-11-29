import Parsing

struct SchemaParser: ParserPrinter {
    var body: some ParserPrinter<Substring.UTF8View, Schema> {
        OneOf {
            ValueParser().map(.case(Output.value))
            SelectorString().map(.case(Output.selector))
            ObjectParser().map(.case(Output.object))
            ArrayParser().map(.case(Output.array))
        }
    }
    
    struct ValueParser: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, Value> {
            OneOf {
                "Number".utf8.map(.case(Value.number))
                "String".utf8.map(.case(Value.string))
                "Boolean".utf8.map(.case(Value.bool))
                AttributeParser().map(.case(Value.attribute))
            }
        }
        
        struct AttributeParser: ParserPrinter {
            var body: some ParserPrinter<Substring.UTF8View, String> {
                "Attribute[".utf8
                Whitespace()
                Prefix(while: {
                    $0.isLetter
                }).map(.string)
                Whitespace()
                "]".utf8
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
            Whitespace()
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
                Whitespace()
                SchemaParser()
            } separator: {
                ",".utf8
            } terminator: {
                Whitespace()
                "}".utf8
            }
        }
    }
    
    struct ArrayParser: ParserPrinter {
        var body: some ParserPrinter<Substring.UTF8View, (String, Schema)> {
            "[".utf8
            Whitespace()
            JSONString()
            Whitespace()
            ":".utf8
            Whitespace()
            SchemaParser()
            Whitespace()
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
    
    fileprivate var isLetter: Bool {
        (.init(ascii: "A") ... .init(ascii: "Z")).contains(self)
        || (.init(ascii: "a") ... .init(ascii: "z")).contains(self)
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

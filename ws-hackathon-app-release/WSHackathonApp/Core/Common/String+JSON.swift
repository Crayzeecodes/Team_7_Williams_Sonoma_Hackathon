import Foundation

extension String {
    /// Sanitizes raw unescaped control characters (such as newlines, carriage returns, and tabs) 
    /// that reside within JSON string values, preventing JSONDecoder from throwing errors.
    func sanitizingJSONControlCharacters() -> String {
        var result = ""
        var insideString = false
        var isEscaped = false
        
        for char in self {
            if char == "\"" {
                if !isEscaped {
                    insideString.toggle()
                }
                isEscaped = false
                result.append(char)
            } else if char == "\\" {
                if insideString {
                    isEscaped.toggle()
                }
                result.append(char)
            } else {
                isEscaped = false
                if insideString {
                    if char == "\n" {
                        result.append("\\n")
                    } else if char == "\r" {
                        result.append("\\r")
                    } else if char == "\t" {
                        result.append("\\t")
                    } else if let scalar = char.unicodeScalars.first, scalar.value < 32 {
                        let hex = String(scalar.value, radix: 16, uppercase: true)
                        let padding = String(repeating: "0", count: max(0, 4 - hex.count))
                        result.append("\\u\(padding)\(hex)")
                    } else {
                        result.append(char)
                    }
                } else {
                    result.append(char)
                }
            }
        }
        return result
    }
}

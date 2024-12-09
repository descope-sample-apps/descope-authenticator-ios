
import Foundation
import CryptoKit

extension Key {
    static let scheme = "otpauth"
    static let type = "totp"

    enum ParseDefaults {
        static let algorithm = Algorithm.sha1
        static let digits = 6
        static let period = 30
    }

    enum ParseError: String, Error {
        case malformed
        case unsupported
    }

    static func parse(url: URL) throws(ParseError) -> (Key, Data) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else { throw ParseError.malformed }
        let params = queryItems.reduce(into: [:], { params, item in params[item.name] = item.value })

        guard components.scheme == Key.scheme else { throw ParseError.malformed }
        guard components.host == Key.type else { throw ParseError.unsupported }

        var algorithm = ParseDefaults.algorithm
        if let str = params["algorithm"] {
            guard let value = Algorithm(rawValue: str.lowercased()) else { throw ParseError.unsupported }
            algorithm = value
        }

        var digits = ParseDefaults.digits
        if let str = params["digits"] {
            guard let value = Int(str), value == 6 || value == 8 else { throw ParseError.unsupported }
            digits = value
        }

        var period = ParseDefaults.period
        if let str = params["period"] {
            guard let value = Int(str), value == 30 else { throw ParseError.unsupported } // only support 30secs period for now
            period = value
        }

        guard let secretString = params["secret"], let secret = Data(base32Encoded: secretString) else { throw ParseError.unsupported }

        // skip the first slash in the path to get the full label
        let label = components.path.dropFirst()
        
        let separator = label.contains(":") ? ":" : "%3A"
        let parts = label.components(separatedBy: separator)

        let username = parts.last?.trimmingCharacters(in: .whitespaces) ?? ""

        var issuer = params["issuer"]?.trimmingCharacters(in: .whitespaces) ?? ""
        if issuer.isEmpty, parts.count >= 2 {
            issuer = parts[0].trimmingCharacters(in: .whitespaces)
        }

        let key = Key(issuer: issuer, username: username, algorithm: algorithm, digits: digits, period: period)
        return (key, secret)
    }
}

extension Key {
    func generateCode(with secret: Data, at date: Date = .now) -> String {
        return generateTOTP(secret: secret, algorithm: algorithm, digits: digits, period: period, date: date)
    }
}

private func generateTOTP(secret: Data, algorithm: Key.Algorithm, digits: Int, period: Int, date: Date) -> String {
    let counter = Int(Double(date.timeIntervalSince1970) / Double(period))
    return generateHOTP(secret: secret, algorithm: algorithm, digits: digits, counter: counter)
}

private func generateHOTP(secret: Data, algorithm: Key.Algorithm, digits: Int, counter: Int) -> String {
    let hash = generateHash(secret: secret, algorithm: algorithm, counter: counter)
    let offset = Int(hash.last!) & 0x0f
    let value = UInt32(hash[offset]) | (UInt32(hash[offset + 1]) << 8) | (UInt32(hash[offset + 2]) << 16) | (UInt32(hash[offset + 3]) << 24)
    let number = value.bigEndian & 0x7fffffff
    let code = number % UInt32(pow(10, Float(digits)))
    let padded = String(format: "%0*u", digits, Int(code))
    return padded
}

private func generateHash(secret: Data, algorithm: Key.Algorithm, counter: Int) -> Data {
    var message = UInt64(counter).bigEndian
    let data = Data(bytes: &message, count: MemoryLayout.size(ofValue: message))
    let key = SymmetricKey(data: secret)
    switch algorithm {
    case .sha1: return Data(HMAC<Insecure.SHA1>.authenticationCode(for: data, using: key))
    case .sha256: return Data(HMAC<SHA256>.authenticationCode(for: data, using: key))
    case .sha512: return Data(HMAC<SHA512>.authenticationCode(for: data, using: key))
    }
}

private extension Data {
    init?(base32Encoded base32String: String) {
        var result: [UInt8] = []

        var bits: UInt8 = 0
        var value: UInt32 = 0

        for ch in base32String {
            guard let ascii = ch.asciiValue else { return nil }

            let ordinal: UInt8
            switch ascii {
            case 65...90: ordinal = ascii - 65 // "A"..."Z"
            case 97...122: ordinal = ascii - 97 // "a"..."z"
            case 50...55: ordinal = 26 + (ascii - 50) // "2"..."7"
            default: return nil
            }

            value = (value << 5) | UInt32(ordinal)

            bits += 5
            if bits >= 8 {
                bits -= 8
                result.append(UInt8((value >> bits) & 0xFF))
            }
        }

        self = Data(result)
    }
}

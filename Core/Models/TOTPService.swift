import Foundation
import CryptoKit

/// RFC 6238 TOTP implementation. Pure value-type, no side effects.
struct TOTPService: Sendable {

    /// Generate a TOTP code for a token at a given date.
    func generateCode(for token: Token, at date: Date = Date()) -> String {
        guard let keyData = base32Decode(token.secret) else {
            return String(repeating: "-", count: token.digits)
        }
        let counter = UInt64(date.timeIntervalSince1970) / UInt64(token.period)
        let hmac = computeHMAC(key: keyData, counter: counter, algorithm: token.algorithm)
        let code = truncate(hmac: hmac, digits: token.digits)
        return String(format: "%0\(token.digits)d", code)
    }

    /// Remaining seconds in the current period.
    func remainingSeconds(period: Int, at date: Date = Date()) -> Int {
        let seconds = Int(date.timeIntervalSince1970)
        return period - (seconds % period)
    }

    /// Progress through the current period (0.0 = start, 1.0 = end).
    func progress(period: Int, at date: Date = Date()) -> Double {
        let seconds = date.timeIntervalSince1970
        let elapsed = seconds.truncatingRemainder(dividingBy: Double(period))
        return elapsed / Double(period)
    }

    /// Validate a Base32 string.
    func isValidBase32(_ string: String) -> Bool {
        let cleaned = string.uppercased().replacingOccurrences(of: " ", with: "")
        let base32Charset = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567=")
        return !cleaned.isEmpty
            && cleaned.unicodeScalars.allSatisfy { base32Charset.contains($0) }
    }

    /// Parse an `otpauth://totp/...` URI into a Token.
    func parseOTPAuthURL(_ urlString: String) -> Token? {
        guard let url = URL(string: urlString),
              url.scheme == "otpauth",
              url.host == "totp" else { return nil }

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let params = Dictionary(
            uniqueKeysWithValues: (components?.queryItems ?? [])
                .compactMap { item in item.value.map { (item.name.lowercased(), $0) } }
        )

        guard let secret = params["secret"], isValidBase32(secret) else { return nil }

        // Label from path: /Issuer:account or /account
        let label = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let parts = label.split(separator: ":", maxSplits: 1)
        let issuer = params["issuer"] ?? (parts.count > 1 ? String(parts[0]) : label)
        let account = parts.count > 1 ? String(parts[1]) : ""

        let digits = params["digits"].flatMap(Int.init) ?? 6
        let period = params["period"].flatMap(Int.init) ?? 30
        let algorithm: TOTPAlgorithm = {
            switch params["algorithm"]?.uppercased() {
            case "SHA256": .sha256
            case "SHA512": .sha512
            default:       .sha1
            }
        }()

        return Token(
            issuer: issuer, account: account, secret: secret,
            digits: digits, period: period, algorithm: algorithm
        )
    }

    // MARK: - Base32 Decode (RFC 4648)

    func base32Decode(_ input: String) -> Data? {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        let lookup: [Character: UInt8] = Dictionary(
            uniqueKeysWithValues: alphabet.enumerated().map {
                (Character(String($0.element)), UInt8($0.offset))
            }
        )

        let cleaned = input.uppercased().replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "=", with: "")

        var bits = 0
        var buffer: UInt64 = 0
        var output = Data()

        for char in cleaned {
            guard let value = lookup[char] else { return nil }
            buffer = (buffer << 5) | UInt64(value)
            bits += 5
            if bits >= 8 {
                bits -= 8
                output.append(UInt8((buffer >> bits) & 0xFF))
            }
        }
        return output
    }

    // MARK: - Private HMAC

    private func computeHMAC(key: Data, counter: UInt64, algorithm: TOTPAlgorithm) -> Data {
        var bigEndianCounter = counter.bigEndian
        let message = Data(bytes: &bigEndianCounter, count: MemoryLayout<UInt64>.size)
        let symmetricKey = SymmetricKey(data: key)

        switch algorithm {
        case .sha1:
            let auth = HMAC<Insecure.SHA1>.authenticationCode(for: message, using: symmetricKey)
            return Data(auth)
        case .sha256:
            let auth = HMAC<SHA256>.authenticationCode(for: message, using: symmetricKey)
            return Data(auth)
        case .sha512:
            let auth = HMAC<SHA512>.authenticationCode(for: message, using: symmetricKey)
            return Data(auth)
        }
    }

    private func truncate(hmac: Data, digits: Int) -> Int {
        let offset = Int(hmac[hmac.count - 1] & 0x0F)
        let code = (Int(hmac[offset]) & 0x7F) << 24
            | (Int(hmac[offset + 1]) & 0xFF) << 16
            | (Int(hmac[offset + 2]) & 0xFF) << 8
            | (Int(hmac[offset + 3]) & 0xFF)
        let mod = Int(pow(10.0, Double(digits)))
        return code % mod
    }
}

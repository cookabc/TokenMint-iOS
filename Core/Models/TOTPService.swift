import Foundation

/// Pure computation TOTP service — no mutable state, safe for concurrent use.
struct TOTPService: Sendable {
    /// Generate a TOTP code for the given token at the specified time.
    func generateCode(for token: Token, at date: Date = Date()) -> String {
        // TODO: W8 — implement HMAC-based TOTP (RFC 6238)
        let placeholder = String(repeating: "0", count: token.digits)
        return placeholder
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
}

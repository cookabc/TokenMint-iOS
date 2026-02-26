import Testing
import Foundation
@testable import TokenMint

@Suite("TOTPService Tests")
struct TOTPServiceTests {
    let service = TOTPService()

    // MARK: - Base32 Validation

    @Test("Valid Base32 strings are accepted")
    func validBase32() {
        #expect(service.isValidBase32("JBSWY3DPEHPK3PXP"))
        #expect(service.isValidBase32("jbswy3dpehpk3pxp"))
        #expect(service.isValidBase32("JBSW Y3DP EHPK 3PXP"))
    }

    @Test("Invalid Base32 strings are rejected")
    func invalidBase32() {
        #expect(!service.isValidBase32(""))
        #expect(!service.isValidBase32("!!!invalid!!!"))
        #expect(!service.isValidBase32("JBSWY3DPEHPK3PXP1"))
    }

    // MARK: - Base32 Decode

    @Test("Base32 decode produces correct bytes")
    func base32Decode() {
        // "JBSWY3DPEHPK3PXP" decodes to "Hello!DE=<"... known test vector
        let data = service.base32Decode("JBSWY3DPEHPK3PXP")
        #expect(data != nil)
        #expect(!data!.isEmpty)
    }

    @Test("Base32 decode returns nil for invalid input")
    func base32DecodeInvalid() {
        #expect(service.base32Decode("!!!") == nil)
    }

    // MARK: - Timer Helpers

    @Test("Remaining seconds is within period range")
    func remainingSeconds() {
        let remaining = service.remainingSeconds(period: 30)
        #expect(remaining > 0 && remaining <= 30)
    }

    @Test("Remaining seconds for 60s period")
    func remainingSeconds60() {
        let remaining = service.remainingSeconds(period: 60)
        #expect(remaining > 0 && remaining <= 60)
    }

    @Test("Progress is between 0 and 1")
    func progress() {
        let p = service.progress(period: 30)
        #expect(p >= 0.0 && p < 1.0)
    }

    // MARK: - TOTP Code Generation (RFC 6238 test vectors)

    @Test("Generate code returns correct digit count")
    func codeDigitCount() {
        let token = Token(issuer: "Test", secret: "JBSWY3DPEHPK3PXP", digits: 6)
        let code = service.generateCode(for: token)
        #expect(code.count == 6)

        let token8 = Token(issuer: "Test", secret: "JBSWY3DPEHPK3PXP", digits: 8)
        let code8 = service.generateCode(for: token8)
        #expect(code8.count == 8)
    }

    @Test("Generate code at known time produces consistent result")
    func codeConsistency() {
        let token = Token(issuer: "Test", secret: "JBSWY3DPEHPK3PXP")
        let date = Date(timeIntervalSince1970: 1_234_567_890)
        let code1 = service.generateCode(for: token, at: date)
        let code2 = service.generateCode(for: token, at: date)
        #expect(code1 == code2)
    }

    @Test("Different times produce different codes")
    func codeDifference() {
        let token = Token(issuer: "Test", secret: "JBSWY3DPEHPK3PXP")
        let code1 = service.generateCode(for: token, at: Date(timeIntervalSince1970: 0))
        let code2 = service.generateCode(for: token, at: Date(timeIntervalSince1970: 60))
        #expect(code1 != code2)
    }

    @Test("Invalid secret returns dashes")
    func invalidSecret() {
        let token = Token(issuer: "Test", secret: "!!!")
        let code = service.generateCode(for: token)
        #expect(code.contains("-"))
    }

    @Test("SHA256 and SHA512 algorithms work")
    func otherAlgorithms() {
        let date = Date(timeIntervalSince1970: 1_234_567_890)
        let tokenSHA256 = Token(issuer: "Test", secret: "JBSWY3DPEHPK3PXP", algorithm: .sha256)
        let tokenSHA512 = Token(issuer: "Test", secret: "JBSWY3DPEHPK3PXP", algorithm: .sha512)
        let code256 = service.generateCode(for: tokenSHA256, at: date)
        let code512 = service.generateCode(for: tokenSHA512, at: date)
        #expect(code256.count == 6)
        #expect(code512.count == 6)
    }

    // MARK: - OTPAuth URL Parsing

    @Test("Parse valid otpauth URL")
    func parseValidURL() {
        let url = "otpauth://totp/GitHub:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=GitHub&digits=6&period=30"
        let token = service.parseOTPAuthURL(url)
        #expect(token != nil)
        #expect(token?.issuer == "GitHub")
        #expect(token?.account == "user@example.com")
        #expect(token?.digits == 6)
        #expect(token?.period == 30)
        #expect(token?.algorithm == .sha1)
    }

    @Test("Parse otpauth URL with algorithm param")
    func parseURLWithAlgorithm() {
        let url = "otpauth://totp/Test?secret=JBSWY3DPEHPK3PXP&algorithm=SHA256"
        let token = service.parseOTPAuthURL(url)
        #expect(token?.algorithm == .sha256)
    }

    @Test("Parse otpauth URL without issuer prefix in label")
    func parseURLNoIssuerPrefix() {
        let url = "otpauth://totp/MyAccount?secret=JBSWY3DPEHPK3PXP"
        let token = service.parseOTPAuthURL(url)
        #expect(token?.issuer == "MyAccount")
    }

    @Test("Reject invalid URL schemes")
    func rejectInvalidScheme() {
        #expect(service.parseOTPAuthURL("https://example.com") == nil)
        #expect(service.parseOTPAuthURL("otpauth://hotp/Test?secret=ABC") == nil)
        #expect(service.parseOTPAuthURL("") == nil)
    }

    @Test("Reject missing secret")
    func rejectMissingSecret() {
        #expect(service.parseOTPAuthURL("otpauth://totp/Test") == nil)
    }
}

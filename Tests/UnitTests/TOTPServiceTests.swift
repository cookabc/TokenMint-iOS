import Testing
@testable import TokenMint

@Suite("TOTPService Tests")
struct TOTPServiceTests {
    let service = TOTPService()

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

    @Test("Remaining seconds is within period range")
    func remainingSeconds() {
        let remaining = service.remainingSeconds(period: 30)
        #expect(remaining > 0 && remaining <= 30)
    }

    @Test("Progress is between 0 and 1")
    func progress() {
        let p = service.progress(period: 30)
        #expect(p >= 0.0 && p < 1.0)
    }
}

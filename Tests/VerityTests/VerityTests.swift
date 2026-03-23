import XCTest
@testable import Verity

final class VerityTests: XCTestCase {

    private func fixturePath(_ relativePath: String) throws -> String {
        guard let url = Bundle.module.url(
            forResource: relativePath,
            withExtension: nil,
            subdirectory: "Fixtures"
        ) else {
            throw XCTSkip("Fixture not found: \(relativePath)")
        }
        return url.path
    }

    private func tempSchemeDir(_ name: String) -> String {
        let dir = NSTemporaryDirectory() + "verity_test_\(name)"
        try? FileManager.default.removeItem(atPath: dir)
        return dir
    }

    func testProveKitBackendPrepareProveVerify() throws {
        let verity = try Verity(backend: .provekit)
        let schemeDir = tempSchemeDir("provekit")

        defer { try? FileManager.default.removeItem(atPath: schemeDir) }

        try verity.prepare(
            circuit: fixturePath("circuit.json"),
            output: schemeDir
        )

        let proof = try verity.prove(
            scheme: schemeDir,
            input: fixturePath("Prover.toml")
        )
        XCTAssertFalse(proof.isEmpty, "Proof should not be empty")

        let valid = try verity.verify(
            proof: proof,
            scheme: schemeDir
        )
        XCTAssertTrue(valid, "ProveKit proof should verify")
    }

    func testBarretenbergBackendPrepareProveVerify() throws {
        let verity = try Verity(backend: .barretenberg)
        let schemeDir = tempSchemeDir("barretenberg")

        defer { try? FileManager.default.removeItem(atPath: schemeDir) }

        try verity.prepare(
            circuit: fixturePath("circuit.json"),
            output: schemeDir
        )

        let proof = try verity.prove(
            scheme: schemeDir,
            input: fixturePath("Prover.toml")
        )
        XCTAssertFalse(proof.isEmpty, "Proof should not be empty")

        let valid = try verity.verify(
            proof: proof,
            scheme: schemeDir
        )
        XCTAssertTrue(valid, "Barretenberg proof should verify")
    }
}

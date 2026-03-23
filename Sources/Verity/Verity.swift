import Foundation
import VerityFFI

/// Available proving backends.
public enum Backend {
    /// ProveKit WHIR backend (transparent, hash-based).
    case provekit
    /// Barretenberg UltraHonk backend (KZG commitments).
    case barretenberg
}

/// Verity — generate and verify zero-knowledge proofs.
///
/// Usage:
/// ```swift
/// // Prover side
/// let verity = try Verity(backend: .provekit)
/// try verity.prepare(circuit: "circuit.json", output: "/tmp/scheme")
/// let proof = try verity.prove(scheme: "/tmp/scheme", input: "input.toml")
///
/// // Verifier side
/// let verifier = try Verity(backend: .provekit)
/// let valid = try verifier.verify(proof: proof, scheme: "/tmp/scheme")
/// ```
public final class Verity {
    private static var initialized = false
    private let backend: Backend

    /// Create a Verity instance with the specified backend.
    ///
    /// Automatically initializes the library on first use.
    public init(backend: Backend) throws {
        if !Verity.initialized {
            let code = pk_init()
            guard code == 0 else {
                throw VerityError.ffiError(code: code)
            }
            Verity.initialized = true
        }
        self.backend = backend
    }

    /// Prepare a circuit for proving and verification.
    ///
    /// Compiles the circuit into backend-specific scheme files in the output
    /// directory. The directory is created if it doesn't exist.
    ///
    /// - Parameters:
    ///   - circuit: Path to the compiled circuit (ACIR JSON from `nargo compile`).
    ///   - output: Path to the output directory for scheme files.
    public func prepare(circuit: String, output: String) throws {
        let code: Int32
        switch backend {
        case .provekit:
            code = pk_prepare(circuit, output)
        case .barretenberg:
            code = bb_prepare(circuit, output)
        }
        guard code == 0 else {
            throw VerityError.fromCode(code)
        }
    }

    /// Generate a proof.
    ///
    /// - Parameters:
    ///   - scheme: Path to the scheme directory created by `prepare()`.
    ///   - input: Path to input file (.toml).
    /// - Returns: Proof bytes as `Data`.
    public func prove(scheme: String, input: String) throws -> Data {
        switch backend {
        case .provekit:
            return try provePK(scheme: scheme, input: input)
        case .barretenberg:
            return try proveBB(scheme: scheme, input: input)
        }
    }

    /// Verify a proof.
    ///
    /// - Parameters:
    ///   - proof: Proof bytes (from `prove()`).
    ///   - scheme: Path to the scheme directory created by `prepare()`.
    /// - Returns: `true` if proof is valid.
    public func verify(proof: Data, scheme: String) throws -> Bool {
        let code: Int32
        switch backend {
        case .provekit:
            code = proof.withUnsafeBytes { bytes -> Int32 in
                guard let base = bytes.baseAddress else { return 1 }
                return pk_verify(
                    base.assumingMemoryBound(to: UInt8.self),
                    UInt(proof.count),
                    scheme
                )
            }
        case .barretenberg:
            code = proof.withUnsafeBytes { bytes -> Int32 in
                guard let base = bytes.baseAddress else { return 1 }
                return bb_verify(
                    base.assumingMemoryBound(to: UInt8.self),
                    UInt(proof.count),
                    scheme
                )
            }
        }

        switch code {
        case 0: return true
        case 4: return false
        default: throw VerityError.fromCode(code)
        }
    }

    // MARK: - Private

    private func provePK(scheme: String, input: String) throws -> Data {
        var buf = PKBuf(ptr: nil, len: 0, cap: 0)
        let code = pk_prove(scheme, input, &buf)

        guard code == 0 else { throw VerityError.fromCode(code) }
        guard let ptr = buf.ptr, buf.len > 0 else {
            throw VerityError.proofFailed("empty proof returned")
        }

        let data = Data(bytes: ptr, count: Int(buf.len))
        pk_free_buf(buf)
        return data
    }

    private func proveBB(scheme: String, input: String) throws -> Data {
        var buf = BBBuf(ptr: nil, len: 0, cap: 0)
        let code = bb_prove(scheme, input, &buf)

        guard code == 0 else { throw VerityError.fromCode(code) }
        guard let ptr = buf.ptr, buf.len > 0 else {
            throw VerityError.proofFailed("empty proof returned")
        }

        let data = Data(bytes: ptr, count: Int(buf.len))
        bb_free_buf(buf)
        return data
    }
}

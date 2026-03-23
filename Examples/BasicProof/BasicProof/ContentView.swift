import SwiftUI
import Verity

struct ContentView: View {
    @State private var status = "Ready"
    @State private var proofHex = ""
    @State private var isRunning = false

    /// Paths — update these to point at your compiled circuit and input file.
    private let circuitPath = Bundle.main.path(forResource: "circuit", ofType: "json") ?? ""
    private let inputPath = Bundle.main.path(forResource: "Prover", ofType: "toml") ?? ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                GroupBox("Status") {
                    Text(status)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.callout.monospaced())
                }

                if !proofHex.isEmpty {
                    GroupBox("Proof (\(proofHex.count / 2) bytes)") {
                        Text(proofHex.prefix(120) + "...")
                            .font(.caption.monospaced())
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                Spacer()

                Button(action: runFlow) {
                    Label("Prepare → Prove → Verify", systemImage: "lock.shield")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRunning)
            }
            .padding()
            .navigationTitle("ZK SDK Example")
        }
    }

    private func runFlow() {
        isRunning = true
        status = "Initializing..."
        proofHex = ""

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let verity = try Verity(backend: .provekit)

                // 1. Prepare
                update("Preparing circuit...")
                let schemeDir = FileManager.default.temporaryDirectory
                    .appendingPathComponent("verity_example").path
                try verity.prepare(circuit: circuitPath, output: schemeDir)

                // 2. Prove
                update("Generating proof...")
                let proof = try verity.prove(scheme: schemeDir, input: inputPath)

                // 3. Verify
                update("Verifying proof...")
                let valid = try verity.verify(proof: proof, scheme: schemeDir)

                let hex = proof.map { String(format: "%02x", $0) }.joined()

                DispatchQueue.main.async {
                    proofHex = hex
                    status = valid ? "Proof VALID" : "Proof INVALID"
                    isRunning = false
                }
            } catch {
                DispatchQueue.main.async {
                    status = "Error: \(error.localizedDescription)"
                    isRunning = false
                }
            }
        }
    }

    private func update(_ msg: String) {
        DispatchQueue.main.async { status = msg }
    }
}

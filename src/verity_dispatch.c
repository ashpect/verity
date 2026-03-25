/**
 * Verity dispatch layer — routes unified verity_* calls to the
 * appropriate backend based on the VerityBackend enum.
 *
 * ProveKit uses pk_prove_to_json / pk_verify_json with pre-compiled
 * .pkp/.pkv files. Barretenberg has the full prepare -> prove -> verify flow.
 */

#include "verity_ffi.h"
#include <stddef.h>
#include <string.h>
#include <stdio.h>

/* Union for type-punning between layout-compatible buffer types. */
typedef union {
    VerityBuf verity;
    PKBuf     pk;
    BBBuf     bb;
} BufUnion;

int verity_init(void) {
    return pk_init();
}

int verity_prepare(VerityBackend backend, const char *circuit_path, const char *output_dir) {
    switch (backend) {
        case VERITY_BACKEND_PROVEKIT: {
            /* pk_prepare(program, pkp_out, pkv_out, hash)
               Convention: output_dir will contain prover.pkp + verifier.pkv */
            char pkp_path[4096];
            char pkv_path[4096];
            snprintf(pkp_path, sizeof(pkp_path), "%s/prover.pkp", output_dir);
            snprintf(pkv_path, sizeof(pkv_path), "%s/verifier.pkv", output_dir);
            return pk_prepare(circuit_path, pkp_path, pkv_path, NULL);
        }
        case VERITY_BACKEND_BARRETENBERG:
            return bb_prepare(circuit_path, output_dir);
        default:
            return VERITY_INVALID_INPUT;
    }
}

int verity_prove(VerityBackend backend, const char *scheme_dir, const char *input_path, VerityBuf *out_buf) {
    if (scheme_dir == NULL || input_path == NULL || out_buf == NULL) {
        return VERITY_INVALID_INPUT;
    }

    BufUnion u = { .verity = { .ptr = NULL, .len = 0, .cap = 0 } };
    int code;

    switch (backend) {
        case VERITY_BACKEND_PROVEKIT: {
            /* ProveKit expects the .pkp path directly.
               Convention: scheme_dir contains "prover.pkp". */
            char pkp_path[4096];
            snprintf(pkp_path, sizeof(pkp_path), "%s/prover.pkp", scheme_dir);
            code = pk_prove_to_json(pkp_path, input_path, &u.pk);
            break;
        }
        case VERITY_BACKEND_BARRETENBERG:
            code = bb_prove(scheme_dir, input_path, &u.bb);
            break;
        default:
            return VERITY_INVALID_INPUT;
    }

    *out_buf = u.verity;
    return code;
}

int verity_verify(VerityBackend backend, const uint8_t *proof_ptr, uintptr_t proof_len, const char *scheme_dir) {
    if (proof_ptr == NULL || proof_len == 0 || scheme_dir == NULL) {
        return VERITY_INVALID_INPUT;
    }

    switch (backend) {
        case VERITY_BACKEND_PROVEKIT: {
            /* pk_verify_json takes verifier.pkv path + proof JSON bytes. */
            char pkv_path[4096];
            snprintf(pkv_path, sizeof(pkv_path), "%s/verifier.pkv", scheme_dir);
            return pk_verify_json(pkv_path, proof_ptr, proof_len);
        }
        case VERITY_BACKEND_BARRETENBERG:
            return bb_verify(proof_ptr, proof_len, scheme_dir);
        default:
            return VERITY_INVALID_INPUT;
    }
}

void verity_free_buf(VerityBackend backend, VerityBuf buf) {
    if (buf.ptr == NULL) return;

    BufUnion u;
    u.verity = buf;

    switch (backend) {
        case VERITY_BACKEND_PROVEKIT:
            pk_free_buf(u.pk);
            break;
        case VERITY_BACKEND_BARRETENBERG:
            bb_free_buf(u.bb);
            break;
        default:
            break;
    }
}

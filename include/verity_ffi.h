#ifndef VERITY_FFI_H
#define VERITY_FFI_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// ---- Unified types ----

// Unified buffer used by the dispatch API
typedef struct {
    uint8_t *ptr;
    uintptr_t len;
    uintptr_t cap;
} VerityBuf;

// Backend selection
typedef enum {
    VERITY_BACKEND_PROVEKIT = 0,
    VERITY_BACKEND_BARRETENBERG = 1,
} VerityBackend;

// Error codes (shared by all backends)
typedef enum {
    VERITY_SUCCESS = 0,
    VERITY_INVALID_INPUT = 1,
    VERITY_SCHEME_READ_ERROR = 2,
    VERITY_WITNESS_READ_ERROR = 3,
    VERITY_PROOF_ERROR = 4,
    VERITY_SERIALIZATION_ERROR = 5,
    VERITY_UTF8_ERROR = 6,
    VERITY_FILE_WRITE_ERROR = 7,
} VerityError;

// ---- Unified API (dispatches to the selected backend) ----

int verity_init(void);
int verity_prepare(VerityBackend backend, const char *circuit_path, const char *output_dir);
int verity_prove(VerityBackend backend, const char *scheme_dir, const char *input_path, VerityBuf *out_buf);
int verity_verify(VerityBackend backend, const uint8_t *proof_ptr, uintptr_t proof_len, const char *scheme_dir);
void verity_free_buf(VerityBackend backend, VerityBuf buf);

// ---- Backend-specific types & functions (implemented by backend authors) ----

// --- ProveKit WHIR backend (maintained in provekit repo) ---

typedef struct { uint8_t *ptr; uintptr_t len; uintptr_t cap; } PKBuf;

int pk_init(void);
int pk_configure_memory(uintptr_t ram_limit_bytes, bool use_file_backed, const char *swap_file_path);
int pk_get_memory_stats(uintptr_t *ram_used, uintptr_t *swap_used, uintptr_t *peak_ram);
void pk_free_buf(PKBuf buf);

// Prepare: compile circuit into .pkp + .pkv (hash can be NULL for default "skyscraper")
int pk_prepare(const char *program_path, const char *pkp_path, const char *pkv_path, const char *hash);

// Prove: takes .pkp prover scheme path, returns proof as JSON bytes or writes to file
int pk_prove_to_file(const char *prover_path, const char *input_path, const char *out_path);
int pk_prove_to_json(const char *prover_path, const char *input_path, PKBuf *out_buf);

// Verify: takes .pkv verifier path + proof (as file path or JSON bytes)
int pk_verify_file(const char *verifier_path, const char *proof_path);
int pk_verify_json(const char *verifier_path, const uint8_t *proof_json, uintptr_t proof_json_len);

// --- Barretenberg UltraHonk backend ---

typedef struct { uint8_t *ptr; uintptr_t len; uintptr_t cap; } BBBuf;

int bb_prepare(const char *circuit_path, const char *output_dir);
int bb_prove(const char *scheme_dir, const char *input_path, BBBuf *out_buf);
int bb_verify(const uint8_t *proof_ptr, uintptr_t proof_len, const char *scheme_dir);
void bb_free_buf(BBBuf buf);

#ifdef __cplusplus
}
#endif

#endif // VERITY_FFI_H

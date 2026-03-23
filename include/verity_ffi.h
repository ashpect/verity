#ifndef VERITY_FFI_H
#define VERITY_FFI_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// Buffer for returning data from FFI functions
typedef struct {
    uint8_t *ptr;
    uintptr_t len;
    uintptr_t cap;
} PKBuf;

// Barretenberg buffer (same layout as PKBuf)
typedef struct {
    uint8_t *ptr;
    uintptr_t len;
    uintptr_t cap;
} BBBuf;

// Error codes (shared by both backends)
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

// --- ProveKit WHIR backend (pk_*) ---

// Initialize ProveKit (call once before any pk_* function)
int pk_init(void);

// Configure memory allocator (call before pk_init)
int pk_configure_memory(uintptr_t ram_limit_bytes, bool use_file_backed, const char *swap_file_path);

// Get memory statistics
int pk_get_memory_stats(uintptr_t *ram_used, uintptr_t *swap_used, uintptr_t *peak_ram);

// Prepare a circuit (writes prover.pkp + verifier.pkv to output_dir)
int pk_prepare(const char *circuit_path, const char *output_dir);

// Prove (scheme_dir from pk_prepare, returns proof bytes in buffer)
int pk_prove(const char *scheme_dir, const char *input_path, PKBuf *out_buf);

// Verify (scheme_dir from pk_prepare)
int pk_verify(const uint8_t *proof_ptr, uintptr_t proof_len, const char *scheme_dir);

// Legacy: prove to file (takes .pkp path directly)
int pk_prove_to_file(const char *prover_path, const char *input_path, const char *out_path);

// Legacy: prove to JSON buffer (takes .pkp path directly)
int pk_prove_to_json(const char *prover_path, const char *input_path, PKBuf *out_buf);

// Free a buffer allocated by pk_* functions
void pk_free_buf(PKBuf buf);

// --- Barretenberg UltraHonk backend (bb_*) ---

// Prepare a circuit (writes circuit.json + vk.bin to output_dir)
int bb_prepare(const char *circuit_path, const char *output_dir);

// Prove (scheme_dir from bb_prepare, returns proof bytes in buffer)
int bb_prove(const char *scheme_dir, const char *input_path, BBBuf *out_buf);

// Verify (scheme_dir from bb_prepare)
int bb_verify(const uint8_t *proof_ptr, uintptr_t proof_len, const char *scheme_dir);

// Free a buffer allocated by bb_* functions
void bb_free_buf(BBBuf buf);

#ifdef __cplusplus
}
#endif

#endif // VERITY_FFI_H

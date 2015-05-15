#ifndef __C_WRAPPER_H__
#define __C_WRAPPER_H__

#define PRIVATE                 0
#define PUBLIC                  1
#define DECRYPT_SEND            0
#define ENCRYPT_SEND            1 

// set to 1 or 0 if these lines to add/remove debug print statements
#define PRINTVERBOSE            1

void store_keys(int type, int32_t *key_1, int32_t *key_2);
void send_int_encrypt_decrypt(int action, int32_t *message_n, int32_t *output);
void read_output(int32_t *bit_output);
void __read_public_keys(int32_t *key_1, int32_t *key_2);
void read_our_public_key(int32_t *our_key);
void __read_encryption(int32_t *encryption);
void store_d (int32_t *d); 
void set_fd();
void print_128_bit_integer(int32_t *input_x);
void read_our_N(int32_t *n);
void __read_decryption(int32_t *decryption); 
void key_swap(int32_t *p, int32_t *q, int32_t *our_n);
void send_cyphertext(int32_t *m);

#endif

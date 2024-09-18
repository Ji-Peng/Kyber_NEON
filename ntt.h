#ifndef NTT_H
#define NTT_H

#include <stdint.h>
#include "params.h"

#define zetas KYBER_NAMESPACE(_zetas)
extern const int16_t zetas[128];

#define zetas1 KYBER_NAMESPACE(_zetas1)
extern const int16_t zetas1[128];

#define zetas2 KYBER_NAMESPACE(_zetas2)
extern const int16_t zetas2[128];

#define ntt KYBER_NAMESPACE(_ntt)
void ntt(int16_t poly[256]);

#define invntt KYBER_NAMESPACE(_invntt)
void invntt(int16_t poly[256]);

#define basemul KYBER_NAMESPACE(_basemul)
void basemul(int16_t r[2], const int16_t a[2], const int16_t b[2], int16_t zeta);

extern void ntt7(const int16_t *a, int16_t *b);     //a = zeta，b = poly

extern void intt7(const int16_t *a, int16_t *b);    //a = zeta，b = poly
//void rev(const int16_t* p);

#endif

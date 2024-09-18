#ifndef REDUCE_H
#define REDUCE_H

#include <stdint.h>
#include "params.h"
#include "poly.h"

#define MONT 2285 // 2^16 mod q
#define QINV 62209 // q^-1 mod 2^16

#define montgomery_reduce KYBER_NAMESPACE(_montgomery_reduce)
int16_t montgomery_reduce(int32_t a);
extern void poly_montgomery_reduce(poly *a);

#define barrett_reduce KYBER_NAMESPACE(_barrett_reduce)
int16_t barrett_reduce(int16_t a);
extern void poly_barrett_reduce(poly *a);

#define specialized_reduce KYBER_NAMESPACE(_specialized_reduce)
int16_t specialized_reduce(int16_t a);

#endif

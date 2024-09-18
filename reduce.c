#include <stdint.h>
#include "params.h"
#include "reduce.h"

/*************************************************
* Name:        montgomery_reduce
*
* Description: Montgomery reduction; given a 32-bit integer a, computes
*              16-bit integer congruent to a * R^-1 mod q, where R=2^16
*
* Arguments:   - int32_t a: input integer to be reduced;
*                           has to be in {-q2^15,...,q2^15-1}
*
* Returns:     integer in {-q+1,...,q-1} congruent to a * R^-1 modulo q.
**************************************************/
int16_t montgomery_reduce(int32_t a)
{
  int32_t t;
  int16_t u;

  u = a*QINV;
  t = (int32_t)u*KYBER_Q;
  t = a - t;
  t >>= 16;
  return t;
}

/*************************************************
* Name:        barrett_reduce
*
* Description: Barrett reduction; given a 16-bit integer a, computes
*              centered representative congruent to a mod q in {-(q-1)/2,...,(q-1)/2}
*
* Arguments:   - int16_t a: input integer to be reduced
*
* Returns:     integer in {-(q-1)/2,...,(q-1)/2} congruent to a modulo q.
**************************************************/
int16_t barrett_reduce(int16_t a) {
  int16_t t;
  const int16_t v = ((1U << 14) + KYBER_Q/2)/KYBER_Q;

  // t  = ((int32_t)v*a + (1<<25)) >> 26;
  // t  = ((int32_t)v*a + (1<<13)) >> 14;
  t = (v*(a>>3) + (1<<10)) >> 11;
  t *= KYBER_Q;
  return a - t;   //return integer in {-q,...,q} congruent to a modulo q
}

int16_t specialized_reduce(int16_t a) {
  int16_t t,u;
  t = a >> 12;
  u = a & 0x0fff;
  t = t * 767;
  t += u;
  return t;   //return integer in {-6138,...,9464} congruent to a modulo q
}
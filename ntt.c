#include <stdint.h>
#include "params.h"
#include "ntt.h"
#include "reduce.h"

#include <stdio.h>
#include "cpucycles.h"
#define LOOP 1


/* Code to generate zetas and zetas_inv used in the number-theoretic transform:

#define KYBER_ROOT_OF_UNITY 17

static const uint8_t tree[128] = {
  0, 64, 32, 96, 16, 80, 48, 112, 8, 72, 40, 104, 24, 88, 56, 120,
  4, 68, 36, 100, 20, 84, 52, 116, 12, 76, 44, 108, 28, 92, 60, 124,
  2, 66, 34, 98, 18, 82, 50, 114, 10, 74, 42, 106, 26, 90, 58, 122,
  6, 70, 38, 102, 22, 86, 54, 118, 14, 78, 46, 110, 30, 94, 62, 126,
  1, 65, 33, 97, 17, 81, 49, 113, 9, 73, 41, 105, 25, 89, 57, 121,
  5, 69, 37, 101, 21, 85, 53, 117, 13, 77, 45, 109, 29, 93, 61, 125,
  3, 67, 35, 99, 19, 83, 51, 115, 11, 75, 43, 107, 27, 91, 59, 123,
  7, 71, 39, 103, 23, 87, 55, 119, 15, 79, 47, 111, 31, 95, 63, 127
};

void init_ntt() {
  unsigned int i;
  int16_t tmp[128];

  tmp[0] = MONT;
  for(i=1;i<128;i++)
    tmp[i] = fqmul(tmp[i-1],MONT*KYBER_ROOT_OF_UNITY % KYBER_Q);

  for(i=0;i<128;i++) {
    zetas[i] = tmp[tree[i]];
    if(zetas[i] > KYBER_Q/2)
      zetas[i] -= KYBER_Q;
    if(zetas[i] < -KYBER_Q/2)
      zetas[i] += KYBER_Q;
  }
}
*/

const int16_t zetas[128] = {
  -1044,  -758,  -359, -1517,  1493,  1422,   287,   202,
   -171,   622,  1577,   182,   962, -1202, -1474,  1468,
    573, -1325,   264,   383,  -829,  1458, -1602,  -130,
   -681,  1017,   732,   608, -1542,   411,  -205, -1571,
   1223,   652,  -552,  1015, -1293,  1491,  -282, -1544,
    516,    -8,  -320,  -666, -1618, -1162,   126,  1469,
   -853,   -90,  -271,   830,   107, -1421,  -247,  -951,
   -398,   961, -1508,  -725,   448, -1065,   677, -1275,
  -1103,   430,   555,   843, -1251,   871,  1550,   105,
    422,   587,   177,  -235,  -291,  -460,  1574,  1653,
   -246,   778,  1159,  -147,  -777,  1483,  -602,  1119,
  -1590,   644,  -872,   349,   418,   329,  -156,   -75,
    817,  1097,   603,   610,  1322, -1285, -1465,   384,
  -1215,  -136,  1218, -1335,  -874,   220, -1187, -1659,
  -1185, -1530, -1278,   794, -1510,  -854,  -870,   478,
   -108,  -308,   996,   991,   958, -1460,  1522,  1628
};

const int16_t zetas1[128] = {
  -1044,  -758,  -359, -1517,  
  
   1493,  -171,   622,   573, -1325,   264,   383,
   1223,   652,  -552,  1015, -1293,  1491,  -282, -1544,
  -1103,   430,   555,   843, -1251,   871,  1550,   105,
    422,   587,   177,  -235,  -291,  -460,  1574,  1653,

   1422,  1577,   182,  -829,  1458, -1602,  -130,
    516,    -8,  -320,  -666, -1618, -1162,   126,  1469,
   -246,   778,  1159,  -147,  -777,  1483,  -602,  1119,
  -1590,   644,  -872,   349,   418,   329,  -156,   -75,
    
    287,    962, -1202, -681,  1017,   732,   608,
   -853,   -90,  -271,   830,    107, -1421,  -247,  -951,
    817,  1097,   603,   610,   1322, -1285, -1465,   384,
  -1215,  -136,  1218, -1335,   -874,   220, -1187, -1659,

    202, -1474,  1468, -1542,    411,  -205, -1571,
   -398,   961, -1508,  -725,    448, -1065,   677, -1275,
  -1185, -1530, -1278,   794,  -1510,  -854,  -870,   478,
   -108,  -308,   996,   991,    958, -1460,  1522,  1628
};

// void rev(const int16_t* p) {
//   unsigned int i;
//   int16_t zeta2[31];
//   for(i=0;i<31;i++) {
//     zeta2[i]=*(p+30-i);
//     printf("%6d,",zeta2[i]);
//   }
// }

const int16_t zetas2[128] = {
   1628,  1522, -1460,   958,   991,   996,  -308,  -108,
    478,  -870,  -854, -1510,   794, -1278, -1530, -1185,
  -1275,   677, -1065,   448,  -725, -1508,   961,  -398,
  -1571,  -205,   411, -1542,  1468, -1474,   202,

  -1659, -1187,   220,  -874, -1335,  1218,  -136, -1215,   
    384, -1465, -1285,  1322,   610,   603,  1097,   817,
   -951,  -247, -1421,   107,   830,  -271,   -90,  -853,
    608,   732,  1017,  -681, -1202,   962,   287,

    -75,  -156,   329,   418,   349,  -872,   644, -1590,
   1119,  -602,  1483,  -777,  -147,  1159,   778,  -246,
   1469,   126, -1162, -1618,  -666,  -320,    -8,   516,
   -130, -1602,  1458,  -829,   182,  1577,  1422,

   1653,  1574,  -460,  -291,  -235,   177,   587,   422,  
    105,  1550,   871, -1251,   843,   555,   430, -1103,
  -1544,  -282,  1491, -1293,  1015,  -552,   652,  1223,   
    383,   264, -1325,   573,   622,  -171,  1493,

  -1517,  -359,  -758, -1044  
};
/*************************************************
* Name:        fqmul
*
* Description: Multiplication followed by Montgomery reduction
*
* Arguments:   - int16_t a: first factor
*              - int16_t b: second factor
*
* Returns 16-bit integer congruent to a*b*R^{-1} mod q
**************************************************/
static int16_t fqmul(int16_t a, int16_t b) {
  return montgomery_reduce((int32_t)a*b);
}

/*************************************************
* Name:        ntt
*
* Description: Inplace number-theoretic transform (NTT) in Rq.
*              input is in standard order, output is in bitreversed order
*
* Arguments:   - int16_t r[256]: pointer to input/output vector of elements of Zq
**************************************************/
void ntt(int16_t r[256])
{
  unsigned int n;
  uint64_t cycles = 0, cycles1, cycles2;
  for (n = 0; n < LOOP; n++)
  {
    // Benchmarking key generation
    cycles1 = cpucycles();
    // printf("%lu\n", cycles1);
    ntt7(zetas1, r);
    cycles2 = cpucycles();
    // printf("%lu\n", cycles2);
    cycles = cycles + (cycles2 - cycles1);
  }
  // printf("ntt runs in ................ %10lu ", cycles / LOOP);
  // print_unit;
  // printf("\n");

  
  // correct the range (after operation is barrett reduction(complete reduction), so don't need to corrett the range)
  // for (int i = 0; i < 256; i++)
  // {
  //   if (r[i] < -KYBER_Q / 2)
  //     r[i] += KYBER_Q;
  //   if (r[i] > KYBER_Q / 2)
  //     r[i] -= KYBER_Q;
  // }
}

/*************************************************
* Name:        invntt_tomont
*
* Description: Inplace inverse number-theoretic transform in Rq and
*              multiplication by Montgomery factor 2^16.
*              Input is in bitreversed order, output is in standard order
*
* Arguments:   - int16_t r[256]: pointer to input/output vector of elements of Zq
**************************************************/
void invntt(int16_t r[256])
{
  unsigned int n;
  uint64_t cycles = 0, cycles1, cycles2;
  for (n = 0; n < LOOP; n++)
  {
    // Benchmarking key generation
    cycles1 = cpucycles();
    // printf("%lu\n", cycles1);
    intt7(zetas2, r);
    cycles2 = cpucycles();
    // printf("%lu\n", cycles2);
    cycles = cycles + (cycles2 - cycles1);
  }
  // printf("intt runs in ................ %10lu ", cycles / LOOP);
  // print_unit;
  // printf("\n");

  // unsigned int j;
  // const int16_t f = 1441; // mont^2/128
  // for (j = 0; j < 256; j++)
  //   r[j] = fqmul(r[j], f);

    
}

/*************************************************
* Name:        basemul
*
* Description: Multiplication of polynomials in Zq[X]/(X^2-zeta)
*              used for multiplication of elements in Rq in NTT domain
*
* Arguments:   - int16_t r[2]: pointer to the output polynomial
*              - const int16_t a[2]: pointer to the first factor
*              - const int16_t b[2]: pointer to the second factor
*              - int16_t zeta: integer defining the reduction polynomial
**************************************************/
void basemul(int16_t r[2], const int16_t a[2], const int16_t b[2], int16_t zeta)
{
  r[0]  = fqmul(a[1], b[1]);
  r[0]  = fqmul(r[0], zeta);
  r[0] += fqmul(a[0], b[0]);
  r[1]  = fqmul(a[0], b[1]);
  r[1] += fqmul(a[1], b[0]);
}

.altmacro

.macro              function  name:req
  .global             name
  .type               name, %function
  .func               name, name
  name&:
.endm

.macro  rptop num, op, \
              d_v, d_s, d_t, d_inc=1, \
              n_v, n_s, n_t, n_inc=1, \
              m_v, m_s, m_t, m_inc=1 
  // this repeats the operation 'op' for 'num' times
  // ?_v is the register type, e.g. v
  // ?_s is the starting register number, e.g. 0
  // ?_inc is the increment for each instruction, e.g. 1
  // it assembles the operation as shown in the line below
  \op \d_v\d_s\d_t, \n_v\n_s\n_t, \m_v\m_s\m_t
  .if     \num-1
    rptop %\num-1, \op, \
          \d_v, %\d_s+\d_inc, \d_t, \d_inc, \
          \n_v, %\n_s+\n_inc, \n_t, \n_inc, \
          \m_v, %\m_s+\m_inc, \m_t, \m_inc
  .endif
.endm

.macro rptmontgomery_reduce num, \
                    a1_v, a1_s, a1_inc=1, \
                    a2_v, a2_s, a2_inc=1, \
                    t_v, t_s, t_inc=1, \
                    eq32_v=v,   eq32_n=15,  eq32_t=.s[0], \
                    eqp32_v=v,  eqp32_n=15, eqp32_t=.s[1], \
                    vr32_v=v,   vr32_n=13
  // first block for a1
  // t1 = a1 * q', overflow discarded
  rptop \num, mul, \
        \t_v,     \t_s,  .4s, \t_inc,  \
        \a1_v,    \a1_s, .4s, \a1_inc, \
        \eqp32_v, \eqp32_n, \eqp32_t, 0
  // note: byte elements needed for and operation
  // t1 = t1 & (2**16-1)
  rptop \num, and, \
        \t_v,  \t_s,  .16b, \t_inc, \
        \t_v,  \t_s,  .16b, \t_inc, \
        \vr32_v, \vr32_n,  .16b, 0
  // a1 -= t1 * q
  rptop \num, mls, \
        \a1_v, \a1_s, .4s, \a1_inc, \
        \t_v,  \t_s,  .4s, \t_inc,  \
        \eq32_v, \eq32_n, \eq32_t, 0

  // second block for a2
  // t1 = a2 * q', overflow discarded
  rptop \num, mul, \
        \t_v,  \t_s,  .4s, \t_inc,  \
        \a2_v, \a2_s, .4s, \a2_inc, \
        \eqp32_v, \eqp32_n, \eqp32_t, 0
  // note: byte elements needed for and operation
  // t1 = t1 & (2**16-1) = t1取低16位
  rptop \num, and, \
        \t_v,  \t_s,  .16b, \t_inc, \
        \t_v,  \t_s,  .16b, \t_inc, \
        \vr32_v, \vr32_n,  .16b, 0
  // a2 -= t1 * q
  rptop \num, mls, \
        \a2_v, \a2_s, .4s, \a2_inc, \
        \t_v,  \t_s,  .4s, \t_inc,  \
        \eq32_v, \eq32_n, \eq32_t, 0

  // a1  = a1/2**16
  rptop \num, uzp2, \
        \a1_v, \a1_s, .8h, \a1_inc, \
        \a1_v, \a1_s, .8h, \a1_inc, \
        \a2_v, \a2_s, .8h, \a2_inc
.endm


.text

function poly_montgomery_reduce
// void poly_montgomery_reduce(poly *a)
      mov w4, 3329
      mov v15.s[0], w4  // v15.s[0] = q
      mov w4, 62209     
      mov v15.s[1], w4  // v15.s[1] = q^-1, q * q^-1 = 1 mod R(2^16)
      mov w4, 1353
      mov v14.s[0], w4  // v14.s[0] = v14.h[0]= f = R * R mod q
      //movi v13.4s, 0, MSL 16 // v13 = 2^16-1, msl表示前面的数左移右面的数的位数，后面补1
      mov w4, 65535  // 0000 0100 0000 0000 0000 0100 0000 0000
      mov v13.s[0], w4  // v14.s[0] = v14.h[0] = 1<<10
      mov v13.s[1], w4 
      mov v13.s[2], w4
      mov v13.s[3], w4
      mov x3, 0
loop: // for(x3=0, x3<4, x3++)
      ld1 {v16.8h, v17.8h, v18.8h, v19.8h}, [x0], 8*2*4     
      ld1 {v20.8h, v21.8h, v22.8h, v23.8h}, [x0], 8*2*4     //连续取8组8个16bit数
      // multiply the lower 4 elements each vector to v0-v7
      // r1 = a * b [lower elements]
      rptop 8, smull, \
          v, 0,  .4s, 1, \
          v, 16, .4h, 1, \
          v, 14, .h[0], 0
      // multiply the upper 4 elements each vector to v16-v23
      // r2 = a * b [upper elements]
      rptop 8, smull2, \
          v, 16, .4s, 1, \
          v, 16, .8h, 1, \
          v, 14, .h[0], 0
      // # reduction
      rptmontgomery_reduce 8, \
                    v,  0,  1,  \
                    v,  16, 1,  \
                    v,  24, 1,  \

      sub x0, x0, (8*2*4*2)   //restore x0
    
      st1 {v0.8h, v1.8h, v2.8h, v3.8h}, [x0], 8*2*4     
      st1 {v4.8h, v5.8h, v6.8h, v7.8h}, [x0], 8*2*4     //约减后的值存回x0
   
      add x3, x3, 1
      tbz x3, 2, loop     // repeat loop until x3 is 4
      ret
.endfunc
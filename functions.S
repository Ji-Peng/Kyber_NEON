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

.macro  rptuop num, op, \
              d_v, d_s, d_t, d_inc=1, \
              n_v, n_s, n_t, n_inc=1
  // this repeats the unary operation 'op' for 'num' times
  // ?_v is the register type, e.g. v
  // ?_s is the starting register number, e.g. 0
  // ?_inc is the increment for each instruction, e.g. 1
  // it assembles the operation as shown in the line below
  \op \d_v\d_s\d_t, \n_v\n_s\n_t
  .if     \num-1
    rptuop %\num-1, \op, \
          \d_v, %\d_s+\d_inc, \d_t, \d_inc, \
          \n_v, %\n_s+\n_inc, \n_t, \n_inc
  .endif
.endm

.macro  rptop_m_list  num, op, \
                    d_v, d_s, d_t, d_inc=1, \
                    n_v, n_s, n_t, n_inc=1, \
                    m, m_list:vararg
  // this repeats the operation 'op' for 'num' times
  // ?_v is the register type, e.g. v
  // ?_s is the starting register number, e.g. 0
  // ?_inc is the increment for each instruction, e.g. 1
  // as a third operand, a list is taken, consisting with 'num' entries
  // it assembles the operations as shown in the line below
  \op \d_v\d_s\d_t, \n_v\n_s\n_t, m
  .if     \num-1
    rptop_m_list %\num-1, \op, \
          \d_v, %\d_s+\d_inc, \d_t, \d_inc, \
          \n_v, %\n_s+\n_inc, \n_t, \n_inc, \
          m_list
  .endif
.endm

.macro transposeElements a, b_out, b_in
  // transposes the elements of two vectors
  trn2 \b_out, \a, \b_in
  trn1 \a, \a, \b_in
.endm

.macro transposeElementsUZP a, b_out, b_in
  // transposes the elements of two vectors
  uzp2 \b_out, \a, \b_in
  uzp1 \a, \a, \b_in
.endm

.macro transposeElementsZIP a, b_out, b_in
  // transposes the elements of two vectors
  zip2 \b_out, \a, \b_in
  zip1 \a, \a, \b_in
.endm

.macro rptbarrett num, \
                    a_v, a_s, a_inc=1, \
                    t_v, t_s, t_inc=1, \
                    t16_v=v,   t16_n=13,  t32_t=.8h, \
                    eq16_v=v,   eq16_n=15,  eq32_t=.h[0]
  rptop num, sshr, \
        t_v,     t_s,     .8h,    t_inc, \
        a_v,     a_s,     .8h,    a_inc, \
        ,         3,       ,       0            // t = a / 2**3

  rptop num, ssra, \
        t_v,     t_s,     .8h,    t_inc, \
        a_v,     a_s,     .8h,    a_inc, \
        ,         1,       ,       0            // t += a / 2**1 = t * 5

  rptop num, add, \
        t_v,     t_s,     .8h,    t_inc, \
        t_v,     t_s,     .8h,    t_inc, \
        t16_v,   t16_n,   t32_t,    0           // t += (1<<10)

  rptop num, sshr, \
        t_v,     t_s,     .8h,    t_inc, \
        t_v,     t_s,     .8h,    t_inc, \
        ,         11,       ,       0           // t = t / 2**11

  rptop num, mls, \
        a_v,     a_s,     .8h,    a_inc, \
        t_v,     t_s,     .8h,    t_inc, \
        eq16_v,  eq16_n,   eq32_t,    0         // a -= t * q
.endm

.macro rptspecial num, \
                    a_v, a_s, a_inc=1, \
                    t_v, t_s, t_inc=1, \
                    u_v, u_s, u_inc=1, \
                    t16_v=v,   t16_n=31,  t32_t=.16b
  rptop num, sshr, \
        t_v,     t_s,     .8h,    t_inc, \
        a_v,     a_s,     .8h,    a_inc, \
        ,         12,       ,       0           // t = a >> 12

  rptop \num, and, \
        u_v,     u_s,    .16b,    u_inc, \
        a_v,     a_s,    .16b,    a_inc, \
        t16_v,   t16_n,   t32_t,    0           // u = a & 0x0fff

  rptop num, sub, \
        u_v,     u_s,     .8h,    u_inc, \
        u_v,     u_s,     .8h,    u_inc, \
        t_v,     t_s,     .8h,    t_inc         // u = u - t

  rptop num, shl, \
        t_v,     t_s,     .8h,    t_inc, \
        t_v,     t_s,     .8h,    t_inc, \
        ,         8,       ,       0            // t = t << 8

  rptop num, add, \
        a_v,     a_s,     .8h,    a_inc, \
        u_v,     u_s,     .8h,    u_inc, \
        t_v,     t_s,     .8h,    t_inc         // r = u + t

  rptop num, shl, \
        t_v,     t_s,     .8h,    t_inc, \
        t_v,     t_s,     .8h,    t_inc, \
        ,         1,       ,       0            // t = t << 1

  rptop num, add, \
        a_v,     a_s,     .8h,    a_inc, \
        a_v,     a_s,     .8h,    a_inc, \
        t_v,     t_s,     .8h,    t_inc         // r += t
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

.macro rptbutterfly num, \
                    a1_v, a1_s, a1_inc=1, \
                    a2_v, a2_s, a2_inc=1, \
                    t_v, t_s, t_inc=1

  // a[j+distance]_new = a[j] - t
  rptop \num, sub, \
        \a2_v,    \a2_s,    .8h, \a2_inc,  \
        \a1_v,    \a1_s,    .8h, \a1_inc,  \
        \t_v,     \t_s,     .8h, \t_inc

  // a[j]_new = a[j] + t
  rptop \num, add, \
        \a1_v,    \a1_s,    .8h, \a1_inc, \
        \a1_v,    \a1_s,    .8h, \a1_inc, \
        \t_v,     \t_s,     .8h, \t_inc
.endm

.macro rptbutterfly_gs num, \
                    a1_v, a1_s, a1_inc=1, \
                    a2_v, a2_s, a2_inc=1, \
                    t_v, t_s, t_inc=1
  // t = a[j]
  rptuop \num, mov, \
        \t_v,     \t_s,    .16b, \t_inc, \
        \a1_v,    \a1_s,   .16b, \a1_inc
        
  // a[j]_new = a[j+distance] + t
  rptop \num, add, \
        \a1_v,    \a1_s,    .8h, \a1_inc, \
        \a2_v,    \a2_s,    .8h, \a2_inc, \
        \t_v,     \t_s,     .8h, \t_inc

  // a[j+distance]_new = a[j+distance] - t
  rptop \num, sub, \
        \a2_v,    \a2_s,    .8h, \a2_inc,  \
        \a2_v,    \a2_s,    .8h, \a2_inc,  \
        \t_v,     \t_s,     .8h, \t_inc
.endm

.macro rptbutterfly_gs_br num, \
                    a1_v, a1_s, a1_inc=1, \
                    a2_v, a2_s, a2_inc=1, \
                    t_v, t_s, t_inc=1
  // t = a[j]
  rptuop \num, mov, \
        \t_v,     \t_s,    .16b, \t_inc, \
        \a1_v,    \a1_s,   .16b, \a1_inc
        
  // a[j]_new = a[j+distance] + t
  rptop \num, add, \
        \a1_v,    \a1_s,    .8h, \a1_inc, \
        \a2_v,    \a2_s,    .8h, \a2_inc, \
        \t_v,     \t_s,     .8h, \t_inc

  // a[j+distance]_new = a[j+distance] - t
  rptop \num, sub, \
        \a2_v,    \a2_s,    .8h, \a2_inc,  \
        \a2_v,    \a2_s,    .8h, \a2_inc,  \
        \t_v,     \t_s,     .8h, \t_inc

  // a[j]_new = barrett_reduce(a[j]_new)
  rptbarrett \num, \
                    \a1_v, \a1_s, \a1_inc, \
                    \t_v,  \t_s,  \t_inc
.endm

.macro rptbutterfly_gs_sp num, \
                    a1_v, a1_s, a1_inc=1, \
                    a2_v, a2_s, a2_inc=1, \
                    t_v, t_s, t_inc=1, \
                    t2_v, t2_s, t2_inc=1
  // t = a[j]
  rptuop \num, mov, \
        \t_v,     \t_s,    .16b, \t_inc, \
        \a1_v,    \a1_s,   .16b, \a1_inc
        
  // a[j]_new = a[j+distance] + t
  rptop \num, add, \
        \a1_v,    \a1_s,    .8h, \a1_inc, \
        \a2_v,    \a2_s,    .8h, \a2_inc, \
        \t_v,     \t_s,     .8h, \t_inc

  // a[j+distance]_new = a[j+distance] - t
  rptop \num, sub, \
        \a2_v,    \a2_s,    .8h, \a2_inc,  \
        \a2_v,    \a2_s,    .8h, \a2_inc,  \
        \t_v,     \t_s,     .8h, \t_inc

  // a[j]_new = barrett_reduce(a[j]_new)
  rptspecial \num, \
                    \a1_v, \a1_s, \a1_inc, \
                    \t_v,  \t_s,  \t_inc, \
                    \t2_v,  \t2_s,  \t2_inc
.endm

.macro rptntt1 num, \
        a_v, a_s, a_inc=1, \
        b_in_v, b_in_s, b_in_inc=1, \
        t1_v, t1_s, t1_inc=1, \
        t2_v, t2_s, t2_inc=1, \
        t3_v, t3_s, t3_inc=1, \
        omega16_1_list, \
        omega16_2_list
        //z_v=v, z_s=14, z_t=.h[0], z_inc=0
  rptop_m_list \num, smull, \
        \t1_v,     \t1_s,    .4s,  \t1_inc, \
        \b_in_v,   \b_in_s,  .4h,  \b_in_inc, \
        \omega16_1_list
        //\z_v,      \z_s,    \z_t,  \z_inc
  rptop_m_list \num, smull2, \
        \t2_v,     \t2_s,    .4s,  \t2_inc,     \
        \b_in_v,   \b_in_s,  .8h,  \b_in_inc,   \
        \omega16_2_list
        //\z_v,      \z_s,    \z_t,  \z_inc
  // reduction
  rptmontgomery_reduce \num, \
        \t1_v,     \t1_s,     \t1_inc,     \
        \t2_v,     \t2_s,     \t2_inc,     \
        \t3_v,     \t3_s,     \t3_inc
  // butterfly
  rptbutterfly \num, \
        \a_v,      \a_s,      \a_inc,      \
        \b_in_v,   \b_in_s,   \b_in_inc,   \
        \t1_v,     \t1_s,     \t1_inc
.endm

.macro rptintt1 num, \
        a_v, a_s, a_inc=1, \
        b_in_v, b_in_s, b_in_inc=1, \
        t1_v, t1_s, t1_inc=1, \
        t2_v, t2_s, t2_inc=1, \
        t3_v, t3_s, t3_inc=1, \
        omega16_1_list, \
        omega16_2_list

  // butterfly_gs
  rptbutterfly_gs \num, \
        \a_v,      \a_s,      \a_inc,      \
        \b_in_v,   \b_in_s,   \b_in_inc,   \
        \t3_v,     \t3_s,     \t3_inc
  // a[j + len] = fqmul(zeta, a[j + len]);
  rptop_m_list \num, smull, \
        \t1_v,     \t1_s,    .4s,  \t1_inc, \
        \b_in_v,   \b_in_s,  .4h,  \b_in_inc, \
        \omega16_1_list
        //\z_v,      \z_s,    \z_t,  \z_inc
  rptop_m_list \num, smull2, \
        \t2_v,     \t2_s,    .4s,  \t2_inc,     \
        \b_in_v,   \b_in_s,  .8h,  \b_in_inc,   \
        \omega16_2_list
        //\z_v,      \z_s,    \z_t,  \z_inc
  // reduction
  rptmontgomery_reduce \num, \
        \t1_v,     \t1_s,     \t1_inc,     \
        \t2_v,     \t2_s,     \t2_inc,     \
        \t3_v,     \t3_s,     \t3_inc
  rptuop \num, mov, \
        \b_in_v,  \b_in_s, .16b, \b_in_inc, \
        \t1_v,    \t1_s,   .16b, \t1_inc
.endm

.macro rptintt1_br num, \
        a_v, a_s, a_inc=1, \
        b_in_v, b_in_s, b_in_inc=1, \
        t1_v, t1_s, t1_inc=1, \
        t2_v, t2_s, t2_inc=1, \
        t3_v, t3_s, t3_inc=1, \
        omega16_1_list, \
        omega16_2_list

  // butterfly_gs
  rptbutterfly_gs_br \num, \
        \a_v,      \a_s,      \a_inc,      \
        \b_in_v,   \b_in_s,   \b_in_inc,   \
        \t3_v,     \t3_s,     \t3_inc
  // a[j + len] = fqmul(zeta, a[j + len]);
  rptop_m_list \num, smull, \
        \t1_v,     \t1_s,    .4s,  \t1_inc, \
        \b_in_v,   \b_in_s,  .4h,  \b_in_inc, \
        \omega16_1_list
        //\z_v,      \z_s,    \z_t,  \z_inc
  rptop_m_list \num, smull2, \
        \t2_v,     \t2_s,    .4s,  \t2_inc,     \
        \b_in_v,   \b_in_s,  .8h,  \b_in_inc,   \
        \omega16_2_list
        //\z_v,      \z_s,    \z_t,  \z_inc
  // reduction
  rptmontgomery_reduce \num, \
        \t1_v,     \t1_s,     \t1_inc,     \
        \t2_v,     \t2_s,     \t2_inc,     \
        \t3_v,     \t3_s,     \t3_inc
  rptuop \num, mov, \
        \b_in_v,  \b_in_s, .16b, \b_in_inc, \
        \t1_v,    \t1_s,   .16b, \t1_inc
.endm

.macro rptintt1_sp num, \
        a_v, a_s, a_inc=1, \
        b_in_v, b_in_s, b_in_inc=1, \
        t1_v, t1_s, t1_inc=1, \
        t2_v, t2_s, t2_inc=1, \
        t3_v, t3_s, t3_inc=1, \
        omega16_1_list, \
        omega16_2_list

  // butterfly_gs
  rptbutterfly_gs_sp \num, \
        \a_v,      \a_s,      \a_inc,      \
        \b_in_v,   \b_in_s,   \b_in_inc,   \
        \t3_v,     \t3_s,     \t3_inc,     \
        \t2_v,     \t2_s,     \t2_inc
        
  // a[j + len] = fqmul(zeta, a[j + len]);
  rptop_m_list \num, smull, \
        \t1_v,     \t1_s,    .4s,  \t1_inc, \
        \b_in_v,   \b_in_s,  .4h,  \b_in_inc, \
        \omega16_1_list
        //\z_v,      \z_s,    \z_t,  \z_inc
  rptop_m_list \num, smull2, \
        \t2_v,     \t2_s,    .4s,  \t2_inc,     \
        \b_in_v,   \b_in_s,  .8h,  \b_in_inc,   \
        \omega16_2_list
        //\z_v,      \z_s,    \z_t,  \z_inc
  // reduction
  rptmontgomery_reduce \num, \
        \t1_v,     \t1_s,     \t1_inc,     \
        \t2_v,     \t2_s,     \t2_inc,     \
        \t3_v,     \t3_s,     \t3_inc
  rptuop \num, mov, \
        \b_in_v,  \b_in_s, .16b, \b_in_inc, \
        \t1_v,    \t1_s,   .16b, \t1_inc
.endm
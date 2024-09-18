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

.macro rptbarrett num, \
                    a_v, a_s, a_inc=1, \
                    t_v, t_s, t_inc=1, \
                    t2_v, t2_s, t2_inc=1, \
                    t16_v=v,   t16_n=13,  t32_t=.8h, \
                    eq16_v=v,   eq16_n=15,  eq32_t=.h[0]
  rptop num, sshr, \
        t_v,     t_s,     .8h,    t_inc, \
        a_v,     a_s,     .8h,    a_inc, \
        ,         3,       ,       0            // t = a / 2**3

  rptop num, shl, \
        t2_v,   t2_s,     .8h,   t2_inc, \
        t_v,     t_s,     .8h,    t_inc, \
        ,         2,       ,       0     
        
  rptop num, add, \
        t_v,     t_s,     .8h,    t_inc, \
        t_v,     t_s,     .8h,    t_inc, \
        t2_v,   t2_s,     .8h,   t2_inc, 
                                                // t += a / 2**1 = t * 5 (errors)
                                                // t += t * 2**2 = t * 5 (right)

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


.text

function poly_barrett_reduce
// void poly_barrett_reduce(poly *a); 
      //push d15     // store constants q
      mov w4, 3329
      mov v15.s[0], w4  // v15.s[0] = v15.h[0] = q
      mov w4, 67109888  // 0000 0100 0000 0000 0000 0100 0000 0000
      mov v13.s[0], w4  // v14.s[0] = v14.h[0] = 1<<10
      mov v13.s[1], w4 
      mov v13.s[2], w4
      mov v13.s[3], w4
      mov x3, 0
loop: // for(x3=0, x3<4, x3++)
      ld1 {v16.8h, v17.8h, v18.8h, v19.8h}, [x0], 8*2*4     
      ld1 {v20.8h, v21.8h, v22.8h, v23.8h}, [x0], 8*2*4     //连续取8组8个16bit数
      
      rptbarrett 8, \
            v,  16, 1,  \
            v,  0,  1,  \
            v, 24,  1

      sub x0, x0, (8*2*4*2)   //restore x0
    
      st1 {v16.8h, v17.8h, v18.8h, v19.8h}, [x0], 8*2*4     
      st1 {v20.8h, v21.8h, v22.8h, v23.8h}, [x0], 8*2*4     //约减后的值存回x0
   
      add x3, x3, 1
      tbz x3, 2, loop     // repeat loop until x3 is 4

      //pop d15    
      ret
.endfunc
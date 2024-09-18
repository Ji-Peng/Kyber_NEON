#include "functions.S"

.text

// v13 save R-1, v15 save q and q^-1
function intt7
      // q
      mov w4, 3329
      mov v15.s[0], w4  // v15.s[0] = q
      // q^-1
      mov w4, 62209     
      mov v15.s[1], w4  // v15.s[1] = q^-1, q * q^-1 = 1 mod R(2^16)
      
      // v13.s[0]=s[1]=s[2]=s[3]=R-1=2^16-1
      movi v13.4s, 0, MSL 16 // v13 = 2^16-1, msl表示前面的数左移右面的数的位数，后面补1
      mov x3, 0
loop_intt5: // for(x3=0, x3<4, x3++)
      // zeta[127]~[112]、[111]~[97]
      ld1 {v8.8h, v9.8h, v10.8h, v11.8h}, [x0]
      add x0, x0, 31*2

      // in[0, 1, ..., 7], in[8, 9, ..., 15], in[16, .., 23], in[24, ..., 31]
      ld1 {v16.8h, v17.8h, v18.8h, v19.8h}, [x1], 8*2*4
      add x2, x1, 32*2-8*2*4  // mov x2, x1
      ld1 {v20.8h, v21.8h, v22.8h, v23.8h}, [x2], 8*2*4

      // first layer
      zip2 v12.8h,  v8.8h,  v8.8h
      zip1 v8.8h,   v8.8h,  v8.8h
      zip2 v14.8h,  v9.8h,  v9.8h
      zip1 v9.8h,   v9.8h,  v9.8h // v8, v12, v9, v14

      rptop 4, transposeElementsUZP, \
                v, 16, .4s, 2, \
                v, 24, .4s, 1, \
                v, 17, .4s, 2
      rptuop 4, mov, \
        v, 17, .16b, 2, \
        v, 24, .16b, 1

      // butterfly unit, input is v16 and v17
      rptintt1 4, \
        v, 16, 2, \
        v, 17, 2, \
        v, 0, 1, \
        v, 4, 1, \
        v, 24, 1, \
        <v8.4h,v12.4h,v9.4h,v14.4h>, \
        <v8.8h,v12.8h,v9.8h,v14.8h>

      rptop 4, transposeElementsZIP, \
                v, 16, .4s, 2, \
                v, 24, .4s, 1, \
                v, 17, .4s, 2
      rptuop 4, mov, \
        v, 17, .16b, 2, \
        v, 24, .16b, 1

      // second layer 
      // butterfly unit, input is v16 and v17
      rptop 4, transposeElements, \
                v, 16, .2d, 2, \
                v, 24, .2d, 1, \
                v, 17, .2d, 2
      rptuop 4, mov, \
        v, 17, .16b, 2, \
        v, 24, .16b, 1
      rptintt1 4, \
        v, 16, 2, \
        v, 17, 2, \
        v, 0, 1, \
        v, 4, 1, \
        v, 24, 1, \
        <v10.h[0],v10.h[2],v10.h[4],v10.h[6]>, \
        <v10.h[1],v10.h[3],v10.h[5],v10.h[7]>
      rptop 4, transposeElements, \
                v, 16, .2d, 2, \
                v, 24, .2d, 1, \
                v, 17, .2d, 2
      //mov v17.16b, v24.16b
      rptuop 4, mov, \
        v, 17, .16b, 2, \
        v, 24, .16b, 1
      
      // third layer
      rptintt1_br 4, \
        v, 16, 2, \
        v, 17, 2, \
        v, 0, 1, \
        v, 4, 1, \
        v, 24, 1, \
        <v11.h[0],v11.h[1],v11.h[2],v11.h[3]>, \
        <v11.h[0],v11.h[1],v11.h[2],v11.h[3]>

      // fourth layer
      rptintt1 2, \
        v, 16, 1, \
        v, 18, 1, \
        v, 0, 1, \
        v, 4, 1, \
        v, 24, 1, \
        <v11.h[4],v11.h[4]>, \
        <v11.h[4],v11.h[4]>
      rptintt1 2, \
        v, 20, 1, \
        v, 22, 1, \
        v, 0, 1, \
        v, 4, 1, \
        v, 24, 1, \
        <v11.h[5],v11.h[5]>, \
        <v11.h[5],v11.h[5]>

      // fifth layer
      rptintt1 4, \
        v, 16, 1, \
        v, 20, 1, \
        v, 0, 1, \
        v, 4, 1, \
        v, 24, 1, \
        <v11.h[6],v11.h[6],v11.h[6],v11.h[6]>, \
        <v11.h[6],v11.h[6],v11.h[6],v11.h[6]>

     // store
      sub x1, x1, (8*2*4)   // restore x1
      sub x2, x2, (8*2*4)
      st1 {v16.8h, v17.8h, v18.8h, v19.8h}, [x1], 8*2*4     
      st1 {v20.8h, v21.8h, v22.8h, v23.8h}, [x2], 8*2*4   
      add x1, x1, 64*2-8*2*4

      add x3, x3, 1
      // loop num is 4, each loop handle 64 coefficients
      // repeat loop until x3 is 4
      tbz x3, 2, loop_intt5    
    
      // last two layer
      ld1 {v14.8h}, [x0]
      sub x1, x1, 256*2
      mov x3, 0
loop_intt2: // for(x3=0, x3<2, x3++)
      // in[0, 1, ..., 7], in[8, 9, ..., 15], in[16, .., 23], in[24, ..., 31]
      ld1 {v16.8h, v17.8h, v18.8h, v19.8h}, [x1], 8*2*4
      sub x1, x1, (8*2*4)   //restore x1 
      
      // point to next coefficients  
      add x2, x1, 64*2   
      // in[0+64, 1+64, ..., 7+64], in[8+64, 9+64, ..., 15+64], in[16+64, .., 23+64], in[24+64, ..., 31+64]
      ld1 {v20.8h, v21.8h, v22.8h, v23.8h}, [x2], 8*2*4   //b
      
      add x2, x1, 128*2
      ld1 {v24.8h, v25.8h, v26.8h, v27.8h}, [x2], 8*2*4
      
      add x2, x1, 192*2
      ld1 {v28.8h, v29.8h, v30.8h, v31.8h}, [x2], 8*2*4

      // sixth layer
      // butterfly unit, input is v16 and v20
      rptintt1_br 4, \
        v, 16, 1, \
        v, 20, 1, \
        v, 0, 1, \
        v, 4, 1, \
        v, 8, 1, \
        <v14.h[0],v14.h[0],v14.h[0],v14.h[0]>, \
        <v14.h[0],v14.h[0],v14.h[0],v14.h[0]>

      rptintt1_br 4, \
        v, 24, 1, \
        v, 28, 1, \
        v, 0, 1, \
        v, 4, 1, \
        v, 8, 1, \
        <v14.h[1],v14.h[1],v14.h[1],v14.h[1]>, \
        <v14.h[1],v14.h[1],v14.h[1],v14.h[1]>

      // seventh layer
      rptintt1_br 4, \
        v, 16, 1, \
        v, 24, 1, \
        v, 0, 1, \
        v, 4, 1, \
        v, 8, 1, \
        <v14.h[2],v14.h[2],v14.h[2],v14.h[2]>, \
        <v14.h[2],v14.h[2],v14.h[2],v14.h[2]>

      rptintt1_br 4, \
        v, 20, 1, \
        v, 28, 1, \
        v, 0, 1, \
        v, 4, 1, \
        v, 8, 1, \
        <v14.h[2],v14.h[2],v14.h[2],v14.h[2]>, \
        <v14.h[2],v14.h[2],v14.h[2],v14.h[2]>
      
      // store
      st1 {v16.8h, v17.8h, v18.8h, v19.8h}, [x1], 8*2*4     //a, 四组8个多项式系数
      sub x1, x1, (8*2*4)   //restore x1 
      add x2, x1, 64*2
      st1 {v20.8h, v21.8h, v22.8h, v23.8h}, [x2], 8*2*4     //b
      add x2, x1, 128*2
      st1 {v24.8h, v25.8h, v26.8h, v27.8h}, [x2], 8*2*4     //c
      add x2, x1, 192*2
      st1 {v28.8h, v29.8h, v30.8h, v31.8h}, [x2], 8*2*4     //d
      
      add x1, x1, 32*2
      add x3, x3, 1
      // loop num is 2, each loop handle 32 coefficients
      // repeat loop until x3 is 2
      tbz x3, 1, loop_intt2
         
      // MontM
      sub x1, x1, 64*2
      mov w4, 1441
      mov v14.s[0], w4  // v14.s[0] = v14.h[0]= f = R * R mod q
      mov x3, 0
loop: // for(x3=0, x3<4, x3++)
      ld1 {v16.8h, v17.8h, v18.8h, v19.8h}, [x1], 8*2*4     
      ld1 {v20.8h, v21.8h, v22.8h, v23.8h}, [x1], 8*2*4     //连续取8组8个16bit数
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

      sub x1, x1, (8*2*4*2)   //restore x1
    
      st1 {v0.8h, v1.8h, v2.8h, v3.8h}, [x1], 8*2*4     
      st1 {v4.8h, v5.8h, v6.8h, v7.8h}, [x1], 8*2*4     //约减后的值存回x1
   
      add x3, x3, 1
      tbz x3, 2, loop     // repeat loop until x3 is 4

      ret
.endfunc
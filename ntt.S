#include "functions.S"

.text

// v13 save R-1, v14 save zetas, v15 save q and q^-1
function ntt7
      // q
      mov w4, 3329
      mov v15.s[0], w4  // v15.s[0] = q
      // q^-1
      mov w4, 62209     
      mov v15.s[1], w4  // v15.s[1] = q^-1, q * q^-1 = 1 mod R(2^16)
      
      // x0=*zeta[0]
      add x0, x0, 1*2
      // zeta[1]
      ld1 {v14.8h}, [x0]
      // v13.s[0]=s[1]=s[2]=s[3]=R-1=2^16-1
      movi v13.4s, 0, MSL 16 // v13 = 2^16-1, msl表示前面的数左移右面的数的位数，后面补1
      mov x3, 0
loop_ntt2: // for(x3=0, x3<2, x3++)
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

      // first layer
      // butterfly unit, input is v16 and v24
      rptntt1 4, \
        v, 16, 1, \
        v, 24, 1, \
        v, 0, 1, \
        v, 4, 1, \
        v, 8, 1, \
        <v14.h[0],v14.h[0],v14.h[0],v14.h[0]>, \
        <v14.h[0],v14.h[0],v14.h[0],v14.h[0]>

      rptntt1 4, \
        v, 20, 1, \
        v, 28, 1, \
        v, 0, 1, \
        v, 4, 1, \
        v, 8, 1, \
        <v14.h[0],v14.h[0],v14.h[0],v14.h[0]>, \
        <v14.h[0],v14.h[0],v14.h[0],v14.h[0]>

      // second layer
      rptntt1 4, \
        v, 16, 1, \
        v, 20, 1, \
        v, 0, 1, \
        v, 4, 1, \
        v, 8, 1, \
        <v14.h[1],v14.h[1],v14.h[1],v14.h[1]>, \
        <v14.h[1],v14.h[1],v14.h[1],v14.h[1]>

      rptntt1 4, \
        v, 24, 1, \
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
      tbz x3, 1, loop_ntt2     


      // last five layer
      add x0, x0, 3*2
      sub x1, x1, 64*2
      mov x3, 0
loop_ntt5: // for(x3=0, x3<4, x3++)
      // zeta[4]~[18]
      ld1 {v8.8h, v9.8h}, [x0] 
      add x0, x0, 15*2
      // zeta[19]~[34]
      ld1 {v10.8h, v11.8h}, [x0]
      add x0, x0, 16*2
      mov v12.16b, v11.16b 
      ld1 {v16.8h, v17.8h, v18.8h, v19.8h}, [x1], 8*2*4
      add x2, x1, 32*2-8*2*4    
      ld1 {v20.8h, v21.8h, v22.8h, v23.8h}, [x2], 8*2*4

      // third layer butterfly unit, input is v16 and v20
      rptntt1 4, \
        v, 16, 1, \
        v, 20, 1, \
        v, 0, 1, \
        v, 4, 1, \
        v, 24, 1, \
        <v8.h[0],v8.h[0],v8.h[0],v8.h[0]>, \
        <v8.h[0],v8.h[0],v8.h[0],v8.h[0]>

      // fourth layer butterfly unit, input is v16 and v18
      rptntt1 2, \
        v, 16, 1, \
        v, 18, 1, \
        v, 0, 1, \
        v, 4, 1, \
        v, 24, 1, \
        <v8.h[1],v8.h[1]>, \
        <v8.h[1],v8.h[1]>
      rptntt1 2, \
        v, 20, 1, \
        v, 22, 1, \
        v, 0, 1, \
        v, 4, 1, \
        v, 24, 1, \
        <v8.h[2],v8.h[2]>, \
        <v8.h[2],v8.h[2]>

      // fifth layer butterfly unit, input is v16 and v17
      rptntt1 4, \
        v, 16, 2, \
        v, 17, 2, \
        v, 0, 1, \
        v, 4, 1, \
        v, 24, 1, \
        <v8.h[3],v8.h[4],v8.h[5],v8.h[6]>, \
        <v8.h[3],v8.h[4],v8.h[5],v8.h[6]>

      // sixth layer butterfly unit, input is v16 and v17
      rptop 4, transposeElements, \
                v, 16, .2d, 2, \
                v, 24, .2d, 1, \
                v, 17, .2d, 2
      rptuop 4, mov, \
        v, 17, .16b, 2, \
        v, 24, .16b, 1
      rptntt1 4, \
        v, 16, 2, \
        v, 17, 2, \
        v, 0, 1, \
        v, 4, 1, \
        v, 24, 1, \
        <v8.h[7],v9.h[1],v9.h[3],v9.h[5]>, \
        <v9.h[0],v9.h[2],v9.h[4],v9.h[6]>
      rptop 4, transposeElements, \
                v, 16, .2d, 2, \
                v, 24, .2d, 1, \
                v, 17, .2d, 2
      //mov v17.16b, v24.16b
      rptuop 4, mov, \
        v, 17, .16b, 2, \
        v, 24, .16b, 1
      
      // seventh layer  butterfly unit, input is v16 and v18
      // douplicate zeta elements
      zip2 v11.8h,  v10.8h,  v10.8h
      zip1 v10.8h,  v10.8h,  v10.8h
      zip2 v9.8h,   v12.8h,  v12.8h
      zip1 v12.8h,  v12.8h,  v12.8h
      rptop 4, transposeElementsUZP, \
                v, 16, .4s, 2, \
                v, 24, .4s, 1, \
                v, 17, .4s, 2
      //mov v17.16b, v24.16b
      rptuop 4, mov, \
        v, 17, .16b, 2, \
        v, 24, .16b, 1
      rptntt1 4, \
        v, 16, 2, \
        v, 17, 2, \
        v, 0, 1, \
        v, 4, 1, \
        v, 24, 1, \
        <v10.4h,v11.4h,v12.4h,v9.4h>, \
        <v10.8h,v11.8h,v12.8h,v9.8h>

      rptop 4, transposeElementsZIP, \
                v, 16, .4s, 2, \
                v, 24, .4s, 1, \
                v, 17, .4s, 2
      rptuop 4, mov, \
        v, 17, .16b, 2, \
        v, 24, .16b, 1
     
      // restore x1
      sub x1, x1, (8*2*4)   
      sub x2, x2, (8*2*4)
    
      st1 {v16.8h, v17.8h, v18.8h, v19.8h}, [x1], 8*2*4     
      st1 {v20.8h, v21.8h, v22.8h, v23.8h}, [x2], 8*2*4   
      add x1, x1, 64*2-8*2*4

      add x3, x3, 1
      tbz x3, 2, loop_ntt5

      ret
.endfunc
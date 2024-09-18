CC = aarch64-none-linux-gnu-gcc
CFLAGS += -Wall -Wextra -Wpedantic -Wmissing-prototypes -Wredundant-decls \
  -Wshadow -Wpointer-arith -O3 -fomit-frame-pointer -fwrapv
NISTFLAGS += -Wno-unused-result -O3 -fwrapv
RM = /bin/rm

SOURCES = kem.c indcpa.c polyvec.c poly.c ntt.c cbd.c reduce.c verify.c
HEADERS = params.h kem.h indcpa.h polyvec.h poly.h ntt.h cbd.h reduce.c verify.h symmetric.h
SOURCESKECCAK = $(SOURCES) fips202.c symmetric-shake.c
HEADERSKECCAK = $(HEADERS) fips202.h

all: test_kyber512 test_kyber768 test_kyber1024

test_kyber512: $(SOURCESKECCAK) $(HEADERSKECCAK) test_kyber.c randombytes.c
	$(CC) $(CFLAGS) -DKYBER_K=2 $(SOURCESKECCAK) barrett.S montgomery.S functions.S ntt.S intt.S randombytes.c cpucycles.c test_kyber.c -o test_kyber512

test_kyber768: $(SOURCESKECCAK) $(HEADERSKECCAK) test_kyber.c randombytes.c
	$(CC) $(CFLAGS) -DKYBER_K=3 $(SOURCESKECCAK) barrett.S montgomery.S functions.S ntt.S intt.S randombytes.c cpucycles.c test_kyber.c -o test_kyber768

test_kyber1024: $(SOURCESKECCAK) $(HEADERSKECCAK) test_kyber.c randombytes.c
	$(CC) $(CFLAGS) -DKYBER_K=4 $(SOURCESKECCAK) barrett.S montgomery.S functions.S ntt.S intt.S randombytes.c cpucycles.c test_kyber.c -o test_kyber1024


clean:
	-$(RM) -rf test_kyber512
	-$(RM) -rf test_kyber768
	-$(RM) -rf test_kyber1024

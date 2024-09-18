#include <stdint.h>
#include <time.h>
#include "cpucycles.h"

int64_t cpucycles(void)
{ // Access system counter for benchmarking
  struct timespec time;

  clock_gettime(CLOCK_REALTIME, &time);
  return (int64_t)(time.tv_sec * 1e9 + time.tv_nsec);
}

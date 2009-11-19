#include <time.h>
#include <stdio.h>
#include <errno.h>
#include <strings.h>

int main() {
  struct timespec t;
  long long x;
  
  if (clock_getres(CLOCK_MONOTONIC, &t) != 0) {
    perror("clock_getres");
    return 1;
  }
  x = t.tv_sec*1000000000 + t.tv_nsec; 
  printf("Monotonic time-resolution: %lld\n", x);
  return 0;
}

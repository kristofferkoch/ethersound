/*
  Module for syncing to and sending audio to the
  FPGA. Note: MAC-address is hard-coded into the source.


    This file is part of hwpulse.

    hwpulse is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    hwpulse is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with hwpulse.  If not, see <http://www.gnu.org/licenses/>.

 */
#include <sys/socket.h>
#include <net/if.h>
#include <errno.h>
#include <stdlib.h>
#include <linux/if_packet.h>
#include <arpa/inet.h>
#include <stdio.h>
#include <string.h>
#include <linux/if_ether.h>
#include <unistd.h>

const int proto = 0x88b5;

void mainloop(int, int);

void usage(char **argv) {
  fprintf(stderr, "Usage: %s ethX\n", argv[0]);
  exit(1);
}

int main(int argc, char **argv) {
  int s, iface, ret;
  struct sockaddr_ll sockaddr;
  socklen_t slen = sizeof(sockaddr);

  if (argc < 2) usage(argv);
  
  s = socket(AF_PACKET, SOCK_RAW, htons(proto));
  if (s < 0) {
    perror("socket");
    exit(1);
  }
  iface = if_nametoindex(argv[1]);
  if (iface == 0) {
    perror("if_nametoindex");
    exit(1);
  }
  memset (&sockaddr, 0, slen);
  sockaddr.sll_family = AF_PACKET;
  sockaddr.sll_protocol = htons(proto);
  sockaddr.sll_ifindex = iface;

  ret = bind(s, (struct sockaddr *)&sockaddr, slen);
  if (ret < 0) {
    perror("bind");
    exit(1);
  }
  for (;;)
    mainloop(s, iface);
  return 0;
}
void mainloop(int s, int iface) {
  char packet[4096], rbuf[4096];
  unsigned int plen = 1024;
  int ret,i;
  struct sockaddr_ll from;
  socklen_t slen = sizeof(from);
  union {
    uint64_t uint;
    char c[8];
  } clock;
  static uint64_t t;

  ret = recvfrom(s, rbuf, sizeof(rbuf), 0, 
		 (struct sockaddr *)&from, &slen);
  if (ret < 0) {
    perror("recvfrom");
    exit(1);
  }
  /*printf("Dest:\t");
  for(i=0;i<6;i+=1) printf("%02hhX ", rbuf[i]);
  printf("\nSource:\t");
  for(;i<12;i+=1) printf("%02hhX ", rbuf[i]);
  printf("\nType: %04X\n", ntohs(*((uint16_t *)(&rbuf[12]))));
  printf("Cmd: %02hhX, len:%02hhX\n", rbuf[14], rbuf[15]);
  */
  clock.c[7]=rbuf[16];
  clock.c[6]=rbuf[17];
  clock.c[5]=rbuf[18];
  clock.c[4]=rbuf[19];
  clock.c[3]=rbuf[20];
  clock.c[2]=rbuf[21];
  clock.c[1]=rbuf[22];
  clock.c[0]=rbuf[23];
  //printf("Clock: %llu\n", (unsigned long long)clock.uint);
  //printf("                                                            \r");
  printf("Clockdelta: %lld   Clock: %llu           \r", (long long)(clock.uint-t), (unsigned long long)(clock.uint));
  t = clock.uint;

  //printf("Sending packet...\n");
  /*Send packet*/
#warning "You need to change the source-mac address"
  /*dest (ff:ff:ff:ff:ff:ff=broadcast), source and ethertype=0x88b5*/
  memcpy(packet, "\xFF\xFF\xFF\xFF\xFF\xFF\x00\x04\x75\xc6\xd7\xc1\x88\xb5\x00", 15);
  
  for(i=0;i < 4;i++) {
    ret = read(0, (packet+15), 128*2*24/8);
    if (ret != 128*2*24/8) {
      perror("read");
      exit(1);
    }    
    plen=15+128*2*24/8;
    ret = send(s, packet, plen, 0x0);
    if (ret < 0) {
      perror("sendto");
      exit(1);
    }
  }
}

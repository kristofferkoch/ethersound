#!/usr/bin/env python

# Framework for sending raw frames

#     This file is part of hwpulse.

#     hwpulse is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.

#     hwpulse is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.

#     You should have received a copy of the GNU General Public License
#     along with hwpulse.  If not, see <http://www.gnu.org/licenses/>.


from socket import *
import struct, string, numpy, time

proto = 0x88b5;
#proto = 0xdd88;
soc = socket(AF_PACKET, SOCK_RAW, proto);
soc.bind(("eth1", proto))

ifName, ifProto, pktType, hwType, hwAddr = soc.getsockname();

#print ifName, ifProto, pktType, hwType, hwAddr

srcAddr = hwAddr

dstAddr = "\x01\x0B\x5E\x00\x00\x00";
dstAddr = "\xff\xff\xff\xff\xff\xff";

#dstAddr = dstAddr[::-1]
#dstAddr = "\xff\xff\xff\xff\xff\xff";

#            ID  TF  Timestamp....     
ethData = "\x00"

t = (numpy.arange(48e3*10)*numpy.pi*2)/48e3

ary = numpy.sin(t*1000)*127+127
ary = ary.astype(numpy.uint8)
ary2 = numpy.sin(t*1000)*127+127
ary2 = ary2.astype(numpy.uint8)

txFrameB = struct.pack("!6s6sH",dstAddr,srcAddr,proto) + ethData;
N=220

for c in xrange(len(ary)/N):
    start = time.time()
    txFrame = txFrameB
    for i in xrange(N):
        txFrame  += chr(ary[c*N+i])+"\x00\x00" + \
            chr(ary2[c*N+i])+"\x00\x00"

    #print "Tx[%d]: "%len(txFrame) + string.join(["%02x"%ord(b) for b in txFrame]," ")
    for i in xrange(1):
        soc.send(txFrame)
    delta = time.time()-start
    print N/48e3, delta
    time.sleep(N/48e3-delta);
soc.close()

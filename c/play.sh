#!/bin/sh
sox "$1" -c2 -u -B -3 -r48000 -t raw - | sudo ./sender eth1

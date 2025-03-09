#!/bin/sh
set -x

HEXFILE=$1

TTY=/dev/ttyUSB1

stty -F $TTY speed 115200 cs8 -cstopb -parenb
cat $HEXFILE > $TTY && echo $HEXFILE uploaded to $TTY


# program FPGA:
#  openFPGALoader -b tangnano9k gowin/mk14/impl/pnr/mk14.fs

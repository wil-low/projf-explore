#!/bin/sh
set -x

HEXFILE=$1

TTY=/dev/ttyUSB1

stty -F $TTY speed 115200 cs8 -cstopb -parenb
cat $HEXFILE > $TTY && echo $HEXFILE uploaded to $TTY

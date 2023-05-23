#!/bin/sh

HEXFILE=$1
stty -F /dev/ttyACM0 speed 115200 cs8 -cstopb -parenb
cat $HEXFILE > /dev/ttyACM0
echo $HEXFILE uploaded

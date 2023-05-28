#!/bin/sh
set -x

HEXFILE=$1

if [ -c /dev/ttyACM0 ]
then
	TTY=/dev/ttyACM0
fi

if [ -c /dev/ttyUSB0 ]
then
	TTY=/dev/ttyUSB0
fi

stty -F $TTY speed 115200 cs8 -cstopb -parenb
cat $HEXFILE > $TTY && echo $HEXFILE uploaded to $TTY

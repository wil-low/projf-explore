#!/bin/sh

# Project F: Lint Script
# (C)2022 Will Green, open source software released under the MIT License
# Learn more at https://projectf.io/posts/fpga-graphics/

DIR=`dirname $0`
LIB="${DIR}/../../lib"

clear

# Lattice iCE40 iCESugar
if [ -d "${DIR}/ice40_272p" ]; then
	echo "## Linting top modules in ${DIR}/ice40_272p"
	for f in ${DIR}/ice40_272p/top_*.sv; do
		echo "##   Checking ${f}";
		~/program/svlint/svlint $f;
	done
fi

#!/bin/bash

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:`dirname \`pwd\``
#Run a file, must contain 'run_this()' and `load` all its stuff.
julia -q -L $@ -e 'run_this()'

# build environement
# adapt form xconfigure
# this version of elpa does not contain avx512 kernel

export FC=mpiifort
export FCFLAGS="-Ofast $(CRAY_xAVX) -align array64byte -heap-arrays 4096"

export CC=mpiicc 
export CFLAGS="-Ofast $(CRAY_xAVX) -fno-alias -ansi-alias"

export PREFIX="$HOME/benchmark/$COMPILER/$COMPILER_VER/$CRAY_CPU_TARGET/elpa/$ELPA_VER"
export ELPA_VER="2016.11.001.pre"

export SCALAPACK_LDFLAGS="-L${MKLROOT}/lib/intel64 -lmkl_scalapack_lp64 -lmkl_blacs_intelmpi_lp64 -lmkl_intel_lp64 -lmkl_core -lmkl_sequential" \
export SCALAPACK_FCFLAGS="-L${MKLROOT}/include" 

../configure --with-avx-optimization --prefix=$PREFIX 

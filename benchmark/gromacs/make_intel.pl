#!/usr/bin/env perl 

use strict; 
use warnings; 

use Data::Printer; 

my $compiler; 
my (@suffices, @params);  

# gromacs cmake params
my %cmake = ( 
    BUILD_SHARED_LIBS     => 'off',
    GMX_BUILD_MDRUN_ONLY  => 'on',
    CMAKE_C_COMPILER      => 'icc', 
    CMAKE_CXX_COMPILER    => 'icpc', 
    GMX_GPU               => 'off', 
    GMX_MPI               => 'off',
    GMX_OPENMP            => 'off',    
    GMX_THREAD_MPI        => 'off',
    GMX_FFT_LIBRARY       => 'mkl',
    GMX_EXTERNAL_BLAS     => 'off',
    GMX_EXTERNAL_LAPACK   => 'off',
    GMX_SIMD              => 'off', 
    GMX_CYCLE_SUBCOUNTERS => 'on', 
    GMX_DEFAULT_SUFFIX    => 'off', 
    GMX_BINARY_SUFFIX     => '', 
); 

# debug 
my $arg = shift @ARGV // ''; 

set_cmp ('intel'); 
set_simd('on'); 
set_mpi ('thread'); 
set_fft ('mkl'); 
set_omp ('on'); 
set_suff(); 

cmake(); 

sub set_cmp { 
    $compiler = shift; 
}

sub set_simd { 
    my $opt = shift; 

    if ($opt eq 'on') { 
        $cmake{GMX_SIMD} = 'AVX_512_KNL'; 
        push @suffices, 'knl', $compiler;
    } else { 
        $cmake{GMX_SIMD} = 'none'; 
        push @suffices, 'x86', $compiler;
    }
}

sub set_fft { 
    my $opt = shift; 

    $cmake{GMX_FFT_LIBRARY} = $opt; 

    # download and build fftw3 3.3.8
    if ($opt eq 'fftw3') { 
        $cmake{GMX_BUILD_OWN_FFTW} = 'on' 
    }

    # mkl:   mkl blas/lapack otherwise segmentation fault 
    # fftw3: internal blas/lapack otherwise segmentation fault
    if ($opt eq 'mkl') { 
        $cmake{GMX_EXTERNAL_BLAS}   = 'on',
        $cmake{GMX_EXTERNAL_LAPACK} = 'on',
    }

    push @suffices, $cmake{GMX_FFT_LIBRARY};  

}

sub set_mpi { 
    my $opt = shift; 

    if ($opt eq 'thread') { 
        $cmake{GMX_THREAD_MPI} = 'on'

    } elsif ($opt eq 'impi') { 
        $cmake{GMX_MPI}            = 'on'; 
        $cmake{CMAKE_C_COMPILER}   = 'mpiicc';  
        $cmake{CMAKE_CXX_COMPILER} = 'mpiicpc';  
        push @suffices, $opt; 

    } else { 
        $cmake{GMX_MPI}            = 'on'; 
        $cmake{CMAKE_C_COMPILER}   = 'mpicc';  
        $cmake{CMAKE_CXX_COMPILER} = 'mpicxx'; 
        push @suffices, $opt; 
    }
} 

# segmentation fault for thread_MPI/mkl FFT
sub set_omp { 
    my $opt = shift;  

    $cmake{GMX_OPENMP} = $opt; 
    push @suffices, 'omp' if $cmake{GMX_OPENMP} eq 'on'; 
} 

sub set_suff { 
    $cmake{GMX_BINARY_SUFFIX} = '_' . join('_', @suffices); 
    #$cmake{GMX_LIBS_SUFFIX}   = $cmake{GMX_BINARY_SUFFIX}; 
} 

sub cmake { 
    @params = map { '-D'.join('=', $_, $cmake{$_}) } sort keys %cmake; 

    # debug; 
    $arg eq '-d' 
    ? map { printf("%s\n", $_) } @params
    : system 'cmake', '..', @params; 
} 

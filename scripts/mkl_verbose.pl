#!/usr/bin/env perl 

use strict; 
use warnings; 
use Data::Printer; 
use String::Util qw(trim);

my %unit = ( 
    m => 1.e-3, 
    u => 1.e-6, 
    n => 1.e-9
);  

parse_mkl_header( \ my %blas,      "$ENV{MKLROOT}/include/mkl_blas.h"      ); 
parse_mkl_header( \ my %lapack,    "$ENV{MKLROOT}/include/mkl_lapack.h"    ); 
parse_mkl_header( \ my %scalapack, "$ENV{MKLROOT}/include/mkl_scalapack.h" ); 

parse_mkl_verbose( \%blas, \%lapack, \%scalapack ); 

tabulate_mkl( \%blas,      'blas'     ); 
tabulate_mkl( \%lapack,    'lapack'    ); 
tabulate_mkl( \%scalapack, 'scalapack' ); 

# -----------#
# SUBROUTINE #
# -----------#
# function_name => [ count, time ]
sub parse_mkl_header { 
    my ( $hash_ref, $header ) = @_; 

    open FH, '<', $header; 
    while (<FH>) { 
        if ( /void\s+(.+)\(/ ) {
            $hash_ref->{uc($1)} = [];   
        }
    }
    close FH; 
}

sub parse_mkl_verbose { 
    my ( $blas, $lapack, $scalapack ) = @_; 
     
    open FH, '<', 'std.out'; 
    
    while (<FH>) { 
        if ( /MKL_VERBOSE (\w+)\(.*\) (\d+\.?\d+)(m|u|n)/ ) { 
            if ( exists $blas->{$1} ) {  
                $blas->{$1}[0]++; 
                $blas->{$1}[1] += $2 * $unit{$3}; 
            } elsif ( exists $lapack->{$1} ) {
                $lapack->{$1}[0]++; 
                $lapack->{$1}[1] += $2 * $unit{$3}; 
            } elsif ( exists $scalapack->{$1} ) { 
                $scalapack->{$1}[0]++; 
                $scalapack->{$1}[1] += $2 * $unit{$3}; 
            }
        }
    }

    close FH; 
}

# tabulated data
sub tabulate_mkl { 
    my ( $mkl_ref, $header ) = @_; 

    my %func =
        map { $_, $mkl_ref->{$_} }  
        grep { $mkl_ref->{$_}[0] } keys $mkl_ref->%*; 

    if ( %func ) {
        print "Lib: $header\n"; 
        for ( sort { $func{$b}[1] <=> $func{$a}[1] } keys %func ) { 
            printf "%-6s  %6d  %7.3e\n", $_, $func{$_}->@*; 
        } 
        print "\n"; 
    }
} 

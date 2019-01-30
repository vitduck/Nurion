#!/usr/bin/env perl 

use strict; 
use warnings; 

use Data::Printer; 
use File::Find; 
use List::Util qw/sum/; 

my @fft_routines = qw/ 
    fft3d 
    fftwav 
    fft3d_mpi 
    fftext_mpi
    dfftw_execute 
    fftwav_mpi 
    fftbas_plan_mpi
/; 

my @mpi_routines = qw/ 
    map_forward 
    map_scatter 
    map_backward 
    map_gather 
    m_alltoallv_z
/; 

my %routine; 
my $elapsed_time; 

for my $outcar ( @ARGV ) { 
    # init
    $elapsed_time = 0; 
    %routine = (); 

    flat_profile( $outcar ); 

    if ( $elapsed_time ) { 
        my $fft = get_routines( @fft_routines ); 
        my $mpi = get_routines( @mpi_routines ); 

        printf( 
            "%s %12.5f %12.5f %12.5f %12.5f\n", 
            $outcar,
            $fft, 
            $mpi, 
            $elapsed_time - $fft - $mpi, 
            $elapsed_time
        ); 
    }
} 

sub flat_profile { 
    open FH, '<', shift @_; 
    while ( <FH> ) { 
        if ( /Elapsed time/ ) { 
            $elapsed_time = (split)[3] 
        }

        if ( /Flat profile/ ) { 
            # skip 4 files 
            <FH> for 1..4; 

            while (1) {  
                local $_ = <FH>; 
                last if /^ ---/; 

                my ( $name, $cpu, undef ) = split; 
                $routine{ $name } = $cpu; 
            }
        }
    }
    close FH; 
} 

sub get_routines { 
    # for ( @_ ) { 
        # printf "%-15s %12.5f\n", $_, $routine{$_} if exists $routine{$_}
    # } 
    
    return sum( 
        map $routine{$_}, 
        grep exists $routine{$_}, @_
    )
}

package Nurion::VASP; 

use strict; 
use warnings; 

use File::Slurp qw( read_file edit_file ); 
use File::Copy  qw( move ); 
use Data::Printer; 

use Env::Nurion qw( ldd pbs_log );

our @ISA       = qw( Exporter ); 
our @EXPORT    = ();  

our @EXPORT_OK = qw( run_vasp benchmark_vasp ); 

sub run_vasp { 
    my ( $nrepeat, $bin, $kpar, $ncore, $outdir ) = @_; 

    set_KPAR ( $kpar  ) if $kpar; 
    set_NCORE( $ncore ) if $ncore;  

    if ( $outdir ) { 
        mkdir $outdir unless -e $outdir; 

        for my $n ( 1 .. $nrepeat ) { 
            my $n_output = 
                $nrepeat == 1 ? 
                "$outdir/OUTCAR" : 
                "$outdir/OUTCAR_${n}";

            # check if job is finished
            if ( -e $n_output && read_file($n_output) =~ /Total CPU time used/ ) {
                next
            } else {
                system "mpirun $bin"; 
            }

            move 'OUTCAR' => "$n_output"; 
        }
    } else { 
        system "mpirun $bin"; 
    }
}

sub benchmark_vasp { 
    my ( $bin, $param ) = @_; 

    ldd( $bin ); 

    for my $kpar ( $param->{kpar}->@* ) { 
        for my $ncore ( $param->{ncore}->@* ) { 
            my $outdir = "$kpar-$ncore"; 

            run_vasp( $param->{n}, $bin, $kpar, $ncore, $outdir ); 
            pbs_log( "$outdir/$ENV{PBS_JOBID}" );  
        }
    }
}

sub set_KPAR { 
    my $kpar = shift; 

    edit_file { s/KPAR.+?=.+?\d+/KPAR = $kpar/ } 'INCAR'; 
}

sub set_NCORE { 
    my $ncore = shift; 

    edit_file { s/NCORE.+?=.+?\d+/NCORE = $ncore/ } 'INCAR'; 
}

1;

package Nurion::QE; 

use strict; 
use warnings; 

use File::Slurp 'read_file'; 
use Data::Printer; 

use Env::Nurion qw( ldd pbs_log );

our @ISA       = qw( Exporter ); 
our @EXPORT    = ();  
our @EXPORT_OK = qw( run_pwscf run_linear benchmark_pwscf benchmark_linear profile_pwscf );  

sub run_pwscf { 
    my ($nrepeat, $bin, $input, $nk, $ntg, $nd, $outdir) = @_; 

    # output file 
    my $output = $input =~ s/(.+)\.in/$1.out/r;

    if ( $outdir ) { 
        mkdir $outdir unless -e $outdir; 
        
        for my $n ( 1 .. $nrepeat ) {
            my $n_output = "$outdir/${n}_$output"; 

            # check if job is finished
            if ( -e $n_output && read_file($n_output) =~ /JOB DONE/ ) {
                next
            } else {
                system "mpirun $bin -nk $nk -ntg $ntg -nd $nd -inp $input > $n_output ";
            }
        }
    } else { 
        system "mpirun $bin -nk $nk -ntg $ntg -nd $nd -inp $input > ./$output ";
    }
}

sub benchmark_pwscf { 
    my ( $qe, $param ) = @_;  

    ldd( $qe ); 

    for my $nk ( $param->{nk}->@* ) { 
        for my $ntg ( $param->{ntg}->@* ) { 
            for my $nd ( $param->{nd}{$nk}->@* ) {
                my $outdir = "$nk-$ntg-$nd"; 
                
                run_pwscf( $param->{n}, $qe, $param->{inp}, $nk, $ntg, $nd, $outdir ); 

                # memory
                system "qstat -f $ENV{PBS_JOBID} > $outdir/$ENV{PBS_JOBID}.dat";
            }
        }
    }

    clean_wfc(); 
    clean_mix(); 
}

sub run_linear { 
    my ( $bin, $matrix_size, $nproc_ortho ) = @_; 

    my $prefix = "$ENV{PBS_JOBID}_$matrix_size"; 

    if ( $nproc_ortho ) { 
        system 'mpirun', $bin, '-n', $matrix_size, '-ndiag', $nproc_ortho; 
        pbs_log( "$prefix-$nproc_ortho.log" );  
    } else { 
        system 'mpirun', $bin, '-n', $matrix_size; 
        pbs_log( "$prefix.log" );  
    }
}

sub benchmark_linear { 
    my ( $la, $param ) = @_; 

    # debug
    p $param; 

    for my $size ( $param->{size}->@* ) { 
        for my $ndiag ( $param->{ndiag}->@* ) { 
            for my $stat ( 1 .. $param->{stat} ) { 
                run_linear( $la, $size, $ndiag ); 

                # rename output file if required
                if ( $param->{stat} == 1 ) { 
                    next; 
                } else { 
                    rename "test_$size-$ndiag.out" => "test_$size-$ndiag-$stat.out"
                }
            }
        }
    }
}

sub profile_pwscf { 
    my ( $bin, $input, $nk, $ntg, $nd, $vtune_dir ) = @_; 
    
    # output file 
    my $output = $input =~ s/(.+)\.in/$1.out/r;

    system "mpirun amplxe-cl -quiet -collect hotspots -trace-mpi -data-limit=0 -knob sampling-interval=1000 -result-dir $vtune_dir " .
           "$bin -nk $nk -ntg $ntg -nd $nd -inp $input > ./$output ";
}

# remove temp files
sub clean_wfc { 
    unlink <*wfc*>; 
}

sub clean_mix { 
    unlink <*mix*>; 
}

1; 

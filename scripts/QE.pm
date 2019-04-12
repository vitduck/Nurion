package QE; 

use strict; 
use warnings; 

use Env::Modulecmd;
use Capture::Tiny 'capture_stderr';
use File::Slurp 'read_file'; 

use Nurion qw( ldd );

our @ISA       = qw( Exporter ); 
our @EXPORT    = ();  
our @EXPORT_OK = qw( run_pwscf profile_pwscf parallel_benchmark linear_benchmark );  

sub run_pwscf { 
    my ($nrepeat, $bin, $input, $nk, $ntg, $nd, $outdir) = @_; 

    # output file 
    ( my $output = $input ) =~ s/(.+)\.in/$1.out/;

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

sub profile_pwscf { 
    my ( $bin, $input, $nk, $ntg, $nd, $vtune_dir ) = @_; 
    
    # output file 
    ( my $output = $input ) =~ s/(.+)\.in/$1.out/;

    system "mpirun amplxe-cl -quiet -collect hotspots -trace-mpi -result-dir $vtune_dir " .
           "$bin -nk $nk -ntg $ntg -nd $nd -inp $input > ./$output ";
}

sub parallel_benchmark { 
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

sub linear_benchmark { 
    my ( $bin, $matrix_size, $nproc_ortho ) = @_; 

    my $pbs_log = "$ENV{PBS_JOBID}_$matrix_size"; 

    if ( $nproc_ortho ) { 
        system 'mpirun', $bin, '-n', $matrix_size, '-ndiag', $nproc_ortho; 
        $pbs_log = "$pbs_log-$nproc_ortho.log"; 
    } else { 
        system 'mpirun', $bin, '-n', $matrix_size; 
        $pbs_log = "$pbs_log.log"; 
    }

    # memory
    system "qstat -f $ENV{PBS_JOBID} > $pbs_log"; 
}

# remove temp files
sub clean_wfc { 
    unlink <*wfc*>; 
}

sub clean_mix { 
    unlink <*mix*>; 
}

1; 

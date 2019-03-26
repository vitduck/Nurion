package QE; 

use strict; 
use warnings; 

use Env::Modulecmd;
use Capture::Tiny 'capture_stderr';
use File::Slurp 'read_file'; 

our @ISA       = qw/Exporter/; 
our @EXPORT    = qw/run_pwscf/; 
our @EXPORT_OK = (); 

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

1; 

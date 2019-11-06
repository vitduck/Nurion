#!/usr/bin/env perl 

#PBS -V
#PBS -N test
#PBS -q normal
#PBS -e std.err
#PBS -o std.out
#PBS -l select=1:ncpus=16:mpiprocs=16:ompthreads=1
#PBS -l walltime=1:00:00

use strict; 
use warnings; 
use autodie; 

use File::Slurp qw/edit_file read_file/; 

# module load 
# system('module load ...) does not work since module is an alias
use Env::Modulecmd { load => 'craype-mic-knl' };  

# cray
# use Env::Modulecmd { load => 'cce/8.6.3'              }; 
# use Env::Modulecmd { load => 'PrgEnv-cray/1.0.2'      }; 
# use Env::Modulecmd { load => 'cray-libsci/17.09.1'    }; 
# use Env::Modulecmd { load => 'cray-fftw_impi/3.3.6.2' }; 

# intel
use Env::Modulecmd { load => 'intel/18.0.3'   }; 
use Env::Modulecmd { load => 'impi/18.0.3'    }; 

# gnu
# use Env::Modulecmd { load => 'craype-mic-knl' };  
# use Env::Modulecmd { load => 'gcc/7.2.0'      }; 
# use Env::Modulecmd { load => 'openmpi/3.1.0'  }; 
# use Env::Modulecmd { load => 'lapack/3.7.0'   };   
# use Env::Modulecmd { load => 'fftw_mpi/3.3.7' }; 

# vasp_binary 
my $dir = '/scratch/pop19/02-qe/intel/00-bin'; 
my $opt = 'Ofast'; 
my $cpu = 'knl'; 

my $bin = "$dir/$opt/$cpu/pw.x"; 

# execution 
chdir $ENV{PBS_O_WORKDIR}; 

# location of pseudopotential
my $upf = '/scratch/pop19/02-qe/upf'; 

my @dirs = <pw_*>; 
#my @dirs = qw( pw_berry ); 

for ( @dirs ) { 
    printf "%s:\n", $_; 
    
    chdir $_; 
    
    # numeric sort due to inconsistent naming of input file
    for my $input ( 
        sort { (($a =~ /(\d+)/)[0] || 0) <=> (($b =~ /(\d+)/)[0] || 0) } 
        grep !/^benchmark/,  <*.in> 
    ) {  
        # if the pseudo_dir tag is missing 
        my $slurp_input = read_file( $input ); 
        
        unless ( $slurp_input =~ /pseudo_dir/ ) { 
            edit_file { 
                s/&(control|CONTROL)/&$1\npseudo_dir='$upf'/ 
            } $input; 
        }
        
        # output file 
        ( my $output = $input ) =~ s/(.+)\.in/$1.out/; 

        # check if output exists
        if ( -e $output ) { 
            my $slurp_output = read_file( $output );  

            # restart failed job 
            unless ( $slurp_output =~ /JOB DONE/ ) { 
                printf "\t%s: RESTARTED\n", $output; 
                system "mpirun $bin -ndiag 16 -inp $input > $output"; 
            }
        } else { 
            system "mpirun $bin -ndiag 16 -inp $input > $output"; 
        }

        my $slurp_output = read_file( $output );  
        # check job completion
        if ( $slurp_output =~ /JOB DONE/ ) {  
            printf "\t%s: PASSED\n", $output
        } else { 
            printf "\t%s: FAILED\n", $output
        }
    }
    
    chdir '..'; 
} 

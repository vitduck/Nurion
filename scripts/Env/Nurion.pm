package Env::Nurion; 

use strict; 
use warnings; 

use Env::Modulecmd;
use Capture::Tiny 'capture_stderr';

our @ISA       = qw(Exporter); 
our @EXPORT    = qw(ldd pbs_log module_init module_load module_list module_load_cpu module_load_env); 
our @EXPORT_OK = (); 

our %cpu = ( 
    'mic-knl'     => 'craype-mic-knl', 
    'x86-skylake' => 'craype-x86-skylake', 
); 

our %env = ( 
    intel => [ 
        'intel/18.0.3', 
        'impi/18.0.3',    
        'vtune/18.0.3', 
        'fftw_mpi/3.3.7'
    ],
    cray => [ 
        'cce/8.6.3', 
        'PrgEnv-cray/1.0.2', 
        'cray-libsci/17.09.1', 
        'cray-fftw_impi/3.3.6.2' 
    ], 
    gnu  => [ 
        'gcc/7.2.0', 
        'openmpi/3.1.0', 
        'lapack/3.7.0', 
        'fftw_mpi/3.3.7' 
    ],
); 

sub module_list { 
    my @modules = split ' ',  capture_stderr { system 'modulecmd', 'perl', 'list' }; 

    # remove header file
    splice @modules, 0, 3; 

    # minimum
    return grep !/\d+\)/, @modules; 
} 

sub module_load { 
    Env::Modulecmd::load($_) for @_
}

sub module_unload { 
    Env::Modulecmd::unload($_) for @_
}

sub module_init { 
    module_unload(grep !/craype-network-opa/, module_list()) 
} 

sub module_load_cpu { 
    my $target = shift; 

    module_load($cpu{$target}) if exists $cpu{$target}
} 

sub module_load_env { 
    my $preset = shift; 

    module_load($env{$preset}->@*); 

    # cray
    if ( $preset =~ /cray/ ) { 
        $ENV{MPI} = lc( $ENV{PE_MPI} ); 
        $ENV{KISTI_MPI_VER} = $ENV{IMPI_VERSION}; 
    }

    my @current = module_list(); 
    print "Modules: @current\n"; 
} 

sub ldd { 
    my ( $bin, $output ) = @_; 

    system "echo $bin >  $output"; 
    system "ldd  $bin >> $output"; 
}

sub pbs_log { 
    my ( $prefix, $outdir ) = @_; 

    my $log = shift // "$ENV{PBS_JOBID}.dat"; 

    system "qstat -f $ENV{PBS_JOBID} > $log";  
}

1; 

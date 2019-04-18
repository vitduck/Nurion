package Nurion; 

use strict; 
use warnings; 

use Env::Modulecmd;
use Capture::Tiny 'capture_stderr';

our @ISA       = qw(Exporter); 
our @EXPORT    = qw(module_init module_load_cpu module_load_env); 
our @EXPORT_OK = qw(ldd pbs_log ); 

our %cpu = ( 
    'mic-knl'     => 'craype-mic-knl', 
    'x86-skylake' => 'craype-x86-skylake', 
); 

our %env = ( 
    intel => [ 
        'intel/18.0.3', 
        'impi/18.0.3',    
        'vtune/18.0.3' 
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

sub module_init { 
    my @modules = module_list(); 
    
    for ( @modules ) { 
        next if /craype-network-opa/; 
        Env::Modulecmd::unload( $_)
    } 
} 

sub module_load_cpu { 
    my $target = shift; 

    if ( exists $cpu{$target} ) {  
        Env::Modulecmd::load( $cpu{$target} );
    } 
} 

sub module_load_env { 
    my $compiler = shift; 

    for ( $env{$compiler}->@* ){ 
        Env::Modulecmd::load( $_ ); 
    }
    
    # cray
    if ( $compiler =~ /cray/ ) { 
        $ENV{MPI} = lc( $ENV{PE_MPI} ); 
        $ENV{KISTI_MPI_VER} = $ENV{IMPI_VERSION}; 
    }

    my @current = module_list(); 
    print "Modules: @current\n"; 
} 

sub ldd { 
    my $bin = shift; 

    system "echo Build: $bin >  link.dat"; 
    system "echo Linking:    >> link.dat";  
    system "ldd $bin         >> link.dat"; 
}

sub pbs_log { 
    my $log = shift // "$ENV{PBS_JOBID}.dat"; 

    system "qstat -f $ENV{PBS_JOBID} > $log";  
}

1; 

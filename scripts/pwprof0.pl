#!/usr/bin/env perl 

use strict; 
use warnings; 

use File::Find; 
use File::Slurp 'read_file';  
use String::Util 'trim';  
use Data::Printer; 

my %wtime; 

@ARGV == 0 ? find(\&walltime, '.') : find(\&walltime, @ARGV); 

my $max_length = ( sort { $a <=> $b } map { length $_ } keys %wtime )[-1];  

for my $dir ( sort { $a cmp $b } keys %wtime ) {  
    print_time( $dir ); 
}

sub walltime { 
    if ( /\.out$/ && $_ ne 'std.out' ) { 
        my $sum; 

        #printf "%s\n", $File::Find::dir; 
        my $output   = read_file($_);

        if ( $output =~ /JOB DONE/ ) { 
            my $walltime = to_second(trim($1)) if $output =~ /PWSCF.*CPU(.*)WALL/; 
            my $h_psi    = trim($1)            if $output =~ /h_psi.+?(\d+\.\d+)s WALL/; 
            my $diaghg   = trim($1)            if $output =~ /[cr]diaghg(?!:).+?(\d+\.\d+)s WALL/; 
            my $sum_band = trim($1)            if $output =~ /sum_band.+?(\d+\.\d+)s WALL/; 

            $wtime{$File::Find::dir}{$_}{walltime} = $walltime; 
            $wtime{$File::Find::dir}{$_}{h_psi}    = $h_psi; 
            $wtime{$File::Find::dir}{$_}{diaghg}   = $diaghg; 
            $wtime{$File::Find::dir}{$_}{sum_band} = $sum_band; 
            $wtime{$File::Find::dir}{$_}{others}   = $walltime - $h_psi - $diaghg - $sum_band
        }
    }
}

sub to_second { 
    my $time = shift;
   
    if ( $time =~ /(.+)m\s?(.+)s/ ) { 
        return 60*$1 +$2
    } elsif ( $time =~ /(.+)s/ ) { 
        return $1 
    } else { 
        return undef
    }
} 

sub print_time { 
    my $dir = shift; 

    printf "%${max_length}s\n", $dir;   

    for my $file ( sort { $a cmp $b } keys $wtime{$dir}->%* ) { 
        printf( 
            "%20s %7.1f %7.1f %7.1f %7.1f %7.1f \n", 
            $file, $wtime{$dir}{$file}->@{qw/sum_band h_psi diaghg others walltime/}  
        ); 
    }
} 

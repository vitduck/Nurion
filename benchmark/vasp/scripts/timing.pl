#!/usr/bin/env perl 

use strict; 
use warnings; 

use File::Find;
use Data::Printer; 

my %outcar;  
my @dirs = @ARGV ? @ARGV : qw/./;  
find( \&outcar, @dirs ); 

my %success = 
    map { $_ => $outcar{$_} }  
    grep $outcar{$_}, keys %outcar; 

my %fail = 
    map { $_ => $outcar{$_} }  
    grep  ! $outcar{$_}, keys %outcar; 

print "\nCompleted:\n"; 
p %success; 

print "\nFailed:\n"; 
p %fail; 

sub outcar { 
    if ( /OUTCAR/ ) {  
        my $elapsed_time; 
        
        open FH, '<', $_; 
        for ( <FH> ) { 
            $elapsed_time = (split)[-1] if /Elapsed time.*(\d+\.\d+)/ 
        }
        close FH; 

        $outcar{ $File::Find::name } = $elapsed_time ? $elapsed_time : undef; 
    }
}

#!/usr/bin/env perl

use strict; 
use warnings; 

use Data::Printer; 
use List::Util 'max'; 

my %walltime; 

while (<>) { 
    my ($parameter, @walltimes) = split; 
    push $walltime{ $parameter }->@*, @walltimes; 
}

my $slength = max( map length($_), keys %walltime ); 

# sort based on averaged time
for my $parameter ( sort { $walltime{$a}[-2] <=> $walltime{$b}[-2] } keys %walltime ) {  
    
   printf "%-${slength}s %10.2f %10.2f %10.2f %10.2f %10.2f\n", $parameter, $walltime{ $parameter }->@*
} 

#!/usr/bin/env perl 

use strict; 
use warnings; 

use File::Find; 
use Data::Printer; 
use Statistics::Lite qw/mean stddev/; 

my %file; 

find(\&traverse, '.'); 

print_stat( 'diagonalize_parallel' ); 
print_stat( 'sqr_mm_cannon'        ); 

sub print_stat { 
    my ( $string ) = @_; 
    my $output = "$string.dat"; 

    print "=> $output\n"; 

    open my $fh, '>', $output or die "Cannot open $output\n"; 

    my $lcount = 0; 
    my $tcount = keys %file; 

    for my $size ( sort { $a <=> $b } keys %file ) {  
        $lcount++; 
        for my $node ( sort { $a <=> $b } keys $file{$size}->%* ) { 
            for my $ndiag ( sort { $a <=> $b } keys $file{$size}{$node}->%* ) { 
                my @timings; 
                
                for my $file ( $file{ $size }{ $node }{ $ndiag }->@* ) { 
                    push @timings, parse( $file, $string ); 
                }

                if ( @timings == 3 ) { 
                    printf $fh ( 
                        "%3d %10d %10d %7.2f %7.2f %7.2f %7.2f %7.2f\n", 
                        $node, $size, $ndiag, @timings, mean( @timings ), stddev( @timings )
                    )
                }
            }
        }
        # double blank break
        unless ( $lcount == $tcount ) { printf $fh "\n\n" } 
    }

    close $fh; 
} 

sub parse { 
    my ( $file, $string ) = @_; 

    open my $fh, '<', $file or die "Cannot open $file\n";  
   
    my $time; 
    while ( <$fh> ) { 
        if ( /$string/ ) { 
            $time = ( split )[-2]  =~ s/D/E/r;  
            last; 
        }
    }

    close $fh; 

    return $time; 
} 

sub traverse { 
    if ( $File::Find::name =~ /select_(\d+)\/test_(\d+)-(\d+)-\d+\.out/ ) { 
        push $file{ $2 }{ $1 }{ $3 }->@*, $File::Find::name; 
    }
} 

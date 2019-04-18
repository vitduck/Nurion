#!/usr/bin/env perl 

use strict;
use warnings; 

use Data::Printer; 
use File::Spec; 
use File::Find;
use File::Slurp      qw/read_file/;
use String::Util     qw/trim/; 
use Statistics::Lite qw/mean stddev/; 

my ( @files, %walltime );  

find(\&get_output, '.'); 

for my $file ( @files ) { 
    my $walltime  = 0.0; 
    my $output    = read_file( $file ); 

    if ( $output =~ /PWSCF.*CPU(.*)WALL/ ) {
        my (undef, $dir, undef) = File::Spec->splitpath( $file ); 

        # remove trailing '/'
        chop( $dir ); 
        push $walltime{ $dir }->@*, to_second(trim($1)) 
    }

}

for my $parameter ( 
        map  { $_->[0] }
        sort { $a->[1] <=> $b->[1] ||
               $a->[2] <=> $b->[2] ||
               $a->[3] <=> $b->[3]   }
        map  { [ $_, split '-', $_ ] } keys %walltime ) { 
    
    my @times = $walltime{ $parameter }->@*; 

    if ( grep /failed/, @times ) { 
        my $format = "%-12s".("%s   "x@times)."\n"; 
        printf $format, $parameter, @times; 
    } else { 
        if ( @times >= 3 ) { 
            my $format = "%-12s".("%7.2f   "x@times)."%7.2f   %.2f\n"; 
            printf $format, $parameter, @times, mean(@times), stddev(@times) 
        } else { 
            my $format = "%-12s".("%7.2f   "x@times)."\n";  
            printf $format, $parameter, @times; 
        }
    }
}

sub get_output { 
    if ( $File::Find::name =~ /\d+-\d+-\d+\/\d+.+?\.out/ ) { 
        push @files, File::Spec->abs2rel( $File::Find::name ); 
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

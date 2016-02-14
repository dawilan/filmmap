#!/usr/bin/env perl
# findfilms.pl - quick video file management

## Includes

use File::Find;
use Data::Dumper;    ## DEBUG

#my @dirs   = qw( /media2/movies /media3/movies /media4/movies /media/tv );
my @dirs = qw( /media/tv );    ## DEBUG

my $movies          = {};
my $extension_regex = qr/\.mkv$|\.mp4$|\.avi$|\.ts/;

find(
    sub {
        -f
          && $extension_regex
          && push(
            @{ $movies->{'list'} },
            Video->new(
                {
                    name => $_,
                    dir  => $File::Find::dir,
                    path => $File::Find::name,
                    size => -s $_,
                }
            )
          );
    },
    @dirs
);

foreach my $movie ( @{ $movies->{'list'} } ) {
    is_duplicate($movie);
}

## Printing to user ##

print "\n";
print 'Number of Duplicates: ' . scalar @{ $movies->{'duplicates'} } . "\n";
printf "Gigs of Duplicates: %.2f\n",
  $movies->{'total_duplicate_size'} / ( 1024 * 1024 * 1024 );
print "\n";

sub is_duplicate {
    my ($movie) = @_;

    my $regex = qr/\.\d($extension_regex)/;
    if ( $movie->{'name'} =~ $regex ) {
        push( @{ $movies->{'duplicates'} }, $movie );
        $movies->{'total_duplicate_size'} += $movie->{'size'};
    }
}

package Video;
use strict;
use warnings;
use Data::Dumper;

sub new {
    my ( $class, $args ) = @_;
    my $self = bless {
        name => $args->{'name'},
        dir  => $args->{'dir'},
        path => $args->{'path'},
        size => $args->{'size'},
    }, $class;
}

1;

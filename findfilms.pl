#!/usr/bin/env perl

use File::Find;
use Data::Dumper;

my @dirs = qw( '/media2/movies', '/media3/movies', '/media4/movies' );
my @movies;

find(
    sub {
        -f
          && /\.mkv$|\.mp4$|\.avi$|\.ts/
          && push(
            @movies,
            Video->new(
                {
                    path => $File::Find::dir,
                    name => $_,
                    size => -s $_,
                }
            )
          );
    },
    '/media3/movies'
);

foreach my $file ( @movies ) {
   print Dumper $file;
}

package Video;
use strict;
use warnings;
use Data::Dumper;

sub new {
    my ( $class, $args ) = @_;
    my $self = bless {
        name => $args->{'name'},
        path => $args->{'path'},
        size => $args->{'size'},
    }, $class;
}

1;

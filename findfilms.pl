#!/usr/bin/env perl
# findfilms.pl - quick video file management

## Includes

use File::Find;
use Data::Dumper;    ## DEBUG

#my @dirs   = qw( /media2/movies /media3/movies /media4/movies /media/tv );
my @dirs = qw( /media/tv );    ## DEBUG

my $videos          = {};
my $extension_regex = qr/\.mkv$|\.mp4$|\.avi$|\.ts/;
my ( $show_list, $verbose );

## Get user supplied args
my @ARGS = @_;

my $arg_count = '0';

foreach my $arg (@ARGV) {
    $arg_count++;
    print "$arg_count: $arg\n";
    if ( $arg eq '--list' ) {
        print "# \#show_list: enabled\n" if $verbose;
        $show_list = 1;
    }
    $verbose = 1 if $arg eq '-v' or $arg eq '--verbose';
}

find(
    sub {
        -f
          && $extension_regex
          && push(
            @{ $videos->{'list'} },
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

foreach my $video ( @{ $videos->{'list'} } ) {
    is_duplicate($video);
}

## Printing to user ##

print "\n";
print 'Number of Duplicates: ' . scalar @{ $videos->{'duplicates'} } . "\n";
printf "Gigs of Duplicates: %.2f\n",
  $videos->{'total_duplicate_size'} / ( 1024 * 1024 * 1024 );
print "\n";

sub is_duplicate {
    my ($video) = @_;

    my $regex = qr/\.\d($extension_regex)/;
    if ( $video->{'name'} =~ $regex ) {
        push( @{ $videos->{'duplicates'} }, $video );
        $videos->{'total_duplicate_size'} += $video->{'size'};
    }
    $video->{'rel_path'} = $video->{'path'};
    $video->{'rel_path'} =~ s{\s}{\\ }g;
    $video->{'rel_path'} =~ s{\[}{\\[}g;
    $video->{'rel_path'} =~ s{\]}{\\]}g;
    $video->{'rel_path'} =~ s{\(}{\\(}g;
    $video->{'rel_path'} =~ s{\)}{\\)}g;
}

sub in_gigs {
    my ($bytes) = @_;
    my $gigs;
    $gigs = sprintf "%.2f", $bytes / ( 1024 * 1024 * 1024 );
    return $gigs;
}

if ($show_list) {
    my %sorted;
    print "# \$show_list is active\n";
    foreach my $video ( @{ $videos->{'duplicates'} } ) {
        $video->{'size_gb'} = in_gigs( $video->{'size'} );
        if ($verbose) {
            print Dumper $video;
        }
        else {
            $video->{'size_gb'} = in_gigs( $video->{'size'} );
            print "$video->{'size_gb'}: $video->{'path'}\n";
        }
    }
}

#my @sorted = sort {-s $a <=> -s $b } @{$videos->{'duplicates'}};

#foreach my $val ( sort {-s $a <=> -s $b } @{$videos->{'duplicates'}} ) {
#    print "# \$val->{'size} -> $val->{'size'}\n";
#}

#foreach my $sorted ( sort { $b <=> $a } @{$video->{'duplicates'}} ) {
#    print $sorted . "\n";
#}

@sorted;

#print Dumper $video->{'duplicates'};

#print Dumper $videos->{'duplicates'};
#print Dumper $videos->{'duplicates'};

foreach my $file (@movies) {
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
        dir  => $args->{'dir'},
        path => $args->{'path'},
        size => $args->{'size'},
    }, $class;
}

1;

#!/usr/bin/env perl
# findfilms.pl - quick video file management

## Includes

use File::Find;
use Data::Dumper;    ## DEBUG

#my @dirs   = qw( /media2/movies /media3/movies /media4/movies /media/tv );
my @dirs = qw( /media/tv );    ## DEBUG

my $videos = {};

my $extension_regex = qr/\.mkv$|\.mp4$|\.avi$|\.ts$/;
my ( $show_list, $verbose, $sort_by_size, $find_duplicates, $trash_collect,
    $samples );

## Get user supplied args
my @ARGS = @_;

$verbose         = 1 if ( grep /--verbose/,         @ARGV );
$show_list       = 1 if ( grep /--list/,            @ARGV );
$sort_by_size    = 1 if ( grep /--sort_by_size/,    @ARGV );
$find_duplicates = 1 if ( grep /--find_duplicates/, @ARGV );
$trash_collect   = 1 if ( grep /--trash_collect/,   @ARGV );
$find_samples    = 1 if ( grep /--find_samples/,    @ARGV );

print "# show_list is enabled\n"       if $show_list       && $verbose;
print "# verbose is enabled\n"         if $verbose;
print "# sort_by_size is enabled\n"    if $sort_by_size    && $verbose;
print "# find_duplicates is enabled\n" if $find_duplicates && $verbose;

find(
    sub {
        if ( -f && /$extension_regex/ ) {
            push(
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
        }
        if ( -f && !/$extension_regex/ ) {
            push(
                @{ $videos->{'trash_list'} },
                Video->new(
                    {
                        name => $_,
                        dir  => $File::Find::dir,
                        path => $File::Find::name,
                        size => -s $_,
                    }
                )
            );
        }
        if ( -f && /sample/i ) {
            push(
                @{ $videos->{'sample_list'} },
                Video->new(
                    {
                        name => $_,
                        dir  => $File::Find::dir,
                        path => $File::Find::name,
                        size => -s $_,
                    }
                )
            );
        }
    },
    @dirs
);

foreach my $video ( @{ $videos->{'list'} } ) {
    is_duplicate($video);
}

## Printing to user ##

if ($sort_by_size) {
    @{ $videos->{'list_sorted_by_size'} } =
      _sort_by_size( @{ $videos->{'list'} } );
    foreach $video ( @{ $videos->{'list_sorted_by_size'} } ) {
        print "$video->{'name'}\n";
    }
}

if ($find_duplicates) {
    print "\n";
    print 'Number of Duplicates: ' . scalar @{ $videos->{'duplicates'} } . "\n";
    printf "Gigs of Duplicates: %.2f\n",
      $videos->{'total_duplicate_size'} / ( 1024 * 1024 * 1024 )
      if $verbose;
    print "\n";
}

if ($find_samples) {

    #    print Dumper $videos->{'sample_list'};
    my $total_size = 0;
    print 'Total Sample Files: ' . scalar @{ $videos->{'sample_list'} } . "\n";
    foreach my $sample ( @{ $videos->{'sample_list'} } ) {
        $total_size += $sample->{'size'};
    }
    print 'Total Sample Size: ' . _in_gigs( $total_size ) . " GB\n";
}

sub _sort_by_size {
    my @list_to_sort = @_;
    my @sorted = sort { $a->{'size'} <=> $b->{'size'}; } @list_to_sort;
    if ($verbose) {
        foreach my $video (@sorted) {
            print _in_gigs( $video->{'size'} ) . ": "
              . _cli_rinse( $video->{'path'} ) . "\n";
        }
    }
    return @sorted;
}

sub is_duplicate {
    my ($video) = @_;

    my $regex = qr/\.\d($extension_regex)/;
    if ( $video->{'name'} =~ $regex ) {
        push( @{ $videos->{'duplicates'} }, $video );
        $videos->{'total_duplicate_size'} += $video->{'size'};
    }
}

sub _cli_rinse {
    my ($path) = @_;
    $path =~ s{\s}{\\ }g;
    $path =~ s{\[}{\\[}g;
    $path =~ s{\]}{\\]}g;
    $path =~ s{\(}{\\(}g;
    $path =~ s{\)}{\\)}g;
    return $path;
}

sub _in_gigs {
    my ($bytes) = @_;
    my $gigs;
    $gigs = sprintf "%.2f", $bytes / ( 1024 * 1024 * 1024 );
    return $gigs;
}

if ($trash_collect) {
    print Dumper $videos->{'trash_list'};
}

if ($show_list) {
    foreach my $video ( @{ $videos->{'list'} } ) {
        print _cli_rinse( $video->{'path'} ) . "\n";
    }
}

if ($find_duplicates) {
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

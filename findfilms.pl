#!/usr/bin/env perl
# findfilms.pl - quick video file management

## Includes

use File::Find;
use Data::Dumper;    ## DEBUG

#my @dirs   = qw( /media2/movies /media3/movies /media4/movies /media/tv );
my @dirs = qw( /media/tv );    ## DEBUG

my $videos          = {};
my $extension_regex = qr/\.mkv$|\.mp4$|\.avi$|\.ts$/;
my ( $show_list, $verbose, $sort_by_size, $find_duplicates );

## Get user supplied args
my @ARGS = @_;

$verbose         = 1 if ( grep /--verbose/,         @ARGV );
$show_list       = 1 if ( grep /--list/,            @ARGV );
$sort_by_size    = 1 if ( grep /--sort_by_size/,    @ARGV );
$find_duplicates = 1 if ( grep /--find_duplicates/, @ARGV );

print "# show_list is enabled\n"       if $show_list       && $verbose;
print "# verbose is enabled\n"         if $verbose;
print "# sort_by_size is enabled\n"    if $sort_by_size    && $verbose;
print "# find_duplicates is enabled\n" if $find_duplicates && $verbose;

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

if ($sort_by_size) {
    ## This needs to be written
    my @sorted_by_size = _sort_by_size( @{ $videos->{'list'} } );
    print "# sort_by_size called\n";

    #    print Dumper \@sorted_by_size;
}

if ($find_duplicates) {
    print "\n";
    print 'Number of Duplicates: ' . scalar @{ $videos->{'duplicates'} } . "\n";
    printf "Gigs of Duplicates: %.2f\n",
      $videos->{'total_duplicate_size'} / ( 1024 * 1024 * 1024 )
      if $verbose;
    print "\n";
}

sub _sort_by_size {
    my @list_to_sort = @_;

    my @sorted = sort {

      } @list_to_sort;

      #    print Dumper \@list_to_sort;
}

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

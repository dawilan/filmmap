#!/usr/bin/env perl
# findfilms.pl - quick video file management

package Video;

use File::Find;
use Data::Dumper;

my @dirs = qw( /HGST1/tv /media1/tv /media2/tv );    ## DEBUG

my $trashbin = '/media/trashvbin/';

my $videos = {};

my $extension_regex = qr/.(mkv|m4v|mp4|flv|avi|ts|webm|mpg|txt|nfo|sub|idx)$/;
my (
    $show_list,       $verbose,       $sort_by_size,
    $find_duplicates, $trash_collect, $samples,
    $move,            $remove,        $help,
    $commit
);

$commit          = 1 if ( grep /--commit|-c/,                           @ARGV );
$verbose         = 1 if ( grep /--verbose|-v/,                          @ARGV );
$show_list       = 1 if ( grep /--list|-l/,                             @ARGV );
$sort_by_size    = 1 if ( grep /--sort_by_size|--size_sort|--size/,     @ARGV );
$find_duplicates = 1 if ( grep /--find_duplicates|--dups/,              @ARGV );
$trash_collect   = 1 if ( grep /--trash_collect|--trash|-t/,            @ARGV );
$find_samples    = 1 if ( grep /--find_samples|--samples|-s$/,          @ARGV );
$remove          = 1 if ( grep /--remove|--rm|--del|--delete|--commit/, @ARGV );
$move            = 1 if ( grep /--move|--relocate/,                     @ARGV );
$help = 1 if ( grep /--help|-h/, @ARGV || defined !@ARGV );

_print_eom() if defined $help;

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
    _print_duplicate_size();
}

if ($trash_collect) {
    foreach $video ( @{ $videos->{'trash_list'} } ) {
        if ( $remove ) {
            print "[DELETING TRASH FILE]: $video->{path}\n";
            unlink( $video->{path} );
        } else {
            print "[TRASH IDENTIFIED]: $video->{path}\n";
        }
    }
}

if ($show_list) {
    foreach my $video ( @{ $videos->{'list'} } ) {
        print _cli_rinse( $video->{'path'} ) . "\n";
    }
}

if ($find_samples && !$remove ) {
    _parse_file_size();
}

if ( $remove ) {
    print "\n\t\tDUPLICATES FLAGGED FOR REMOVAL!!!\n\n";
    if ( $find_samples ) {
        if ( $verbose ) {
            foreach $sample ( @{ $videos->{'sample_list'} } ) {
                print $sample->{'path'} ."\n";
            }
        }
        if ( $commit ) {
            foreach my $sample ( @{ $videos->{'sample_list'} } ) {
                print "----> \unlink( $sample->{'path'})\n";
                unlink( $sample->{'path'});
            }
        }
    }
    _parse_file_size();
}

if ($find_duplicates && !$remove ) {
    foreach my $video ( @{ $videos->{'duplicates'} } ) {
        $video->{'size_gb'} = _in_gigs( $video->{'size'} );
        if ($verbose) {
            print Dumper $video->{'path'};
        }
        else {
            $video->{'size_gb'} = in_gigs( $video->{'size'} );
            print "$video->{'size_gb'}: $video->{'path'}\n";
        }
    }
}

sub is_duplicate {
    my ($video) = @_;

    my $regex = qr/\d\.\d($extension_regex)/;
    if ( $video->{'name'} =~ $regex && $video->{'name'} !~ /5\.1/ ) {
        push( @{ $videos->{'duplicates'} }, $video );
        $videos->{'total_duplicate_size'} += $video->{'size'};
    }
}

if ( $find_duplicates && $remove ) {
    my @d = map{ print "Removing $_->{'path'}\n" } @{ $videos->{'duplicates'} } if $verbose;
    my @d = map{ unlink $_->{'path'} } @{ $videos->{'duplicates'} } if $commit ;
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

sub _print_duplicate_size{
    print "\n";
    print 'Number of Duplicates: ' . scalar @{ $videos->{'duplicates'} } . "\n";
    printf "Gigs of Duplicates: %.2f\n",
    $videos->{'total_duplicate_size'} / ( 1024 * 1024 * 1024 )
    if $verbose;
    print "\n";
}

sub _parse_file_size {
    my $total_size = 0;
    print "\n"
    . 'Total Sample Files: '
    . scalar @{ $videos->{'sample_list'} } . "\n";
    foreach my $sample ( @{ $videos->{'sample_list'} } ) {
        $total_size += $sample->{'size'};
    }
    print 'Total Sample Size: ' . _in_gigs($total_size) . " GB\n\n";
}

sub _print_eom {
    print "\t$!\n";
    print "--list|-l - Print the file list.\n";
    print
      "--sort_by_size|--size_sort|-ss - Print the file list sorted by size.\n";
    print "--find_duplicates|--dups - locate duplicate files.\n";
    print
"--trash_collect|--trash|-t - Find files considered junk like nfo, srr, or text files.\n";
    print
"--find_samples|--samples|-s - Find all sample files.  When used with --delete these duplicate files will be reaped.\n";
    print
"--remove|--rm|--del|--delete|--commit - Will act on built lists by removing the files within said list.\n";
    print
"--move|--relocate - Instead of removing files within the list MOVE them to a safe place.\n";
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

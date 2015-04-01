#!/usr/bin/perl

use strict;
use warnings;

use HTML::Tree;
use LWP::Simple;

my $indir = "/cygdrive/i/Videos/Shows/Broad City/";
$indir =~ s/ /\\ /g;
my $url = "http://en.wikipedia.org/wiki/List_of_Broad_City_episodes"; 
my $verbose = "";

sub choose_table {
    my ($tree) = @_;
    my $table;

    my @tables = $tree->look_down( _tag => "table" );
    print "Number of tables found: @tables\n" if $verbose;

    my $choice = "n";
    foreach my $t (@tables) {
        print "This table? (y/n)\n";
        my @kids = $t->content_list();
        print "\t" . $kids[0]->as_text() . "\n";
        print "\t" . $kids[1]->as_text() . "\n";
        chomp($choice = <>);
        if ($choice =~ /y/) {
            $table = $t;
            last;
        }
    }
    die "Error: No table chosen\n" unless $choice =~ /y/;

    return $table;
}

sub get_episode_list{
    my ($url) = @_;

    my $content = get($url);
    my @t = split(/\n/, $content);
    print "Test content:\n" . join ("\n", @t[0..5]) if $verbose;

    my $treeroot = HTML::Tree->new();
    my $success = $treeroot->parse($content);
    die "Unsuccessful parse\n" unless $success;

    my $table = choose_table($treeroot);

    my @episode_nodes = $table->look_down( class => 'summary' );
    my @episode_list = ();

    foreach my $node (@episode_nodes) {
        my $name = $node->as_HTML();
        $name =~ s/<td.*?>(.*?)<.*/$1/;
        $name =~ s/&.*?;//g ;
        $name =~ s/:/-/g ;
        $name =~ s/[\/\\\*\?<>"|]//g ;
        push(@episode_list, $name);
    }
    return @episode_list;
}

sub name_episodes {
    my ($indir, $url) = @_;

    my @elist = get_episode_list($url);
    my @mvlist = ();
    my $c = 0;

    my @episodes = split(/\n/, `ls $indir`);
    foreach my $episode (@episodes) {
        if ($episode =~ /()(\d\d\d).*(\.\w+)$/) {
            my $newname = "$1${2} - $elist[$c]$3";
            print $newname . "\n";
            $newname =~ s/ /\\ /g;
            $episode =~ s/ /\\ /g;
            push(@mvlist, "mv $indir/$episode $indir/$newname");
            $c++;
        }
    }
    my $choice;
    print "\nProceed with episode renaming? (y/n) ";
    chomp ($choice = <>);

    if ($choice =~ /y/) {
        foreach my $move (@mvlist) {
            system($move);
        }
    }

}

name_episodes($indir, $url);

#!/usr/bin/perl -w

# DETUtil
# DETUtil.pl
# Author: Jonathan Fiscus
# 
# This software was developed at the National Institute of Standards and Technology by
# employees of the Federal Government in the course of their official duties.  Pursuant to
# Title 17 Section 105 of the United States Code this software is not subject to copyright
# protection within the United States and is in the public domain. asclite is
# an experimental system.  NIST assumes no responsibility whatsoever for its use by any party.
# 
# THIS SOFTWARE IS PROVIDED "AS IS."  With regard to this software, NIST MAKES NO EXPRESS
# OR IMPLIED WARRANTY AS TO ANY MATTER WHATSOEVER, INCLUDING MERCHANTABILITY,
# OR FITNESS FOR A PARTICULAR PURPOSE.

use strict;
use Getopt::Long;
use Data::Dumper;

use lib qw(../../src);
use DETCurve;

Getopt::Long::Configure(qw( auto_abbrev no_ignore_case ));

my $VERSION = 0.1;

sub usage
{
    print "DETUtil.pl [ -t TMPDIR ] -o outputPNG [ searializedDET1, searializedDET2, ...]\n";
    print "\n";
    print "Required file arguments:\n";
    print "  -o, --output-png         Path to write the PNG to\n";
    print "Optional arguments:\n";
    print "  -t, --tmpdir             Path to write temporary files in.\n";
    print "\n";
}


my $OutPNGfile = "";
my $tmpDir = "/tmp";

GetOptions
(
    'output-png=s'                       => \$OutPNGfile,
    'tmpdir=s'                           => \$tmpDir,
    'version',                            => sub { print "STDListGenerator version: $VERSION\n"; exit },
    'help'                                => sub { usage (); exit },
);

die "ERROR: An Output file must be set." if($OutPNGfile eq "");

### make a temporary dirctory
my $temp = "$tmpDir/DET.$$";

my @dets = ();
foreach my $srl(@ARGV){
    push @dets, DETCurve::readFromFile($srl);
}

### Setup a cleanup signal
sub cleanup {
    system "rm -rf $temp";
}
$SIG{INT} = \&cleanup;

system "mkdir $temp";
DETCurve::writeMultiDetGraph("$temp/merge", \@dets);
system "cp $temp/merge.png $OutPNGfile";
cleanup();


# STDEval
# CacheOccurrences.pm
# Author: Jerome Ajot
# 
# This software was developed at the National Institute of Standards and Technology by
# employees of the Federal Government in the course of their official duties.  Pursuant to
# Title 17 Section 105 of the United States Code this software is not subject to copyright
# protection within the United States and is in the public domain. STDEval is
# an experimental system.  NIST assumes no responsibility whatsoever for its use by any party.
# 
# THIS SOFTWARE IS PROVIDED "AS IS."  With regard to this software, NIST MAKES NO EXPRESS
# OR IMPLIED WARRANTY AS TO ANY MATTER WHATSOEVER, INCLUDING MERCHANTABILITY,
# OR FITNESS FOR A PARTICULAR PURPOSE.

package CacheOccurrences;
use strict;
use STDTermRecord;
use TermListRecord;
use TermList;
use Data::Dumper;

sub new
{
    my $class = shift;
    my $self = {};

    $self->{FILENAME} = shift;
    $self->{SYSTEMVRTTM} = shift;
    $self->{THRESHOLD} = shift;
    $self->{REFLIST} = shift;
	
    bless $self;    
    return $self;
}

sub saveFile
{
    my ($self, $termlist) = @_;
        
    open(CACHE_FILE, ">$self->{FILENAME}") or die "cannot open cache file '$self->{FILENAME}'";

    print CACHE_FILE "<rttm_cache_file system_V=\"$self->{SYSTEMVRTTM}\" find_threshold=\"$self->{THRESHOLD}\">\n";
    
    foreach my $terms(keys %{ $self->{REFLIST} })
    {
        print CACHE_FILE "    <term termid=\"$termlist->{REVERSE}{$terms}\"><termtext>$terms<termtext>\n";
        
        if($self->{REFLIST}{$terms})
        {
            for(my $i=0; $i<@{ $self->{REFLIST}{$terms} }; $i++)
            {
                print CACHE_FILE "        <occurrence file=\"$self->{REFLIST}{$terms}[$i]->{FILE}\" channel=\"$self->{REFLIST}{$terms}[$i]->{CHAN}\" begt=\"$self->{REFLIST}{$terms}[$i]->{BT}\" dur=\"$self->{REFLIST}{$terms}[$i]->{DUR}\"/>\n";
            }
        }
        
        print CACHE_FILE "    </term>\n";
    }
    
    print CACHE_FILE "</rttm_cache_file>\n";
    
    close(CACHE_FILE);
}

sub loadFile
{
    my ($self, $terms) = @_;
    my $cachefilestring = "";
     
    open(CACHE_FILE, "<$self->{FILENAME}") or die "cannot open cache file '$self->{FILENAME}'";
    
    while (<CACHE_FILE>)
    {
        chomp;
        $cachefilestring .= $_;
    }
    
    close(CACHE_FILE);
    
    #clean unwanted spaces
    $cachefilestring =~ s/\s+/ /g;
    $cachefilestring =~ s/> </></g;
    $cachefilestring =~ s/^\s*//;
    $cachefilestring =~ s/\s*$//;
    
    my $cachelisttag;
    my $termlist;

    if($cachefilestring =~ /(<rttm_cache_file .*?[^>]*>)([[^<]*<.*[^>]*>]*)<\/rttm_cache_file>/)
    {
        $cachelisttag = $1;
        $termlist = $2;
    }
    else
    {
        die "Invalid Cache file";
    }
    
    if($cachelisttag =~ /system_V="(.*?[^"]*)"/)
    {
       $self->{SYSTEMVRTTM} = $1;
    }
    else
    {
        die "Cache: 'system_V' option is missing in rttm_cache_file tag";
    }
    
    if($cachelisttag =~ /find_threshold="(.*?[^"]*)"/)
    {
       $self->{THRESHOLD} = $1;
    }
    else
    {
        die "Cache: 'find_threshold' option is missing in rttm_cache_file tag";
    }
    
    while( $termlist =~ /(<term (.*?[^>]*)><termtext>.*?<termtext>(.*?)<\/term>)/ )
    {
        my $allterm = $1;
        my $texttag = $2;
        my $occurrences = $3;
        
        my $text;
        
        if($texttag =~ /termid="(.*?[^"]*)"/)
        {
            $text = $terms->{TERMS}{$1}->{TEXT};
        }
        else
        {
            die "Cache: 'text' option is missing in term tag";
        }
                
        while( $occurrences =~ /(<occurrence (.*?[^>]*)\/>)/ )
        {
            my $alloccur = $1;
            my $alloptions = $2;
            
            my $file;
            my $channel;
            my $begt;
            my $dur;
            
            if($alloptions =~ /file="(.*?[^"]*)"/)
            {
                $file = $1;
            }
            else
            {
                die "Cache: 'file' option is missing in occurrence tag";
            }
            
            if($alloptions =~ /channel="(.*?[^"]*)"/)
            {
                $channel = $1;
            }
            else
            {
                die "Cache: 'channel' option is missing in occurrence tag";
            }
            
            if($alloptions =~ /begt="(.*?[^"]*)"/)
            {
                $begt = $1;
            }
            else
            {
                die "Cache: 'begt' option is missing in occurrence tag";
            }
            
            if($alloptions =~ /dur="(.*?[^"]*)"/)
            {
                $dur = $1;
            }
            else
            {
                die "Cache: 'dur' option is missing in occurrence tag";
            }
            
            push( @{ $self->{REFLIST}{$text} }, new STDTermRecord($file, $channel, $begt, $dur, undef, undef));
                        
            $occurrences =~ s/$alloccur//;
        }
                
        $termlist =~ s/$allterm//;
    }
    
    close(CACHE_FILE);
}

1;

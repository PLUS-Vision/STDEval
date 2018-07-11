# STDEval
# STDAlignment.pm
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

package STDAlignment;

use strict;
use MappedRecord;
use DETCurve;
use STDDETSet;
use Trials;
use MinMax;
require File::Spec;
use Encode;
use encoding 'euc-cn';
use encoding 'utf8';

use Data::Dumper;

sub new
{
    my $class = shift;
    my $self = {};

    $self->{STD} = shift;
    $self->{TERM} = shift;
    $self->{ECF} = shift;
    $self->{MAPPINGS} = shift;
    $self->{C} = shift;
    $self->{V} = shift;
    
    bless $self;
    return $self;
}

sub unitTest
{
    print "Test STDAlignment\n";
      
    print " Filter array empty...     ";
    
    my @array = ();
    my $term = "test-01";
    
    if( EltInList(\@array, $term) )
    {
        print "OK\n";
    }
    else
    {
        print "FAILED!\n";
        return 0;
    }
    
    print " Filter array match...     ";
    
    @array = ("test-03", "test-00", "test-01", "test-10");
    $term = "test-01";
    
    if( EltInList(\@array, $term) )
    {
        print "OK\n";
    }
    else
    {
        print "FAILED!\n";
        return 0;
    }
    
    print " Filter array not-match... ";
    
    @array = ("test-03", "test-00", "test-01", "test-10");
    $term = "test-11";
    
    if( !EltInList(\@array, $term) )
    {
        print "OK\n";
    }
    else
    {
        print "FAILED!\n";
        return 0;
    }
    
    return 1;
}

sub transcriptCheckReport
{
    my ($self, $output, $thresh) = @_;
    
    open(OUTPUT, ($output ne "") ? ">$output" : ">&STDOUT") or die "cannot open '$output'";
    
    my $high_corr = 0;
    my $high_famiss = 0;
    my $low_corr = 0;
    my $low_famiss = 0;
    my $noscore_miss = 0;
    my $low_dropped = 0;
    my $high_dropped = 0;
    my $med_dropped = 0;
    my $med_corr = 0;
    my $med_famiss = 0;
    
    my $minscore = $self->{STD}->{MIN_SCORE};
    my $maxscore = $self->{STD}->{MAX_SCORE};
    
    my $lowthresh = $self->{STD}->{MIN_SCORE} + ($self->{STD}->{MAX_SCORE} - $self->{STD}->{MIN_SCORE}) * $thresh;
    my $highthresh = $self->{STD}->{MIN_SCORE} + ($self->{STD}->{MAX_SCORE} - $self->{STD}->{MIN_SCORE}) * (1.0 - $thresh);
    
    my $mindecisionscore_yes = 9999.0;
    my $maxdecisionscore_no = -1.0;
    
    foreach my $termid(sort keys %{ $self->{MAPPINGS} } )
    {
        for(my $i=0; $i<@{ $self->{MAPPINGS}->{$termid}{MAPPED} }; $i++)
        {
            if($self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{DECISION} eq "YES")
            {
                $mindecisionscore_yes = $self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{SCORE} if($self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{SCORE} < $mindecisionscore_yes);
                
                if($self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{SCORE} < $lowthresh)
                {
                    $low_corr++;
                }
                elsif( ($self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{SCORE} > $lowthresh) && ($self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{SCORE} < $highthresh) )
                {
                    $med_corr++;
                }
                else
                {
                    $high_corr++;
                }
            }
            else
            {
                $maxdecisionscore_no = $self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{SCORE} if($self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{SCORE} > $maxdecisionscore_no);
                
                if($self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{SCORE} < $lowthresh)
                {
                    $low_famiss++;
                }
                elsif( ($self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{SCORE} > $lowthresh) && ($self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{SCORE} < $highthresh) )
                {
                    $med_famiss++;
                }
                else
                {
                    $high_famiss++;
                }
            }
        }
            
        for(my $i=0; $i<@{ $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS} }; $i++)
        {
            if($self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{DECISION} eq "YES")
            {
                $mindecisionscore_yes = $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{SCORE} if($self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{SCORE} < $mindecisionscore_yes);
                
                if($self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{SCORE} < $lowthresh)
                {
                    $low_famiss++;
                }
                elsif( ($self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{SCORE} > $lowthresh) && ($self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{SCORE} < $highthresh) )
                {
                    $med_famiss++;
                }
                else
                {
                    $high_famiss++;
                }
            }
            else
            {
                $maxdecisionscore_no = $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{SCORE} if($self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{SCORE} > $maxdecisionscore_no);
                
                if($self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{SCORE} < $lowthresh)
                {
                    $low_dropped++;
                }
                elsif( ($self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{SCORE} > $lowthresh) && ($self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{SCORE} < $highthresh) )
                {
                    $med_dropped++;
                }
                else
                {
                    $high_dropped++;
                }
            }
        }
            
        for(my $i=0; $i<@{ $self->{MAPPINGS}->{$termid}{UNMAPPED_REF} }; $i++)
        {
            $noscore_miss++;
        }
    }
    
    my $display_high_corr = sprintf("%5d", $high_corr);
    my $display_high_famiss = sprintf("%5d", $high_famiss);
    my $display_high_dropped = sprintf("%5d", $high_dropped);
    my $display_low_corr = sprintf("%5d", $low_corr);
    my $display_low_famiss = sprintf("%5d", $low_famiss);
    my $display_low_dropped = sprintf("%5d", $low_dropped);
    my $display_med_corr = sprintf("%5d", $med_corr);
    my $display_med_famiss = sprintf("%5d", $med_famiss);
    my $display_med_dropped = sprintf("%5d", $med_dropped);
    
    print OUTPUT "Threshold: $thresh\n";
    print OUTPUT "[ $minscore <lo> $lowthresh <med> $highthresh <hi> $maxscore ]\n";
    print OUTPUT "+------+---------+---------+---------+\n";
    print OUTPUT "|      |   Corr  | FA-Miss | Dropped |\n";
    print OUTPUT "+------+---------+---------+---------+\n";
    print OUTPUT "| High |  $display_high_corr  |  $display_high_famiss  |  $display_high_dropped  |\n";
    print OUTPUT "+------+---------+---------+---------+\n";
    print OUTPUT "| Med  |  $display_med_corr  |  $display_med_famiss  |  $display_med_dropped  |\n";
    print OUTPUT "+------+---------+---------+---------+\n";
    print OUTPUT "| Low  |  $display_low_corr  |  $display_low_famiss  |  $display_low_dropped  |\n";
    print OUTPUT "+------+---------+---------+---------+\n";
    print OUTPUT "Unrefed Miss: $noscore_miss\n";
    print OUTPUT "Min Score YES: $mindecisionscore_yes\n";
    $maxdecisionscore_no = "N/A" if($maxdecisionscore_no == -1);
    print OUTPUT "Max Score NO:  $maxdecisionscore_no\n";
    
    close OUTPUT;
}

sub csvReport
{
    my ($self, $output) = @_;
    
    if($output ne "")
    {
        open(OUTPUT, ($self->{STD}->{LANGUAGE} eq "mandarin") ? ">:encoding(gb2312)" : ">:encoding(utf8)", $output) or die "cannot open '$output'";
    }
    else
    {
        open(OUTPUT, ">&STDOUT") or die "cannot display in STDOUT";
    }
    
    print OUTPUT "type,language,file,channel,termid,term,ref_bt,ref_et,sys_bt,sys_et,sys_score,sys_decision,alignment\n";
    
    my %filechantype;
    my $language = $self->{TERM}->{LANGUAGE};
    
    for (my $i=0; $i<@{ $self->{ECF}->{EXCERPT} }; $i++)
    {
       $filechantype{$self->{ECF}->{EXCERPT}[$i]->{FILE}}{$self->{ECF}->{EXCERPT}[$i]->{CHANNEL}} = $self->{ECF}->{EXCERPT}[$i]->{SOURCE_TYPE};
    }
    
    foreach my $termid(sort keys %{ $self->{MAPPINGS} } )
    {
        my $term = $self->{TERM}->{TERMS}{$termid}->{TEXT};
        $term = decode("gb2312", $self->{TERM}->{TERMS}{$termid}->{TEXT}) if($self->{STD}->{LANGUAGE} eq "mandarin");
        $term = decode("utf8", $self->{TERM}->{TERMS}{$termid}->{TEXT}) if($self->{STD}->{LANGUAGE} eq "arabic");
        my $status = "CORR";
        
        for(my $i=0; $i<@{ $self->{MAPPINGS}->{$termid}{MAPPED} }; $i++)
        {
            my $file = $self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{FILE};
            my $channel = $self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{CHAN};
            my $type =  $filechantype{$file}{$channel};
                            
            my $ref_bt = $self->{MAPPINGS}->{$termid}{MAPPED}[$i][1]->{BT};
            my $ref_et = $self->{MAPPINGS}->{$termid}{MAPPED}[$i][1]->{ET};
            
            my $sys_bt = $self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{BT};
            my $sys_et = $self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{ET};
            my $sys_score = $self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{SCORE};
            my $sys_decision = $self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{DECISION};
            
            print OUTPUT "$type,$language,$file,$channel,$termid,$term,$ref_bt,$ref_et,$sys_bt,$sys_et,$sys_score,$sys_decision,$status\n";
        }

        $status = "FA";
        
        for(my $i=0; $i<@{ $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS} }; $i++)
        {
            my $file = $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{FILE};
            my $channel = $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{CHAN};
            my $type =  $filechantype{$file}{$channel};
            
            my $sys_bt = $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{BT};
            my $sys_et = $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{ET};
            my $sys_score = $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{SCORE};
            my $sys_decision = $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{DECISION};
            
            print OUTPUT "$type,$language,$file,$channel,$termid,$term,,,$sys_bt,$sys_et,$sys_score,$sys_decision,$status\n";
        }
        
        $status = "MISS";
        
        for(my $i=0; $i<@{ $self->{MAPPINGS}->{$termid}{UNMAPPED_REF} }; $i++)
        {
            my $file = $self->{MAPPINGS}->{$termid}{UNMAPPED_REF}[$i]->{FILE};
            my $channel = $self->{MAPPINGS}->{$termid}{UNMAPPED_REF}[$i]->{CHAN};
            my $type =  $filechantype{$file}{$channel};
                            
            my $ref_bt = $self->{MAPPINGS}->{$termid}{UNMAPPED_REF}[$i]->{BT};
            my $ref_et = $self->{MAPPINGS}->{$termid}{UNMAPPED_REF}[$i]->{ET};
            
            print OUTPUT "$type,$language,$file,$channel,$termid,$term,$ref_bt,$ref_et,,,,,$status\n";
        }
    }
    
    close OUTPUT;
}

sub ReportAlign
{
    my ($self, $output) = @_;
    my %termfilechanmap;
    
    if($output ne "")
    {
        open(OUTPUT_LOCAL, ($self->{STD}->{LANGUAGE} eq "mandarin") ? ">:encoding(gb2312)" : ">:encoding(utf8)", $output) or die "cannot open '$output'";
    }
    else
    {
        open(OUTPUT_LOCAL, ">&STDOUT") or die "cannot display in STDOUT";
    }
    
    print "Writing alignment report to $output\n" if ($output ne "");
    
    foreach my $termid(sort keys %{ $self->{MAPPINGS} } )
    {
        for(my $i=0; $i<@{ $self->{MAPPINGS}->{$termid}{MAPPED} }; $i++)
        {
            my $chan = $self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{CHAN};
            my $file = $self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{FILE};
                            
            my ($RefBT, $RefET);
            my ($SysBT, $SysET, $SysScore, $SysDecision);
            
            $RefBT = $self->{MAPPINGS}->{$termid}{MAPPED}[$i][1]->{BT};
            $RefET = $self->{MAPPINGS}->{$termid}{MAPPED}[$i][1]->{ET};
            
            $SysBT = $self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{BT};
            $SysET = $self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{ET};
            $SysScore = $self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{SCORE};
            $SysDecision = $self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{DECISION};
            
            push( @{ $termfilechanmap{$termid}{$file}{$chan} }, [ ($RefBT, $RefET, $SysBT, $SysET, $SysScore, $SysDecision) ]);
        }
        
        for(my $i=0; $i<@{ $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS} }; $i++)
        {
            my $chan = $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{CHAN};
            my $file = $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{FILE};
                            
            my ($SysBT, $SysET, $SysScore, $SysDecision);
            
            $SysBT = $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{BT};
            $SysET = $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{ET};
            $SysScore = $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{SCORE};
            $SysDecision = $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{DECISION};
            
            push( @{ $termfilechanmap{$termid}{$file}{$chan} }, [ ("", "", $SysBT, $SysET, $SysScore, $SysDecision) ]);
        }

        for(my $i=0; $i<@{ $self->{MAPPINGS}->{$termid}{UNMAPPED_REF} }; $i++)
        {
            my $chan = $self->{MAPPINGS}->{$termid}{UNMAPPED_REF}[$i]->{CHAN};
            my $file = $self->{MAPPINGS}->{$termid}{UNMAPPED_REF}[$i]->{FILE};
                            
            my ($RefBT, $RefET);
            
            $RefBT = $self->{MAPPINGS}->{$termid}{UNMAPPED_REF}[$i]->{BT};
            $RefET = $self->{MAPPINGS}->{$termid}{UNMAPPED_REF}[$i]->{ET};
            
            push( @{ $termfilechanmap{$termid}{$file}{$chan} }, [ ($RefBT, $RefET, "", "", "", "") ]);
        }
    }

    foreach my $termid(sort keys %termfilechanmap )
    {
        my $termtext = $self->{TERM}->{TERMS}{$termid}->{TEXT};
        $termtext = decode("gb2312", $self->{TERM}->{TERMS}{$termid}->{TEXT}) if($self->{STD}->{LANGUAGE} eq "mandarin");
        $termtext = decode("utf8", $self->{TERM}->{TERMS}{$termid}->{TEXT}) if($self->{STD}->{LANGUAGE} eq "arabic");
        
        print OUTPUT_LOCAL "TERM: $termtext\n";
        
        foreach my $file(sort keys %{ $termfilechanmap{$termid} } )
        {
            print OUTPUT_LOCAL "    FILE: $file\n";
            
            foreach my $chan(sort keys %{ $termfilechanmap{$termid}{$file} } )
            {
                print OUTPUT_LOCAL "        CHANNEL: $chan\n";
                print OUTPUT_LOCAL "        +-----------------------+------------------------------------------+\n";
                print OUTPUT_LOCAL "        |          Ref          |                    Sys                   |\n";
                print OUTPUT_LOCAL "        |        BT         ET  |        BT         ET      Score     Dec. |\n";
                print OUTPUT_LOCAL "        +-----------------------+------------------------------------------+\n";
                                 
                my %hashcouple;
                
                for(my $i=0; $i<@{ $termfilechanmap{$termid}{$file}{$chan} }; $i++)
                {
                    my ($RefBT, $RefET, $SysBT, $SysET, $SysScore, $SysDecision);
                    
                    if($termfilechanmap{$termid}{$file}{$chan}[$i][0] ne "")
                    {
                        $RefBT = sprintf("%10s", $termfilechanmap{$termid}{$file}{$chan}[$i][0]);
                        $RefET = sprintf("%10s", $termfilechanmap{$termid}{$file}{$chan}[$i][1]);
                    }
                    else
                    {                        
                        $RefBT = sprintf("%10s", "-- ");
                        $RefET = sprintf("%10s", "-- ");
                    }
                    
                    if($termfilechanmap{$termid}{$file}{$chan}[$i][2] ne "")
                    {
                        $SysBT = sprintf("%10s", $termfilechanmap{$termid}{$file}{$chan}[$i][2]);
                        $SysET = sprintf("%10s", $termfilechanmap{$termid}{$file}{$chan}[$i][3]);
                        $SysScore = sprintf("%10s", $termfilechanmap{$termid}{$file}{$chan}[$i][4]);
                        $SysDecision = sprintf("%6s", $termfilechanmap{$termid}{$file}{$chan}[$i][5]);
                    }
                    else
                    {
                        $SysBT = sprintf("%10s", "-- ");
                        $SysET = sprintf("%10s", "-- ");
                        $SysScore = sprintf("%10s", "-- ");
                        $SysDecision = sprintf("%6s", "-- ");
                    }
                    
                    if($termfilechanmap{$termid}{$file}{$chan}[$i][0] ne "")
                    {
                        push( @{ $hashcouple{$RefBT} }, ($RefBT, $RefET, $SysBT, $SysET, $SysScore, $SysDecision));
                    }
                    else
                    {
                        push( @{ $hashcouple{$SysBT} }, ($RefBT, $RefET, $SysBT, $SysET, $SysScore, $SysDecision));
                    }
                }
                
                my @sorttime = sort keys %hashcouple;
                
                for(my $i=0; $i<@sorttime; $i++)
                {                        
                    print OUTPUT_LOCAL "        | $hashcouple{$sorttime[$i]}[0] $hashcouple{$sorttime[$i]}[1] | $hashcouple{$sorttime[$i]}[2] $hashcouple{$sorttime[$i]}[3] $hashcouple{$sorttime[$i]}[4] $hashcouple{$sorttime[$i]}[5]  |\n";
                }
                
                print OUTPUT_LOCAL "        +-----------------------+------------------------------------------+\n";
            }
        }
        
        print OUTPUT_LOCAL "\n";
    }
    
    close(OUTPUT_LOCAL);
}

sub GenerateOccurrenceReport
{
    my ($self, $filter_termsIDs, $filter_filechannels, $filter_types, $trialsPerSecond, $probOfTerm, $KoefV, $KoefC) = @_;
    my %stats;
    my %filechantype;
    
    $stats{COEFF}{KOEFC} = $KoefC;
    $stats{COEFF}{KOEFV} = $KoefV;
    $stats{COEFF}{PROBOFTERM} = $probOfTerm;
    $stats{COEFF}{TRIALSPERSEC} = $trialsPerSecond;

    for (my $i=0; $i<@{ $self->{ECF}->{EXCERPT} }; $i++)
    {
        $filechantype{$self->{ECF}->{EXCERPT}[$i]->{FILE}}{$self->{ECF}->{EXCERPT}[$i]->{CHANNEL}} = uc($self->{ECF}->{EXCERPT}[$i]->{SOURCE_TYPE});
    }
    
    foreach my $level("TOTAL","MEAN")
    {
        foreach my $type("BNEWS", "CTS", "CONFMTG", "ALL")
        {
            foreach my $align("REF","CORR","FA","MISS","VALUE","NBR_TERMS", "PMISS", "PFA", "TERMWEIGHTEDVALUE", "NUMTRIALS", "TOTALTIME")
            {
                $stats{$level}{$type}{$align} = 0;
            }
        }
        
        $stats{$level}{SEARCH_TIME} = 0;
    }
        
    foreach my $termid(sort keys %{ $self->{MAPPINGS} } )
    {
        next if(!EltInList($filter_termsIDs, $termid));
        
        $stats{MEAN}{ALL}{NBR_TERMS} += 1;
        $stats{$termid}{TEXT} = $self->{TERM}->{TERMS}{$termid}->{TEXT};
        $stats{$termid}{SEARCH_TIME} = $self->{STD}->{TERMS}{$termid}->{SEARCH_TIME};
        $stats{TOTAL}{SEARCH_TIME} += $self->{STD}->{TERMS}{$termid}->{SEARCH_TIME};
        $stats{MEAN}{SEARCH_TIME} += $self->{STD}->{TERMS}{$termid}->{SEARCH_TIME};
            
        foreach my $type("BNEWS", "CTS", "CONFMTG", "ALL")
        {
            foreach my $align("REF","CORR","FA","MISS","VALUE")
            {
                $stats{$termid}{$type}{$align} = 0 if(!$stats{$termid}{$type}{$align});
            }	   
             
            ### Set the number of trials per source type
            $stats{$termid}{$type}{TOTALTIME} = 0 if (!$stats{$termid}{$type}{TOTALTIME});
	    
            for (my $i=0; $i<@{ $self->{ECF}->{EXCERPT} }; $i++)
            {		
                next if ($self->{ECF}->{EXCERPT}[$i]->{CHANNEL} != 1);
            
                my $excerptType = $filechantype{$self->{ECF}->{EXCERPT}[$i]->{FILE}}{$self->{ECF}->{EXCERPT}[$i]->{CHANNEL}};

                if ($type eq "ALL" || $type eq $excerptType)
                { 		    
                    if (( (@$filter_types > 0) && (EltInList($filter_types, $type))) ||
                        ( (@$filter_types > 0) && ($type eq "ALL" && EltInList($filter_types, $excerptType))) ||
                        ( (@$filter_types <= 0) ))
                    {
                        $stats{$termid}{$type}{TOTALTIME} += $self->{ECF}->{EXCERPT}[$i]->{DUR};
                    }
                }
            }
	    
            ### Round it the a whole number
            $stats{$termid}{$type}{NUMTRIALS} = sprintf("%.0f",$trialsPerSecond * $stats{$termid}{$type}{TOTALTIME});
            
            if ($stats{TOTAL}{$type}{NUMTRIALS} == 0)
            {
                $stats{TOTAL}{$type}{NUMTRIALS} = $stats{$termid}{$type}{NUMTRIALS};
                $stats{TOTAL}{$type}{TOTALTIME} = $stats{$termid}{$type}{TOTALTIME};
            }
            elsif ($stats{TOTAL}{$type}{NUMTRIALS} != $stats{$termid}{$type}{NUMTRIALS})
            {
                die "Error: Internal error calculating the total number of trials";
            }
        }
                        
        for(my $i=0; $i<@{ $self->{MAPPINGS}->{$termid}{MAPPED} }; $i++)
        {
            my $file = $self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{FILE};
            my $channel = $self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{CHAN};
            
            next if(!PairInList($filter_filechannels, $file, $channel));
            
            my $type = $filechantype{$file}{$channel};
            
            next if(!EltInList($filter_types, $type));
            
            $stats{$termid}{$type}{REF} += 1;
            $stats{TOTAL}{$type}{REF} += 1;
            $stats{$termid}{ALL}{REF} += 1;
            $stats{TOTAL}{ALL}{REF} += 1;
            
            if($self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{DECISION} eq "YES")
            {
                $stats{$termid}{$type}{CORR} += 1;
                $stats{TOTAL}{$type}{CORR} += 1;
                $stats{$termid}{ALL}{CORR} += 1;
                $stats{TOTAL}{ALL}{CORR} += 1;
            }
            else
            {
                $stats{$termid}{$type}{MISS} += 1;
                $stats{TOTAL}{$type}{MISS} += 1;
                $stats{$termid}{ALL}{MISS} += 1;
                $stats{TOTAL}{ALL}{MISS} += 1;
            }
        }
            
        for(my $i=0; $i<@{ $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS} }; $i++)
        {
            my $file = $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{FILE};
            my $channel = $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{CHAN};
            
            next if(!PairInList($filter_filechannels, $file, $channel));
            
            my $type = $filechantype{$file}{$channel};
            
            next if(!EltInList($filter_types, $type));
            
            if($self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{DECISION} eq "YES")
            {
                $stats{$termid}{$type}{FA} += 1;
                $stats{TOTAL}{$type}{FA} += 1;
                $stats{$termid}{ALL}{FA} += 1;
                $stats{TOTAL}{ALL}{FA} += 1;
            }
        }
            
        for(my $i=0; $i<@{ $self->{MAPPINGS}->{$termid}{UNMAPPED_REF} }; $i++)
        {
            my $file = $self->{MAPPINGS}->{$termid}{UNMAPPED_REF}[$i]->{FILE};
            my $channel = $self->{MAPPINGS}->{$termid}{UNMAPPED_REF}[$i]->{CHAN};
            
            next if(!PairInList($filter_filechannels, $file, $channel));
            
            my $type = $filechantype{$file}{$channel};
            
            next if(!EltInList($filter_types, $type));
            
            $stats{$termid}{$type}{REF} += 1;
            $stats{$termid}{$type}{MISS} += 1;
            $stats{TOTAL}{$type}{REF} += 1;
            $stats{TOTAL}{$type}{MISS} += 1;
            $stats{$termid}{ALL}{REF} += 1;
            $stats{$termid}{ALL}{MISS} += 1;
            $stats{TOTAL}{ALL}{REF} += 1;
            $stats{TOTAL}{ALL}{MISS} += 1;
        }

        foreach my $type("BNEWS", "CTS", "CONFMTG", "ALL")
        {
            if($stats{$termid}{$type}{REF} != 0)
            {
                $stats{$termid}{$type}{VALUE} = ($self->{V}*$stats{$termid}{$type}{CORR} - $self->{C}*$stats{$termid}{$type}{FA})/($self->{V}*$stats{$termid}{$type}{REF});
                $stats{$termid}{$type}{PMISS} = 1 - ($stats{$termid}{$type}{CORR} / $stats{$termid}{$type}{REF});
                $stats{$termid}{$type}{PFA} =   $stats{$termid}{$type}{FA} / ($stats{$termid}{$type}{NUMTRIALS} - $stats{$termid}{$type}{REF});
            }
            else
            {
                $stats{$termid}{$type}{VALUE} = -1000.0;
                $stats{$termid}{$type}{PMISS} = -1000.0;
                $stats{$termid}{$type}{PFA} = -1000.0;
            }
            
            if($stats{$termid}{$type}{REF} != 0)
            {
                $stats{TOTAL}{$type}{NBR_TERMS} += 1;
                $stats{MEAN}{$type}{REF} += $stats{$termid}{$type}{REF};
                $stats{MEAN}{$type}{CORR} += $stats{$termid}{$type}{CORR};
                $stats{MEAN}{$type}{FA} += $stats{$termid}{$type}{FA};
                $stats{MEAN}{$type}{MISS} += $stats{$termid}{$type}{MISS};
                $stats{MEAN}{$type}{VALUE} += $stats{$termid}{$type}{VALUE};
                $stats{MEAN}{$type}{PMISS} += $stats{$termid}{$type}{PMISS};
                $stats{MEAN}{$type}{PFA} += $stats{$termid}{$type}{PFA};
                $stats{MEAN}{$type}{TERMWEIGHTEDVALUE} += 1 - ($stats{$termid}{$type}{PMISS} + ($self->{C} / $self->{V} * ((1 / $probOfTerm) - 1) * $stats{$termid}{$type}{PFA} ));
            }
        }
    }
    
    foreach my $type("BNEWS", "CTS", "CONFMTG", "ALL")
    {
        if(($self->{V}*$stats{TOTAL}{$type}{REF}) != 0)
        {
            $stats{TOTAL}{$type}{VALUE} = sprintf("%.4f", ($self->{V}*$stats{TOTAL}{$type}{CORR} - $self->{C}*$stats{TOTAL}{$type}{FA})/($self->{V}*$stats{TOTAL}{$type}{REF}) );
            $stats{TOTAL}{$type}{PMISS} = sprintf("%.4f", 1 - ($stats{TOTAL}{$type}{CORR} / $stats{TOTAL}{$type}{REF}));
	        $stats{TOTAL}{$type}{PFA} = sprintf("%.8f", $stats{TOTAL}{$type}{FA} / ($stats{TOTAL}{$type}{NUMTRIALS} - $stats{TOTAL}{$type}{REF}));
        }
        else
        {
            $stats{TOTAL}{$type}{VALUE} = -1000.0;
            $stats{TOTAL}{$type}{PMISS} = -1000.0;
	        $stats{TOTAL}{$type}{PFA} = -1000.0;
        }
        
        foreach my $align("REF","CORR","FA","MISS","VALUE", "PMISS", "PFA", "TERMWEIGHTEDVALUE")
        {
            if($stats{TOTAL}{$type}{NBR_TERMS} != 0)
            {
                $stats{MEAN}{$type}{$align} = $stats{MEAN}{$type}{$align}/$stats{TOTAL}{$type}{NBR_TERMS};
            }
            else
            {
                $stats{MEAN}{$type}{$align} = -1000.0 if($align eq "VALUE");
            }
	}
    }
    
    if($stats{TOTAL}{ALL}{NBR_TERMS} != 0)
    {
        $stats{MEAN}{SEARCH_TIME} = $stats{MEAN}{SEARCH_TIME}/$stats{MEAN}{ALL}{NBR_TERMS};
    }
    else
    {
        $stats{MEAN}{SEARCH_TIME} = -1000.0;
    }    
    return(\%stats);
}

sub CopyConditionalOccurrenceReports
{
    my ($self, $hash_stats) = @_;
    my %allstats;
    
    my @all_TermSet = sort keys %{ $hash_stats };
    my @all_SourcetypeSet = sort keys %{ $hash_stats->{$all_TermSet[0]} };
    
    foreach my $level("TOTAL","MEAN")
    {
        foreach my $SourcetypeSet(@all_SourcetypeSet)
        {
            foreach my $Component("REF","CORR","FA","MISS","VALUE","PFA","PMISS","NBR_TERMS","NUMTRIALS","TOTALTIME","TERMWEIGHTEDVALUE")
            {
                $allstats{$level}{$SourcetypeSet}{$Component} = 0;
            }
        }
        
        foreach my $Component("REF","CORR","FA","MISS","VALUE","PFA","PMISS","NBR_TERMS","NUMTRIALS","TOTALTIME","TERMWEIGHTEDVALUE")
        {
            $allstats{$level}{ALL}{$Component} = 0;
        }
        
        $allstats{$level}{SEARCH_TIME} = 0;
    }
    
    $allstats{COEFF}{KOEFC} = $hash_stats->{$all_TermSet[0]}{$all_SourcetypeSet[0]}->{COEFF}{KOEFC};
    $allstats{COEFF}{KOEFV} = $hash_stats->{$all_TermSet[0]}{$all_SourcetypeSet[0]}->{COEFF}{KOEFV};
    $allstats{COEFF}{PROBOFTERM} = $hash_stats->{$all_TermSet[0]}{$all_SourcetypeSet[0]}->{COEFF}{PROBOFTERM};
    $allstats{COEFF}{TRIALSPERSEC} = $hash_stats->{$all_TermSet[0]}{$all_SourcetypeSet[0]}->{COEFF}{TRIALSPERSEC};
    
    foreach my $TermSet(@all_TermSet)
    {
        $allstats{MEAN}{ALL}{NBR_TERMS} += 1;
        
        foreach my $SourcetypeSet(@all_SourcetypeSet)
        {
            $allstats{TOTAL}{SEARCH_TIME} += $hash_stats->{$TermSet}{$SourcetypeSet}->{TOTAL}{SEARCH_TIME};
            $allstats{$TermSet}{SEARCH_TIME} += $hash_stats->{$TermSet}{$SourcetypeSet}->{TOTAL}{SEARCH_TIME};
            $allstats{MEAN}{SEARCH_TIME} += $hash_stats->{$TermSet}{$SourcetypeSet}->{TOTAL}{SEARCH_TIME};
            
            $allstats{$TermSet}{$SourcetypeSet}{TERMWEIGHTEDVALUE} = $hash_stats->{$TermSet}{$SourcetypeSet}->{MEAN}{ALL}{TERMWEIGHTEDVALUE};
            $allstats{MEAN}{$SourcetypeSet}{TERMWEIGHTEDVALUE} += $hash_stats->{$TermSet}{$SourcetypeSet}->{MEAN}{ALL}{TERMWEIGHTEDVALUE};
            $allstats{$TermSet}{ALL}{TERMWEIGHTEDVALUE} += $hash_stats->{$TermSet}{$SourcetypeSet}->{MEAN}{ALL}{TERMWEIGHTEDVALUE};
            $allstats{MEAN}{ALL}{TERMWEIGHTEDVALUE} += $hash_stats->{$TermSet}{$SourcetypeSet}->{MEAN}{ALL}{TERMWEIGHTEDVALUE};
            
            foreach my $Component("REF","CORR","FA","MISS","PFA","PMISS","NUMTRIALS","TOTALTIME")
            {
                $allstats{$TermSet}{$SourcetypeSet}{$Component} = $hash_stats->{$TermSet}{$SourcetypeSet}->{TOTAL}{ALL}{$Component};
                $allstats{TOTAL}{$SourcetypeSet}{$Component} += $hash_stats->{$TermSet}{$SourcetypeSet}->{TOTAL}{ALL}{$Component};
                $allstats{$TermSet}{ALL}{$Component} += $hash_stats->{$TermSet}{$SourcetypeSet}->{TOTAL}{ALL}{$Component};
                $allstats{TOTAL}{ALL}{$Component} += $hash_stats->{$TermSet}{$SourcetypeSet}->{TOTAL}{ALL}{$Component};
            }
            
            if($allstats{$TermSet}{$SourcetypeSet}{REF} != 0)
            {
                $allstats{$TermSet}{$SourcetypeSet}{VALUE} = sprintf("%.3f", ($self->{V}*$allstats{$TermSet}{$SourcetypeSet}{CORR} - $self->{C}*$allstats{$TermSet}{$SourcetypeSet}{FA})/($self->{V}*$allstats{$TermSet}{$SourcetypeSet}{REF}) );
                $allstats{TOTAL}{$SourcetypeSet}{NBR_TERMS} += 1;
                $allstats{MEAN}{$SourcetypeSet}{REF} += $allstats{$TermSet}{$SourcetypeSet}{REF};
                $allstats{MEAN}{$SourcetypeSet}{CORR} += $allstats{$TermSet}{$SourcetypeSet}{CORR};
                $allstats{MEAN}{$SourcetypeSet}{FA} += $allstats{$TermSet}{$SourcetypeSet}{FA};
                $allstats{MEAN}{$SourcetypeSet}{MISS} += $allstats{$TermSet}{$SourcetypeSet}{MISS};
                $allstats{MEAN}{$SourcetypeSet}{VALUE} += $allstats{$TermSet}{$SourcetypeSet}{VALUE};
                $allstats{MEAN}{$SourcetypeSet}{PFA} += $allstats{$TermSet}{$SourcetypeSet}{PFA};
                $allstats{MEAN}{$SourcetypeSet}{PMISS} += $allstats{$TermSet}{$SourcetypeSet}{PMISS};
            }
            else
            {
                $allstats{$TermSet}{$SourcetypeSet}{VALUE} = -1000.0;
            }
        }
        
        if($allstats{$TermSet}{ALL}{REF} != 0)
        {            
            $allstats{$TermSet}{ALL}{VALUE} = sprintf("%.3f", ($self->{V}*$allstats{$TermSet}{ALL}{CORR} - $self->{C}*$allstats{$TermSet}{ALL}{FA})/($self->{V}*$allstats{$TermSet}{ALL}{REF}) );
            $allstats{TOTAL}{ALL}{NBR_TERMS} += 1;
            $allstats{MEAN}{ALL}{REF} += $allstats{$TermSet}{ALL}{REF};
            $allstats{MEAN}{ALL}{CORR} += $allstats{$TermSet}{ALL}{CORR};
            $allstats{MEAN}{ALL}{FA} += $allstats{$TermSet}{ALL}{FA};
            $allstats{MEAN}{ALL}{MISS} += $allstats{$TermSet}{ALL}{MISS};
            $allstats{MEAN}{ALL}{VALUE} += $allstats{$TermSet}{ALL}{VALUE};
            $allstats{MEAN}{ALL}{PFA} += $allstats{$TermSet}{ALL}{PFA};
            $allstats{MEAN}{ALL}{PMISS} += $allstats{$TermSet}{ALL}{PMISS};
        }
        else
        {
            $allstats{$TermSet}{ALL}{VALUE} = -1000.0;
        }
    }
    
    foreach my $SourcetypeSet(@all_SourcetypeSet)
    {
        if(($self->{V}*$allstats{TOTAL}{$SourcetypeSet}{REF}) != 0)
        {
            $allstats{TOTAL}{$SourcetypeSet}{VALUE} = sprintf("%.3f", ($self->{V}*$allstats{TOTAL}{$SourcetypeSet}{CORR} - $self->{C}*$allstats{TOTAL}{$SourcetypeSet}{FA})/($self->{V}*$allstats{TOTAL}{$SourcetypeSet}{REF}) );
        }
        else
        {
            $allstats{TOTAL}{$SourcetypeSet}{VALUE} = -1000.0
        }
        
        foreach my $Component("REF","CORR","FA","MISS","VALUE","PFA","PMISS")
        {
            if($allstats{TOTAL}{$SourcetypeSet}{NBR_TERMS} != 0)
            {
                $allstats{MEAN}{$SourcetypeSet}{$Component} = $allstats{MEAN}{$SourcetypeSet}{$Component}/$allstats{TOTAL}{$SourcetypeSet}{NBR_TERMS};
            }
            else
            {
                $allstats{MEAN}{$SourcetypeSet}{$Component} = -1000.0 if( ($Component eq "VALUE") || ($Component eq "PFA") || ($Component eq "PMISS") );
            }
            
        }
    }
    
    if(($self->{V}*$allstats{TOTAL}{ALL}{REF}) != 0)
    {
        $allstats{TOTAL}{ALL}{VALUE} = sprintf("%.3f", ($self->{V}*$allstats{TOTAL}{ALL}{CORR} - $self->{C}*$allstats{TOTAL}{ALL}{FA})/($self->{V}*$allstats{TOTAL}{ALL}{REF}) );
    }
    else
    {
        $allstats{TOTAL}{ALL}{VALUE} = -1000.0
    }
    
    foreach my $Component("REF","CORR","FA","MISS","VALUE","PFA","PMISS","TERMWEIGHTEDVALUE")
    {
        if($allstats{TOTAL}{ALL}{NBR_TERMS} != 0)
        {
            $allstats{MEAN}{ALL}{$Component} = $allstats{MEAN}{ALL}{$Component}/$allstats{TOTAL}{ALL}{NBR_TERMS};
        }
        else
        {
            $allstats{MEAN}{ALL}{$Component} = -1000.0 if( ($Component eq "VALUE") || ($Component eq "PFA") || ($Component eq "PMISS") );
        }
        
    }
    
    if($allstats{TOTAL}{ALL}{NBR_TERMS} != 0)
    {
        $allstats{MEAN}{SEARCH_TIME} = $allstats{MEAN}{SEARCH_TIME}/$allstats{MEAN}{ALL}{NBR_TERMS};
    }
    else
    {
        $allstats{MEAN}{SEARCH_TIME} = -1000.0;
    }
    
    return(\%allstats);
}

sub ReportOccurrence
{
    my ($self, $output, $display_all, $stats, $dset) = @_;
    
    if($output ne "")
    {
        open(OUTPUT_LOCAL, ($self->{STD}->{LANGUAGE} eq "mandarin") ? ">:encoding(gb2312)" : ">:encoding(utf8)", $output) or die "cannot open '$output'";
    }
    else
    {
        open(OUTPUT_LOCAL, ">&STDOUT") or die "cannot display in STDOUT";
    }
    
    my $display_bnews = ($stats->{TOTAL}{BNEWS}{NBR_TERMS} != 0);
    my $display_cts = ($stats->{TOTAL}{CTS}{NBR_TERMS} != 0);
    my $display_confmtg = ($stats->{TOTAL}{CONFMTG}{NBR_TERMS} != 0);
    
    print OUTPUT_LOCAL "+----------------------------------------------";
    print OUTPUT_LOCAL "----------------------------------------------" if($display_bnews);
    print OUTPUT_LOCAL "----------------------------------------------" if($display_cts);
    print OUTPUT_LOCAL "----------------------------------------------" if($display_confmtg);
    print OUTPUT_LOCAL "----------------------------------------------" if($display_all);
    print OUTPUT_LOCAL "+\n";
    
    my $minmaxdecstr = "";
    
    if ($self->{STD}->{MIN_YES} >= $self->{STD}->{MAX_NO})
    {
        $minmaxdecstr = "OK";
    }
    else
    {
        $minmaxdecstr = "Inconsistent";
    }
    
    foreach my $p("Indexing Time:|".sprintf("%.4f",$self->{STD}->{INDEXING_TIME}),
		  "Language:|".sprintf("%12s", $self->{STD}->{LANGUAGE}),
		  "Index size (bytes):|".sprintf("%12s", $self->{STD}->{INDEX_SIZE}),
		  "System ID:|".sprintf("%12s", $self->{STD}->{SYSTEM_ID}),
		  "Coefficient C:|".sprintf("%.4f",$stats->{COEFF}{KOEFC}),
		  "Coefficient V:|".sprintf("%.4f",$stats->{COEFF}{KOEFV}),
		  "Trials Per Second:|".sprintf("%.4f",$stats->{COEFF}{TRIALSPERSEC}),
		  "Probability of a Term:|".sprintf("%.4f",$stats->{COEFF}{PROBOFTERM}),
		  "Decision Score |".sprintf("%s (Max NO: %.4f, Min YES: %.4f)", $minmaxdecstr, $self->{STD}->{MAX_NO}, $self->{STD}->{MIN_YES})
		  )
    {
        printf OUTPUT_LOCAL "| %-23s %12s         ", split(/\|/,$p);
        print OUTPUT_LOCAL "                                              " if($display_bnews);
        print OUTPUT_LOCAL "                                              " if($display_cts);
        print OUTPUT_LOCAL "                                              " if($display_confmtg);
        print OUTPUT_LOCAL "                                              " if($display_all);
        print OUTPUT_LOCAL "|\n";
    }
    
    print OUTPUT_LOCAL "+----------------------------------------------";
    print OUTPUT_LOCAL "+---------------------------------------------" if($display_bnews);
    print OUTPUT_LOCAL "+---------------------------------------------" if($display_cts);
    print OUTPUT_LOCAL "+---------------------------------------------" if($display_confmtg);
    print OUTPUT_LOCAL "+---------------------------------------------" if($display_all);
    print OUTPUT_LOCAL "+\n";

    print OUTPUT_LOCAL "|                                       Search ";
    print OUTPUT_LOCAL "|                    BNEWS                    " if($display_bnews);
    print OUTPUT_LOCAL "|                     CTS                     " if($display_cts);
    print OUTPUT_LOCAL "|                   CONFMTG                   " if($display_confmtg);
    print OUTPUT_LOCAL "|                     ALL                     " if($display_all);
    print OUTPUT_LOCAL "|\n";
    
    print OUTPUT_LOCAL "|                                              ";
    print OUTPUT_LOCAL "|                          Occ.               " if($display_bnews);
    print OUTPUT_LOCAL "|                          Occ.               " if($display_cts);
    print OUTPUT_LOCAL "|                          Occ.               " if($display_confmtg);
    print OUTPUT_LOCAL "|                          Occ.               " if($display_all);
    print OUTPUT_LOCAL "|\n";
    
    print OUTPUT_LOCAL "|    TermID                     Text     Time  ";
    print OUTPUT_LOCAL "|    Ref  Corr   FA  Miss  Value P(FA)  P(Mis)" if($display_bnews);
    print OUTPUT_LOCAL "|    Ref  Corr   FA  Miss  Value P(FA)  P(Mis)" if($display_cts);
    print OUTPUT_LOCAL "|    Ref  Corr   FA  Miss  Value P(FA)  P(Mis)" if($display_confmtg);
    print OUTPUT_LOCAL "|    Ref  Corr   FA  Miss  Value P(FA)  P(Mis)" if($display_all);
    print OUTPUT_LOCAL "|\n";

    print OUTPUT_LOCAL "+----------------------------------------------";
    print OUTPUT_LOCAL "+---------------------------------------------" if($display_bnews);
    print OUTPUT_LOCAL "+---------------------------------------------" if($display_cts);
    print OUTPUT_LOCAL "+---------------------------------------------" if($display_confmtg);
    print OUTPUT_LOCAL "+---------------------------------------------" if($display_all);
    print OUTPUT_LOCAL "+\n";
    
    my $maxtermidlen = 0;
    
    foreach my $termid(sort keys %{ $stats } )
    {
        next if( ($termid eq "TOTAL") || ($termid eq "MEAN") );
        
        $maxtermidlen = max($maxtermidlen, length($termid));
    }
    
    my $maxtextlen = 34-$maxtermidlen;
    
    foreach my $termid(sort keys %{ $stats } )
    {
        next if( ($termid eq "TOTAL") || ($termid eq "MEAN")  || ($termid eq "COEFF") );
        
        my $display_termID = sprintf("%"."$maxtermidlen"."s", $termid);
        $display_termID = substr($display_termID, 0, $maxtermidlen-3) . "..." if(length($display_termID) > $maxtermidlen);
        
        my $termtext = $stats->{$termid}{TEXT};
        my $lengthtoapply = $maxtextlen;
        
        if($self->{STD}->{LANGUAGE} eq "mandarin")
        {
            $termtext = decode("gb2312", $stats->{$termid}{TEXT});
            my @ary = split(//, $termtext);
            
            for(my $i=0; $i<@ary; $i++)
            {
                $lengthtoapply-- if($ary[$i] !~ /[a-zA-Z \.\-\']/);                
            }
        }
        
        if($self->{STD}->{LANGUAGE} eq "arabic")
        {
           $termtext = decode("utf8", $stats->{$termid}{TEXT});
        }
        
        my $display_text = sprintf("%"."$lengthtoapply"."s", $termtext);
        $display_text = substr($display_text, 0, $maxtextlen-3) . "..." if(length($display_text) > $maxtextlen);   
        
        my $display_searchtime = sprintf("%8.2f", $stats->{$termid}{SEARCH_TIME});
        
        print OUTPUT_LOCAL "| $display_termID $display_text $display_searchtime ";
        
        foreach my $type("BNEWS", "CTS", "CONFMTG", "ALL")
        {
            my $display = ( ( ($type eq "BNEWS") && $display_bnews ) || 
                            ( ($type eq "CTS") && $display_cts ) ||
                            ( ($type eq "CONFMTG") && $display_confmtg ) ||
                            ( ($type eq "ALL") && $display_all ) );

            if($display)
            {
                my $display_ref = sprintf("%5s", $stats->{$termid}{$type}{REF});
                my $display_corr = sprintf("%5s", $stats->{$termid}{$type}{CORR});
                my $display_fa = sprintf("%5s", $stats->{$termid}{$type}{FA});
                my $display_miss = sprintf("%5s", $stats->{$termid}{$type}{MISS});
                my $display_Pfa = (($stats->{$termid}{$type}{PFA} != -1000.0) ? sprintf("%7.5f", $stats->{$termid}{$type}{PFA}) : sprintf("%6s", "N/A"));
                my $display_Pmiss = (($stats->{$termid}{$type}{PMISS} != -1000.0) ? sprintf("%.3f", $stats->{$termid}{$type}{PMISS}) : sprintf("%5s", "N/A"));
                my $display_value;
                
                if($stats->{$termid}{$type}{VALUE} != -1000.0)
                {
                    $display_value = sprintf("%5.3f", $stats->{$termid}{$type}{VALUE});
                }
                else
                {
                    $display_value = sprintf("%6s", "N/A");
                }
                
                print OUTPUT_LOCAL "| $display_ref $display_corr $display_fa $display_miss $display_value $display_Pfa $display_Pmiss ";
            }
        }
        
        print OUTPUT_LOCAL "|\n";
    }
    
    print OUTPUT_LOCAL "+----------------------------------------------";
    print OUTPUT_LOCAL "+---------------------------------------------" if($display_bnews);
    print OUTPUT_LOCAL "+---------------------------------------------" if($display_cts);
    print OUTPUT_LOCAL "+---------------------------------------------" if($display_confmtg);
    print OUTPUT_LOCAL "+---------------------------------------------" if($display_all);
    print OUTPUT_LOCAL "+\n";
    
    foreach my $level("TOTAL","MEAN")
    {
        my $display_searchtime = sprintf("%8s", sprintf("%.2f", $stats->{$level}{SEARCH_TIME}) );

        if($level eq "TOTAL")
        {
            print OUTPUT_LOCAL "| Totals, Actual Occ. Weighted Value  $display_searchtime ";
        }
        else
        {
            print OUTPUT_LOCAL "| Means (N/A excl.)                   $display_searchtime ";
        }
    
        foreach my $type("BNEWS", "CTS", "CONFMTG", "ALL")
        {
            my $display = ( ( ($type eq "BNEWS") && $display_bnews ) || 
                            ( ($type eq "CTS") && $display_cts ) ||
                            ( ($type eq "CONFMTG") && $display_confmtg ) ||
                            ( ($type eq "ALL") && $display_all ) );
        
            if($display)
            {
                my $display_ref = sprintf("%5d", $stats->{$level}{$type}{REF});
                my $display_corr = sprintf("%5d", $stats->{$level}{$type}{CORR});
                my $display_fa = sprintf("%5d", $stats->{$level}{$type}{FA});
                my $display_miss = sprintf("%5d", $stats->{$level}{$type}{MISS});
                my $display_pmiss = sprintf("%5.3f", $stats->{$level}{$type}{PMISS});
                my $display_pfa = sprintf("%7.5f", $stats->{$level}{$type}{PFA});
                my $display_value;
                
                if($stats->{$level}{$type}{VALUE} != -1000.0)
                {
                    $display_value = sprintf("%5.3f", $stats->{$level}{$type}{VALUE});
                }
                else
                {
                    $display_value = sprintf("%5s", "N/A");
                }
                
                print OUTPUT_LOCAL "| $display_ref $display_corr $display_fa $display_miss $display_value $display_pfa $display_pmiss ";
            }
        }
        
        print OUTPUT_LOCAL "|\n";
    }
        
    print OUTPUT_LOCAL "+----------------------------------------------";
    print OUTPUT_LOCAL "+---------------------------------------------" if($display_bnews);
    print OUTPUT_LOCAL "+---------------------------------------------" if($display_cts);
    print OUTPUT_LOCAL "+---------------------------------------------" if($display_confmtg);
    print OUTPUT_LOCAL "+---------------------------------------------" if($display_all);
    print OUTPUT_LOCAL "+\n";

    print OUTPUT_LOCAL "|                                              ";
    printf OUTPUT_LOCAL "|  Number of Trials             %8d      ", $stats->{TOTAL}{BNEWS}{NUMTRIALS} if ($display_bnews);
    printf OUTPUT_LOCAL "|  Number of Trials             %8d      ", $stats->{TOTAL}{CTS}{NUMTRIALS} if ($display_cts);
    printf OUTPUT_LOCAL "|  Number of Trials             %8d      ", $stats->{TOTAL}{CONFMTG}{NUMTRIALS} if ($display_confmtg);
    printf OUTPUT_LOCAL "|  Number of Trials             %8d      ", $stats->{TOTAL}{ALL}{NUMTRIALS} if ($display_all);
    print OUTPUT_LOCAL "|\n";
   
    print OUTPUT_LOCAL "|                                              ";
    printf OUTPUT_LOCAL "|  Total Speech Time (sec.)       %8.1f    ", $stats->{TOTAL}{BNEWS}{TOTALTIME} if ($display_bnews);
    printf OUTPUT_LOCAL "|  Total Speech Time (sec.)       %8.1f    ", $stats->{TOTAL}{CTS}{TOTALTIME} if ($display_cts);
    printf OUTPUT_LOCAL "|  Total Speech Time (sec.)       %8.1f    ", $stats->{TOTAL}{CONFMTG}{TOTALTIME} if ($display_confmtg);
    printf OUTPUT_LOCAL "|  Total Speech Time (sec.)       %8.1f    ", $stats->{TOTAL}{ALL}{TOTALTIME} if ($display_all);
    print OUTPUT_LOCAL "|\n";
   
    print OUTPUT_LOCAL "|                                              ";
    printf OUTPUT_LOCAL "|  A. T-Weighted Value (N/A excl.)  %8.3f  ", $stats->{MEAN}{BNEWS}{TERMWEIGHTEDVALUE} if ($display_bnews);
    printf OUTPUT_LOCAL "|  A. T-Weighted Value (N/A excl.)  %8.3f  ", $stats->{MEAN}{CTS}{TERMWEIGHTEDVALUE} if ($display_cts);
    printf OUTPUT_LOCAL "|  A. T-Weighted Value (N/A excl.)  %8.3f  ", $stats->{MEAN}{CONFMTG}{TERMWEIGHTEDVALUE} if ($display_confmtg);
    printf OUTPUT_LOCAL "|  A. T-Weighted Value (N/A excl.)  %8.3f  ", $stats->{MEAN}{ALL}{TERMWEIGHTEDVALUE} if ($display_all);
    print OUTPUT_LOCAL "|\n";

    print OUTPUT_LOCAL "+----------------------------------------------";
    print OUTPUT_LOCAL "+---------------------------------------------" if($display_bnews);
    print OUTPUT_LOCAL "+---------------------------------------------" if($display_cts);
    print OUTPUT_LOCAL "+---------------------------------------------" if($display_confmtg);
    print OUTPUT_LOCAL "+---------------------------------------------" if($display_all);
    print OUTPUT_LOCAL "+\n";

    if ($dset->hasDETs())
    {
        print OUTPUT_LOCAL "\n";
        print OUTPUT_LOCAL "+-------------------------------------------------------------------+\n";
        print OUTPUT_LOCAL "|                    DET Curve Analysis Summary                     |\n";
        print OUTPUT_LOCAL "+-------------+----------------------+------------------------------+\n";
        
        my $headerdisplay;
        $headerdisplay = ($dset->{DETS}->{BNEWS}->getStyle() eq "pooled" ? "Occ." : "Term") if($display_bnews);
        $headerdisplay = ($dset->{DETS}->{CTS}->getStyle() eq "pooled" ? "Occ." : "Term") if($display_cts);
        $headerdisplay = ($dset->{DETS}->{CONFMTG}->getStyle() eq "pooled" ? "Occ." : "Term") if($display_confmtg);
        
        print OUTPUT_LOCAL "|             |     $headerdisplay Weighted    |                   Decision   |\n";
        print OUTPUT_LOCAL "| Description | Max Value | A. Value |   P(Fa) P(Miss)      Score   |\n";
        print OUTPUT_LOCAL "+-------------+-----------+----------+------------------------------+\n";
        
        if($display_bnews)
        {	
            if ($dset->{DETS}->{BNEWS}->successful())
            {
                my $bnewsdetdisplay = sprintf("|       BNEWS |   %.4f  |  %.4f  | %.5f   %.3f   %.8f |", $dset->{DETS}->{BNEWS}->getMaxValueValue(), ($dset->{DETS}->{BNEWS}->getStyle() eq "pooled" ? $stats->{TOTAL}{BNEWS}{VALUE} : $stats->{MEAN}{BNEWS}{TERMWEIGHTEDVALUE}), $dset->{DETS}->{BNEWS}->getMaxValuePFA(), $dset->{DETS}->{BNEWS}->getMaxValuePMiss(), $dset->{DETS}->{BNEWS}->getMaxValueDetectionScore() );
                
                print OUTPUT_LOCAL "$bnewsdetdisplay\n";
            }
            else
            {
                print OUTPUT_LOCAL "|       BNEWS |      N/A  |     N/A  |     N/A     N/A          N/A |\n";
            }
        }
        
        if($display_cts)
        {
            if ($dset->{DETS}->{CTS}->successful())
            {
                my $bnewsdetdisplay = sprintf("|         CTS |   %.4f  |  %.4f  | %.5f   %.3f   %.8f |", $dset->{DETS}->{CTS}->getMaxValueValue(), ($dset->{DETS}->{CTS}->getStyle() eq "pooled" ? $stats->{TOTAL}{CTS}{VALUE} : $stats->{MEAN}{CTS}{TERMWEIGHTEDVALUE}), $dset->{DETS}->{CTS}->getMaxValuePFA(),$dset->{DETS}->{CTS}->getMaxValuePMiss(), $dset->{DETS}->{CTS}->getMaxValueDetectionScore() );
                print OUTPUT_LOCAL "$bnewsdetdisplay\n";
            }
            else
            {
                print OUTPUT_LOCAL "|         CTS |      N/A  |     N/A  |     N/A     N/A          N/A |\n";
            }
        }
        
        if($display_confmtg)
        {
            if ($dset->{DETS}->{CONFMTG}->successful())
            {
                my $bnewsdetdisplay = sprintf("|     CONFMTG |   %.4f  |  %.4f  | %.5f   %.3f   %.8f |", $dset->{DETS}->{CONFMTG}->getMaxValueValue(), ($dset->{DETS}->{CONFMTG}->getStyle() eq "pooled" ? $stats->{TOTAL}{CONFMTG}{VALUE} : $stats->{MEAN}{CONFMTG}{TERMWEIGHTEDVALUE}), $dset->{DETS}->{CONFMTG}->getMaxValuePFA(),$dset->{DETS}->{CONFMTG}->getMaxValuePMiss(), $dset->{DETS}->{CONFMTG}->getMaxValueDetectionScore() );
		
                print OUTPUT_LOCAL "$bnewsdetdisplay\n";
            }
            else
            {
                print OUTPUT_LOCAL "|     CONFMTG |      N/A  |     N/A  |     N/A     N/A          N/A |\n";
            }
        }
        
        if($display_all)
        {
            print OUTPUT_LOCAL "+-------------+-----------+----------+------------------------------+\n";
            
            if ($dset->{DETS}->{ALL}->successful())
            {
                my $bnewsdetdisplay = sprintf("|         ALL |   %.4f  |  %.4f  | %.5f   %.3f   %.8f |", $dset->{DETS}->{ALL}->getMaxValueValue(), ($dset->{DETS}->{ALL}->getStyle() eq "pooled" ? $stats->{TOTAL}{ALL}{VALUE} : $stats->{MEAN}{ALL}{TERMWEIGHTEDVALUE}), $dset->{DETS}->{ALL}->getMaxValuePFA(),$dset->{DETS}->{ALL}->getMaxValuePMiss(), $dset->{DETS}->{ALL}->getMaxValueDetectionScore() );
                
                print OUTPUT_LOCAL "$bnewsdetdisplay\n";
            }
            else
            {
                print OUTPUT_LOCAL "|         ALL |      N/A  |     N/A  |     N/A     N/A          N/A |\n";
            } 
        }
        
        print OUTPUT_LOCAL "+-------------+-----------+----------+------------------------------+\n";
    }

    close(OUTPUT_LOCAL);
}

sub ReportConditionalOccurrence
{
    my ($self, $output, $stats, $dset) = @_;
    
    if($output ne "")
    {
        open(OUTPUT_LOCAL, ">$output") or die "cannot open '$output'";
    }
    else
    {
        open(OUTPUT_LOCAL, ">&STDOUT") or die "cannot display in STDOUT";
    }
    
    my @all_TermSet;
    my @all_SourcetypeSet;
    
    my $nbrTermSet = 0;
    my $nbrSourcetypeSet = 0;
    
    foreach my $termset(sort keys %{ $stats })
    {
        next if($termset eq "TOTAL" || $termset eq "MEAN" || $termset eq "COEFF");
        push (@all_TermSet, $termset);
        $nbrTermSet += 1;
    }
    
    foreach my $sourcetypeset(sort keys %{ $stats->{TOTAL} })
    {
        next if($sourcetypeset eq "SEARCH_TIME" || $sourcetypeset eq "ALL");
        push (@all_SourcetypeSet, $sourcetypeset);
        $nbrSourcetypeSet += 1;
    }
    
    print OUTPUT_LOCAL "+----------------------------------------------";
    for(my $i=0; $i<$nbrSourcetypeSet; $i++) { print OUTPUT_LOCAL "------------------------------------------------------------"; }
    print OUTPUT_LOCAL "+\n";
    
    my $minmaxdecstr = "";
    
    if ($self->{STD}->{MIN_YES} >= $self->{STD}->{MAX_NO})
    {
        $minmaxdecstr = "OK";
    }
    else
    {
        $minmaxdecstr = "Inconsistent";
    }
    
    foreach my $p("Indexing Time:|".sprintf("%.4f",$self->{STD}->{INDEXING_TIME}),
		  "Language:|".sprintf("%12s", $self->{STD}->{LANGUAGE}),
		  "Index size (bytes):|".sprintf("%12s", $self->{STD}->{INDEX_SIZE}),
		  "System ID:|".sprintf("%12s", $self->{STD}->{SYSTEM_ID}),
		  "Coefficient C:|".sprintf("%.4f",$stats->{COEFF}{KOEFC}),
		  "Coefficient V:|".sprintf("%.4f",$stats->{COEFF}{KOEFV}),
		  "Trials Per Second:|".sprintf("%.4f",$stats->{COEFF}{TRIALSPERSEC}),
		  "Probability of a Term:|".sprintf("%.4f",$stats->{COEFF}{PROBOFTERM}),
		  "Decision Score |".sprintf("%s (Max NO: %.4f, Min YES: %.4f)", $minmaxdecstr, $self->{STD}->{MAX_NO}, $self->{STD}->{MIN_YES})
		  )
    {
	   printf OUTPUT_LOCAL "| %-23s %12s         ", split(/\|/,$p);
	   for(my $i=0; $i<$nbrSourcetypeSet; $i++) { print OUTPUT_LOCAL "                                                            "; }
	   print OUTPUT_LOCAL "|\n";
    }
    
    print OUTPUT_LOCAL "+----------------------------------------------";
    for(my $i=0; $i<$nbrSourcetypeSet; $i++) { print OUTPUT_LOCAL "+-----------------------------------------------------------"; }
    print OUTPUT_LOCAL "+\n";

    print OUTPUT_LOCAL "|                                       Search ";
    
    for(my $i=0; $i<$nbrSourcetypeSet; $i++)
    {
        my $display_sourcetypeset = sprintf("%57s", $all_SourcetypeSet[$i]);
        $display_sourcetypeset = sprintf("%57s", "All Source Types") if ($all_SourcetypeSet[$i] eq "");
        $display_sourcetypeset = substr($display_sourcetypeset, 0, 54) . "..." if(length($display_sourcetypeset) > 57);
        print OUTPUT_LOCAL "| $display_sourcetypeset "
    }
    
    print OUTPUT_LOCAL "|\n";
    
    print OUTPUT_LOCAL "|                                              ";
    for(my $i=0; $i<$nbrSourcetypeSet; $i++) { print OUTPUT_LOCAL "|                          Occ.                 Nbr    TW   "; }
    print OUTPUT_LOCAL "|\n";
    
    if($nbrTermSet != 0)
    {
        print OUTPUT_LOCAL "|    TermSet                             Time  ";
    }
    else
    {
        print OUTPUT_LOCAL "|                                        Time  ";
    }
    
    for(my $i=0; $i<$nbrSourcetypeSet; $i++) { print OUTPUT_LOCAL "|    Ref  Corr   FA  Miss  Value P(FA)  P(Mis) Trials Value "; }
    print OUTPUT_LOCAL "|\n";

    print OUTPUT_LOCAL "+----------------------------------------------";
    for(my $i=0; $i<$nbrSourcetypeSet; $i++) { print OUTPUT_LOCAL "+-----------------------------------------------------------"; }
    print OUTPUT_LOCAL "+\n";
   
    foreach my $termset(@all_TermSet)
    {
        my $display_termSet;
        
        if($termset eq "")
        {
            $display_termSet = sprintf("%35s", "All Terms");
        }
        else
        {
            $display_termSet = sprintf("%35s", $termset);
        }
        
        $display_termSet = substr($display_termSet, 0, 32) . "..." if(length($display_termSet) > 35);
        
        my $display_searchtime = sprintf("%8.2f", $stats->{$termset}{SEARCH_TIME});
        
        print OUTPUT_LOCAL "| $display_termSet $display_searchtime ";
        
        foreach my $type(@all_SourcetypeSet)
        {
            my $display_ref = sprintf("%5s", $stats->{$termset}{$type}{REF});
            my $display_corr = sprintf("%5s", $stats->{$termset}{$type}{CORR});
            my $display_fa = sprintf("%5s", $stats->{$termset}{$type}{FA});
            my $display_miss = sprintf("%5s", $stats->{$termset}{$type}{MISS});
            my $display_Pfa = (($stats->{$termset}{$type}{PFA} != -1000.0) ? sprintf("%7.5f", $stats->{$termset}{$type}{PFA}) : sprintf("%6s", "N/A"));
            my $display_Pmiss = (($stats->{$termset}{$type}{PMISS} != -1000.0) ? sprintf("%.3f", $stats->{$termset}{$type}{PMISS}) : sprintf("%6s", "N/A"));
            my $display_NbrTrials = sprintf("%7d", $stats->{$termset}{$type}{NUMTRIALS});
            my $display_TWValue = sprintf("%5.3f", $stats->{$termset}{$type}{TERMWEIGHTEDVALUE});
            my $display_value;
            
            if($stats->{$termset}{$type}{VALUE} != -1000.0)
            {
                $display_value = sprintf("%5.3f", $stats->{$termset}{$type}{VALUE});
            }
            else
            {
                $display_value = sprintf("%5s", "N/A");
            }
            
            print OUTPUT_LOCAL "| $display_ref $display_corr $display_fa $display_miss $display_value $display_Pfa $display_Pmiss $display_NbrTrials $display_TWValue ";
        }
        
        print OUTPUT_LOCAL "|\n";
    }
    
    print OUTPUT_LOCAL "+----------------------------------------------";
    for(my $i=0; $i<$nbrSourcetypeSet; $i++) { print OUTPUT_LOCAL "+-----------------------------------------------------------"; }
    print OUTPUT_LOCAL "+\n";

    if( $dset->hasDETs())
    {
        print OUTPUT_LOCAL "\n";
        print OUTPUT_LOCAL "+-----------------------------------------------------------------------------+\n";
        print OUTPUT_LOCAL "|                         DET Curve Analysis Summary                          |\n";
        print OUTPUT_LOCAL "+-----------------------+----------------------+------------------------------+\n";
        print OUTPUT_LOCAL "|                       |     Term Weighted    |                   Decision   |\n";
        print OUTPUT_LOCAL "|      Description      | Max Value | A. Value |   P(Fa) P(Miss)      Score   |\n";
        print OUTPUT_LOCAL "+-----------------------+-----------+----------+------------------------------+\n";
        
        foreach my $termset(sort @all_TermSet)
        {
            foreach my $sourcetype (sort @all_SourcetypeSet)
            {
                my $titledetset = "$termset $sourcetype";
                my $displayNAs = 0;
                
                $displayNAs = 1 if ( !$dset->{DETS}->{$titledetset} );

                if(!$displayNAs && $dset->{DETS}->{$titledetset}->successful())
                {
                    my $detdisplay = sprintf("| %21s |   %.4f  |  %.4f  | %.5f   %.3f   %.8f |", $titledetset, $dset->{DETS}->{$titledetset}->getMaxValueValue(), ($dset->{DETS}->{$titledetset}->getStyle() eq "pooled" ? $stats->{$termset}{$sourcetype}{VALUE} : $stats->{$termset}{$sourcetype}{TERMWEIGHTEDVALUE}), $dset->{DETS}->{$titledetset}->getMaxValuePFA(), $dset->{DETS}->{$titledetset}->getMaxValuePMiss(), $dset->{DETS}->{$titledetset}->getMaxValueDetectionScore() );
                
                    print OUTPUT_LOCAL "$detdisplay\n";
                }
                
                if($displayNAs)
                {
                    my $detdisplay = sprintf("| %21s |      N/A  |     N/A  |     N/A     N/A          N/A |", $titledetset);
                
                    print OUTPUT_LOCAL "$detdisplay\n";
                }
            }
        }
        
        print OUTPUT_LOCAL "+-----------------------+-----------+----------+------------------------------+\n";
    }


    close(OUTPUT_LOCAL);
}

sub ReportHTML
{
    my ($self, $output, $display_all, $stats, $dset) = @_;
    
    open(OUTPUT_INDEX, ($self->{STD}->{LANGUAGE} eq "mandarin") ? ">:encoding(gb2312)" : ">:encoding(utf8)", "$output/index.html") or die "cannot open '$output/index.html'";
    
    my $display_bnews = ($stats->{TOTAL}{BNEWS}{NBR_TERMS} != 0);
    my $display_cts = ($stats->{TOTAL}{CTS}{NBR_TERMS} != 0);
    my $display_confmtg = ($stats->{TOTAL}{CONFMTG}{NBR_TERMS} != 0);
    
    my %datahiddenreport;
    $datahiddenreport{GLOBAL} = "";
    
    if($self->{STD}->{LANGUAGE} eq "mandarin")
    {
        print OUTPUT_INDEX "<?xml version=\"1.0\" encoding=\"GB2312\"?>\n";
    }
    else
    {
        print OUTPUT_INDEX "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    }
    
    print OUTPUT_INDEX "<html>\n";
    print OUTPUT_INDEX "<head>\n";
    print OUTPUT_INDEX "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=gb2312\" />\n" if($self->{STD}->{LANGUAGE} eq "mandarin");
    print OUTPUT_INDEX "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n" if($self->{STD}->{LANGUAGE} ne "mandarin");
    print OUTPUT_INDEX "<title>$self->{STD}->{SYSTEM_ID}</title>\n";    
    print OUTPUT_INDEX "</head>\n";
    print OUTPUT_INDEX "<body leftmargin=0 topmargin=0 marginwidth=0 marginheight=0>\n";
    print OUTPUT_INDEX "<table align=center bgcolor=#fefefe border=0>\n";
    print OUTPUT_INDEX "<tr valign=top>\n";
    print OUTPUT_INDEX "<td>\n"; 
    print OUTPUT_INDEX "<table>\n";
    
    my $indexingtimedisplay = sprintf("%.2f", $self->{STD}->{INDEXING_TIME});
    print OUTPUT_INDEX "<tr><td>Indexing Time: </td><td> $indexingtimedisplay</td></tr>\n";
    print OUTPUT_INDEX "<tr><td>Language: </td><td> $self->{STD}->{LANGUAGE}</td></tr>\n";
    
    $datahiddenreport{GLOBAL} .= "<language>$self->{STD}->{LANGUAGE}</language>";
    
    print OUTPUT_INDEX "<tr><td>Index size: </td><td> $self->{STD}->{INDEX_SIZE}</td></tr>\n";
    
    $datahiddenreport{GLOBAL} .= "<index_size>$self->{STD}->{INDEX_SIZE}</index_size>";
    
    print OUTPUT_INDEX "<tr><td>System ID: </td><td> $self->{STD}->{SYSTEM_ID}</td></tr>\n";
    
    $datahiddenreport{GLOBAL} .= "<system_id>$self->{STD}->{SYSTEM_ID}</system_id>";
    
    print OUTPUT_INDEX "<tr><td>Coefficient C: </td><td> ".sprintf("%.4f",$stats->{COEFF}{KOEFC})."</td></tr>\n";
    print OUTPUT_INDEX "<tr><td>Coefficient V: </td><td> ".sprintf("%.4f",$stats->{COEFF}{KOEFV})."</td></tr>\n";
    print OUTPUT_INDEX "<tr><td>Trials Per Second: </td><td> ".sprintf("%.4f",$stats->{COEFF}{TRIALSPERSEC})."</td></tr>\n";
    print OUTPUT_INDEX "<tr><td>Probability of a Term: </td><td> ".sprintf("%.4f",$stats->{COEFF}{PROBOFTERM})."</td></tr>\n"; 
    
    my $minmaxdecstr = "";
    
    if ($self->{STD}->{MIN_YES} >= $self->{STD}->{MAX_NO})
    {
        $minmaxdecstr = "OK";
    }
    else
    {
        $minmaxdecstr = "Inconsistent";
    }
    
    print OUTPUT_INDEX "<tr><td>Decision Score: </td><td> ".sprintf("%s (Max NO: %.4f, Min YES: %.4f)", $minmaxdecstr, $self->{STD}->{MAX_NO}, $self->{STD}->{MIN_YES})."</td></tr>\n";
       
    print OUTPUT_INDEX "</table>\n";
    print OUTPUT_INDEX "<table width=100% border=0>\n";
    
    print OUTPUT_INDEX "<tr bgcolor=#A2C0DF>\n";
    print OUTPUT_INDEX "<td colspan=3 align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF><b>TermID</b></font></td>\n";
    print OUTPUT_INDEX "<td colspan=7 align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF><b>BNEWS</b></font></td>\n" if($display_bnews);
    print OUTPUT_INDEX "<td colspan=7 align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF><b>CTS</b></font></td>\n" if($display_cts);
    print OUTPUT_INDEX "<td colspan=7 align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF><b>CONFMTG</b></font></td>\n" if($display_confmtg);
    print OUTPUT_INDEX "<td colspan=7 align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF><b>ALL</b></font></td>\n" if($display_all);
    print OUTPUT_INDEX "</tr>\n";
            
    print OUTPUT_INDEX "<tr bgcolor=#A2C0DF>\n";
    print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF><b>TermID</b></font></td>\n";
    print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF><b>Text</b></font></td>\n";
    print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF><b>Search Time</b></font></td>\n";
    
    if($display_bnews)
    {
        $datahiddenreport{BNEWS} = "";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>Ref</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>Corr</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>FA</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>Miss</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>Occ. <BR> Value</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>P(FA)</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>P(Miss)</font></td>\n";
    }
    
    if($display_cts)
    {
        $datahiddenreport{CTS} = "";                                       
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>Ref</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>Corr</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>FA</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>Miss</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>Occ. <BR> Value</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>P(FA)</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>P(Miss)</font></td>\n";
    }
    
    if($display_confmtg)
    {
        $datahiddenreport{CONFMTG} = "";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>Ref</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>Corr</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>FA</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>Miss</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>Occ. <BR> Value</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>P(FA)</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>P(Miss)</font></td>\n";
    }
    
    if($display_all)
    {
        $datahiddenreport{ALL} = "";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>Ref</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>Corr</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>FA</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>Miss</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>Occ. <BR> Value</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>P(FA)</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>P(Miss)</font></td>\n";
    }
    
    print OUTPUT_INDEX "</tr>\n";
    
    
    foreach my $termid(sort keys %{ $stats } )
    {
        next if( ($termid eq "TOTAL") || ($termid eq "MEAN" || $termid eq "COEFF") );
     
        print OUTPUT_INDEX "<tr>\n";
        
        my $termtext = $stats->{$termid}{TEXT};
        $termtext = decode("gb2312", $stats->{$termid}{TEXT}) if($self->{STD}->{LANGUAGE} eq "mandarin");
        $termtext = decode("utf8", $stats->{$termid}{TEXT}) if($self->{STD}->{LANGUAGE} eq "arabic");
        
        print OUTPUT_INDEX "<td bgcolor=#DADADA><font face=\"Verdana, Arial, Helvetica, sans-serif\">$termid</font></td>\n";
        print OUTPUT_INDEX "<td bgcolor=#DADADA align=right><font face=\"Verdana, Arial, Helvetica, sans-serif\">$termtext</font></td>\n";
        
        my $display_searchtime = sprintf("%.2f", $stats->{$termid}{SEARCH_TIME});
        
        print OUTPUT_INDEX "<td bgcolor=#DADADA align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\">$display_searchtime</font></td>\n";
        
        foreach my $type("BNEWS", "CTS", "CONFMTG", "ALL")
        {
            my $display = ( ( ($type eq "BNEWS") && $display_bnews ) || 
                            ( ($type eq "CTS") && $display_cts ) ||
                            ( ($type eq "CONFMTG") && $display_confmtg ) ||
                            ( ($type eq "ALL") && $display_all ) );

            if($display)
            {
                my ($display_value, $display_pfa, $display_pmiss);
                
                if($stats->{$termid}{$type}{VALUE} != -1000.0)
                {
                    $display_value = sprintf("%.3f", $stats->{$termid}{$type}{VALUE});
                }
                else
                {
                    $display_value = "N/A";
                }
                                
                $display_pfa = ($stats->{$termid}{$type}{PFA} != -1000.0) ? sprintf("%.5f", $stats->{$termid}{$type}{PFA}) : "N/A";
                $display_pmiss = ($stats->{$termid}{$type}{PMISS} != -1000.0) ? sprintf("%.3f", $stats->{$termid}{$type}{PMISS}) : "N/A";
                
                print OUTPUT_INDEX "<td bgcolor=#EEEEEE align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$stats->{$termid}{$type}{REF}</font></td>\n";
                print OUTPUT_INDEX "<td bgcolor=#EEEEEE align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$stats->{$termid}{$type}{CORR}</font></td>\n";
                print OUTPUT_INDEX "<td bgcolor=#EEEEEE align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$stats->{$termid}{$type}{FA}</font></td>\n";
                print OUTPUT_INDEX "<td bgcolor=#EEEEEE align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$stats->{$termid}{$type}{MISS}</font></td>\n";
                print OUTPUT_INDEX "<td bgcolor=#EEEEEE align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$display_value</font></td>\n";
                print OUTPUT_INDEX "<td bgcolor=#EEEEEE align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$display_pfa</font></td>\n";
                print OUTPUT_INDEX "<td bgcolor=#EEEEEE align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$display_pmiss</font></td>\n";
            }
        }
        
        print OUTPUT_INDEX "</tr>\n";
    }
    
    foreach my $level("TOTAL","MEAN")
    {
        print OUTPUT_INDEX "<tr>\n";
        my $display_searchtime = sprintf("%.2f", $stats->{$level}{SEARCH_TIME});

        if($level eq "TOTAL")
        {
            print OUTPUT_INDEX "<td colspan=2 bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\">Totals, Actual Occ. Weighted Value</font></td>\n";
            print OUTPUT_INDEX "<td bgcolor=#A2C0DF align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\">$display_searchtime</font></td>\n";
            $datahiddenreport{GLOBAL} .= "<search_time>$display_searchtime</search_time>";
        }
        else
        {
            print OUTPUT_INDEX "<td colspan=2 bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\">Term weighted Means (N/A excl.)</font></td>\n";
            print OUTPUT_INDEX "<td bgcolor=#A2C0DF align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\">$display_searchtime</font></td>\n";
        }
    
        foreach my $type("BNEWS", "CTS", "CONFMTG", "ALL")
        {
            my $display = ( ( ($type eq "BNEWS") && $display_bnews ) || 
                            ( ($type eq "CTS") && $display_cts ) ||
                            ( ($type eq "CONFMTG") && $display_confmtg ) ||
                            ( ($type eq "ALL") && $display_all ) );
        
            if($display)
            {
                my $display_ref = sprintf("%d", $stats->{$level}{$type}{REF});
                my $display_corr = sprintf("%d", $stats->{$level}{$type}{CORR});
                my $display_fa = sprintf("%d", $stats->{$level}{$type}{FA});
                my $display_miss = sprintf("%d", $stats->{$level}{$type}{MISS});
                my ($display_value, $display_pfa, $display_pmiss);
                
                if($stats->{$level}{$type}{VALUE} != -1000.0)
                {
                    $display_value = sprintf("%.3f", $stats->{$level}{$type}{VALUE});
                    $datahiddenreport{$type} .= "<aowv>$display_value</aowv>" if($level eq "TOTAL");
                }
                else
                {
                    $display_value = "N/A";
                }

                $display_pfa = ($stats->{$level}{$type}{PFA} != -1000.0) ? sprintf("%.5f", $stats->{$level}{$type}{PFA}) : "N/A";
                $display_pmiss = ($stats->{$level}{$type}{PMISS} != -1000.0) ? sprintf("%.3f", $stats->{$level}{$type}{PMISS}) : "N/A";
                
                print OUTPUT_INDEX "<td bgcolor=#A2C0DF align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$display_ref</font></td>\n";
                print OUTPUT_INDEX "<td bgcolor=#A2C0DF align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$display_corr</font></td>\n";
                print OUTPUT_INDEX "<td bgcolor=#A2C0DF align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$display_fa</font></td>\n";
                print OUTPUT_INDEX "<td bgcolor=#A2C0DF align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$display_miss</font></td>\n";
                print OUTPUT_INDEX "<td bgcolor=#A2C0DF align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$display_value</font></td>\n";
                print OUTPUT_INDEX "<td bgcolor=#A2C0DF align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$display_pfa</font></td>\n";
                print OUTPUT_INDEX "<td bgcolor=#A2C0DF align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$display_pmiss</font></td>\n";
            }
        }

        print OUTPUT_INDEX "</tr>\n";
    }

    foreach my $line("Number of Trials:TOTAL:NUMTRIALS:%s", "Total Speech Time (sec.):TOTAL:TOTALTIME:%.1f", "Actual Term-Weighted Value (N/A excl.):MEAN:TERMWEIGHTEDVALUE:%.3f")
    {
        my ($desc, $set, $attr, $fmt) = split(/:/,$line);

        print OUTPUT_INDEX "<tr>\n";

        if ($desc eq "Number of Trials")
        {
            print OUTPUT_INDEX "<td colspan=3 bgcolor=#A2C0DF rowspan=3><font face=\"Verdana, Arial, Helvetica, sans-serif\"></font></td>\n";
        }

        foreach my $type("BNEWS", "CTS", "CONFMTG", "ALL")
        {
            my $display = ( ( ($type eq "BNEWS") && $display_bnews ) || 
                            ( ($type eq "CTS") && $display_cts ) ||
                            ( ($type eq "CONFMTG") && $display_confmtg ) ||
                            ( ($type eq "ALL") && $display_all ) );

            if($display)
            {
                my $val = sprintf($fmt, $stats->{$set}{$type}{$attr});
                
                print OUTPUT_INDEX "<td colspan=5 bgcolor=#A2C0DF align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$desc</font></td>\n";
                print OUTPUT_INDEX "<td colspan=2 bgcolor=#A2C0DF align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$val</font></td>\n";
            } 
        }

        print OUTPUT_INDEX "</tr>\n";
    }           

    print OUTPUT_INDEX "</table>\n";
    print OUTPUT_INDEX "</td>\n";
    print OUTPUT_INDEX "</tr>\n";
    print OUTPUT_INDEX "</table>\n";
    
    if ($dset->hasDETs())
    {
        print OUTPUT_INDEX "\n";
        $dset->writeMultiDET("$output/DET");
        
        my $purged_filename = $dset->{COMBINED_DET_PNG};
        $purged_filename =~ s/^.+\///;
        $datahiddenreport{GLOBAL} .= "<combined_det_png>$purged_filename</combined_det_png>";
        
        print OUTPUT_INDEX "<hr>\n";
        print OUTPUT_INDEX "<table border=0>\n";
        print OUTPUT_INDEX "<tr bgcolor=#A2C0DF>\n";
        print OUTPUT_INDEX "<th colspan=8 align=center>DET Curve Analysis Summary<br><img src=\"$purged_filename\" alt=\"Combined DET Plot\"/></th></tr>\n";
        print OUTPUT_INDEX "<tr bgcolor=#A2C0DF>\n";
        print OUTPUT_INDEX "<th rowspan=2>Description</th>\n";      
        
        my $headerdisplay;
        $headerdisplay = ($dset->{DETS}->{BNEWS}->getStyle() eq "pooled" ? "Occ." : "Term") if($display_bnews);
        $headerdisplay = ($dset->{DETS}->{CTS}->getStyle() eq "pooled" ? "Occ." : "Term") if($display_cts);
        $headerdisplay = ($dset->{DETS}->{CONFMTG}->getStyle() eq "pooled" ? "Occ." : "Term") if($display_confmtg);
        
        print OUTPUT_INDEX "<th colspan=2>$headerdisplay Weighted</th>\n";
        print OUTPUT_INDEX "<th rowspan=2>P(Fa)</th>\n";
        print OUTPUT_INDEX "<th rowspan=2>P(Miss)</th>\n";
        print OUTPUT_INDEX "<th rowspan=2>Decision<br>Score</th>\n";
        print OUTPUT_INDEX "<th rowspan=2>DET Curve</th>\n";
        print OUTPUT_INDEX "<th rowspan=2>Threshold Plot</th>\n";
        print OUTPUT_INDEX "</tr>\n";
        
        print OUTPUT_INDEX "<tr bgcolor=#A2C0DF>\n";
        print OUTPUT_INDEX "<th>Max Value</th>\n";
        print OUTPUT_INDEX "<th>Actual Value</th>\n";
        print OUTPUT_INDEX "</tr>\n";
        
        if($display_bnews)
        {
            if ($dset->{DETS}->{BNEWS}->successful()) 
            {
                my $maxvaluedisplay = sprintf("%.4f", $dset->{DETS}->{BNEWS}->getMaxValueValue());
                my $pfadisplay = sprintf("%.5f", $dset->{DETS}->{BNEWS}->getMaxValuePFA());
                my $pmissdisplay = sprintf("%.3f", $dset->{DETS}->{BNEWS}->getMaxValuePMiss());
                my $decisiondisplay = sprintf("%.8f", $dset->{DETS}->{BNEWS}->getMaxValueDetectionScore());
                
                print OUTPUT_INDEX "<tr align=center>\n";
                print OUTPUT_INDEX "<TH bgcolor=#DADADA>BNEWS</TH>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$maxvaluedisplay</TD>\n";
                
                my $displayactual = sprintf("%.4f", ($dset->{DETS}->{BNEWS}->getStyle() eq "pooled" ? $stats->{TOTAL}{BNEWS}{VALUE} : $stats->{MEAN}{BNEWS}{TERMWEIGHTEDVALUE}));
                
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$displayactual</TD>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$pfadisplay</TD>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$pmissdisplay</TD>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$decisiondisplay</TD>\n";
                
                my $DETpngdisplay = $dset->{DETS}->{BNEWS}->getDETPng();
                $DETpngdisplay =~ s/^.+\///;
                
                my $Threshdisplay = $dset->{DETS}->{BNEWS}->getThreshPng();
                $Threshdisplay =~ s/^.+\///;
                print OUTPUT_INDEX "<TD><A target=\"_blank\" href=\"$DETpngdisplay\">DET</a></TD>\n";
                print OUTPUT_INDEX "<TD><A target=\"_blank\" href=\"$Threshdisplay\">Threshold</a></TD>\n";
                print OUTPUT_INDEX "</tr>\n";
                
                $datahiddenreport{BNEWS} .= "<mtwv>$maxvaluedisplay</mtwv>" if($dset->{DETS}->{BNEWS}->getStyle() ne "pooled");
                $datahiddenreport{BNEWS} .= "<atwv>$displayactual</atwv>";
                $datahiddenreport{BNEWS} .= "<twdet>$DETpngdisplay</twdet>";
                
                my $serialized = $dset->{DETS}->{BNEWS}->getSerializedDET();
                $serialized =~ s/^.+\///;
                $datahiddenreport{BNEWS} .= "<srldet>$serialized</srldet>";
            }
            else
            {
                print OUTPUT_INDEX "<tr align=center>\n";
                print OUTPUT_INDEX "<TH bgcolor=#DADADA>BNEWS</TH>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";		
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";
                print OUTPUT_INDEX "<TD>N/A</TD>\n";
                print OUTPUT_INDEX "<TD>N/A</TD>\n";
                print OUTPUT_INDEX "</tr>\n";
                $datahiddenreport{BNEWS} .= "<mtwv>N/A</mtwv>" if($dset->{DETS}->{BNEWS}->getStyle() ne "pooled");
                $datahiddenreport{BNEWS} .= "<atwv>N/A</atwv>";
                $datahiddenreport{BNEWS} .= "<twdet>N/A</twdet>";
                $datahiddenreport{BNEWS} .= "<srldet>N/A</srldet>";
            }
        }
        
        if($display_cts)
        {
            if ($dset->{DETS}->{CTS}->successful()) 
            {
                my $maxvaluedisplay = sprintf("%.4f", $dset->{DETS}->{CTS}->getMaxValueValue());
                my $pfadisplay = sprintf("%.5f", $dset->{DETS}->{CTS}->getMaxValuePFA());
                my $pmissdisplay = sprintf("%.3f", $dset->{DETS}->{CTS}->getMaxValuePMiss());
                my $decisiondisplay = sprintf("%.8f", $dset->{DETS}->{CTS}->getMaxValueDetectionScore());
                
                print OUTPUT_INDEX "<tr align=center>\n";
                print OUTPUT_INDEX "<TH bgcolor=#DADADA>CTS</TH>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$maxvaluedisplay</TD>\n";
                
                my $displayactual = sprintf("%.4f", ($dset->{DETS}->{CTS}->getStyle() eq "pooled" ? $stats->{TOTAL}{CTS}{VALUE} : $stats->{MEAN}{CTS}{TERMWEIGHTEDVALUE}));
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$displayactual</TD>\n";
                
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$pfadisplay</TD>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$pmissdisplay</TD>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$decisiondisplay</TD>\n";
                
                my $DETpngdisplay = $dset->{DETS}->{CTS}->getDETPng();
                $DETpngdisplay =~ s/^.+\///;
                
                my $Threshdisplay = $dset->{DETS}->{CTS}->getThreshPng();
                $Threshdisplay =~ s/^.+\///;
                
                print OUTPUT_INDEX "<TD><A target=\"_blank\" href=\"$DETpngdisplay\">DET</a></TD>\n";
                print OUTPUT_INDEX "<TD><A target=\"_blank\" href=\"$Threshdisplay\">Threshold</a></TD>\n";
                print OUTPUT_INDEX "</tr>\n";
                
                $datahiddenreport{CTS} .= "<mtwv>$maxvaluedisplay</mtwv>" if($dset->{DETS}->{CTS}->getStyle() ne "pooled");
                $datahiddenreport{CTS} .= "<atwv>$displayactual</atwv>";
                $datahiddenreport{CTS} .= "<twdet>$DETpngdisplay</twdet>";
                
                my $serialized = $dset->{DETS}->{CTS}->getSerializedDET();
                $serialized =~ s/^.+\///;
                $datahiddenreport{CTS} .= "<srldet>$serialized</srldet>";
            }
            else
            {
                print OUTPUT_INDEX "<tr align=center>\n";
                print OUTPUT_INDEX "<TH bgcolor=#DADADA>CTS</TH>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";		
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";
                print OUTPUT_INDEX "<TD>N/A</TD>\n";
                print OUTPUT_INDEX "<TD>N/A</TD>\n";
                print OUTPUT_INDEX "</tr>\n";
                $datahiddenreport{CTS} .= "<mtwv>N/A</mtwv>" if($dset->{DETS}->{CTS}->getStyle() ne "pooled");
                $datahiddenreport{CTS} .= "<atwv>N/A</atwv>";
                $datahiddenreport{CTS} .= "<twdet>N/A</twdet>";
                $datahiddenreport{CTS} .= "<srldet>N/A</srldet>";
            }
        }

        if($display_confmtg)
        {
            if ($dset->{DETS}->{CONFMTG}->successful()) 
            {
                my $maxvaluedisplay = sprintf("%.4f", $dset->{DETS}->{CONFMTG}->getMaxValueValue());
                my $pfadisplay = sprintf("%.5f", $dset->{DETS}->{CONFMTG}->getMaxValuePFA());
                my $pmissdisplay = sprintf("%.3f", $dset->{DETS}->{CONFMTG}->getMaxValuePMiss());
                my $decisiondisplay = sprintf("%.8f", $dset->{DETS}->{CONFMTG}->getMaxValueDetectionScore());
                
                print OUTPUT_INDEX "<tr align=center>\n";
                print OUTPUT_INDEX "<TH bgcolor=#DADADA>CONFMTG</TH>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$maxvaluedisplay</TD>\n";
                
                my $displayactual = sprintf("%.4f", ($dset->{DETS}->{CONFMTG}->getStyle() eq "pooled" ? $stats->{TOTAL}{CONFMTG}{VALUE} : $stats->{MEAN}{CONFMTG}{TERMWEIGHTEDVALUE}));
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$displayactual</TD>\n";
                
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$pfadisplay</TD>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$pmissdisplay</TD>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$decisiondisplay</TD>\n";
                
                my $DETpngdisplay = $dset->{DETS}->{CONFMTG}->getDETPng();
                $DETpngdisplay =~ s/^.+\///;
                
                my $Threshdisplay = $dset->{DETS}->{CONFMTG}->getThreshPng();
                $Threshdisplay =~ s/^.+\///;
                
                print OUTPUT_INDEX "<TD><A target=\"_blank\" href=\"$DETpngdisplay\">DET</a></TD>\n";
                print OUTPUT_INDEX "<TD><A target=\"_blank\" href=\"$Threshdisplay\">Threshold</a></TD>\n";
                print OUTPUT_INDEX "</tr>\n";
                
                $datahiddenreport{CONFMTG} .= "<mtwv>$maxvaluedisplay</mtwv>" if($dset->{DETS}->{CONFMTG}->getStyle() ne "pooled");
                $datahiddenreport{CONFMTG} .= "<atwv>$displayactual</atwv>";
                $datahiddenreport{CONFMTG} .= "<twdet>$DETpngdisplay</twdet>";
                
                my $serialized = $dset->{DETS}->{CONFMTG}->getSerializedDET();
                $serialized =~ s/^.+\///;
                $datahiddenreport{CONFMTG} .= "<srldet>$serialized</srldet>";
            }
            else
            {
                print OUTPUT_INDEX "<tr align=center>\n";
                print OUTPUT_INDEX "<TH bgcolor=#DADADA>CONFMTG</TH>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";		
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";
                print OUTPUT_INDEX "<TD>N/A</TD>\n";
                print OUTPUT_INDEX "<TD>N/A</TD>\n";
                print OUTPUT_INDEX "</tr>\n";
                $datahiddenreport{CONFMTG} .= "<mtwv>N/A</mtwv>" if($dset->{DETS}->{CONFMTG}->getStyle() ne "pooled");
                $datahiddenreport{CONFMTG} .= "<atwv>N/A</atwv>";
                $datahiddenreport{CONFMTG} .= "<twdet>N/A</twdet>";
                $datahiddenreport{CONFMTG} .= "<srldet>N/A</srldet>";
            }
        }
        
        if($display_all)
        {
            if ($dset->{DETS}->{ALL}->successful()) 
            {
                my $maxvaluedisplay = sprintf("%.4f", $dset->{DETS}->{ALL}->getMaxValueValue());
                my $pfadisplay = sprintf("%.5f", $dset->{DETS}->{ALL}->getMaxValuePFA());
                my $pmissdisplay = sprintf("%.3f", $dset->{DETS}->{ALL}->getMaxValuePMiss());
                my $decisiondisplay = sprintf("%.8f", $dset->{DETS}->{ALL}->getMaxValueDetectionScore());
                
                print OUTPUT_INDEX "<tr align=center>\n";
                print OUTPUT_INDEX "<TH bgcolor=#DADADA>ALL</TH>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$maxvaluedisplay</TD>\n";
                
                my $displayactual = sprintf("%.4f", ($dset->{DETS}->{ALL}->getStyle() eq "pooled" ? $stats->{TOTAL}{ALL}{VALUE} : $stats->{MEAN}{ALL}{TERMWEIGHTEDVALUE}));
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$displayactual</TD>\n";
                
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$pfadisplay</TD>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$pmissdisplay</TD>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$decisiondisplay</TD>\n";
                
                my $DETpngdisplay = $dset->{DETS}->{ALL}->getDETPng();
                $DETpngdisplay =~ s/^.+\///;
                
                my $Threshdisplay = $dset->{DETS}->{ALL}->getThreshPng();
                $Threshdisplay =~ s/^.+\///;
                
                print OUTPUT_INDEX "<TD><A target=\"_blank\" href=\"$DETpngdisplay\">DET</a></TD>\n";
                print OUTPUT_INDEX "<TD><A target=\"_blank\" href=\"$Threshdisplay\">Threshold</a></TD>\n";
                print OUTPUT_INDEX "</tr>\n";
                
                $datahiddenreport{ALL} .= "<mtwv>$maxvaluedisplay</mtwv>" if($dset->{DETS}->{ALL}->getStyle() ne "pooled");
                $datahiddenreport{ALL} .= "<atwv>$displayactual</atwv>";
                $datahiddenreport{ALL} .= "<twdet>$DETpngdisplay</twdet>";
                
                my $serialized = $dset->{DETS}->{ALL}->getSerializedDET();
                $serialized =~ s/^.+\///;
                $datahiddenreport{ALL} .= "<srldet>$serialized</srldet>";
            }
            else
            {
                print OUTPUT_INDEX "<tr align=center>\n";
                print OUTPUT_INDEX "<TH bgcolor=#DADADA>ALL</TH>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";		
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";
                print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";
                print OUTPUT_INDEX "<TD>N/A</TD>\n";
                print OUTPUT_INDEX "<TD>N/A</TD>\n";
                print OUTPUT_INDEX "</tr>\n";
                $datahiddenreport{ALL} .= "<mtwv>N/A</mtwv>" if($dset->{DETS}->{ALL}->getStyle() ne "pooled");
                $datahiddenreport{ALL} .= "<atwv>N/A</atwv>";
                $datahiddenreport{ALL} .= "<twdet>N/A</twdet>";
                $datahiddenreport{ALL} .= "<srldet>N/A</srldet>";
            }
        }
        
        print OUTPUT_INDEX "</tr>\n</table>\n";
    }
    
    print OUTPUT_INDEX "<hr>\n";
    
    print OUTPUT_INDEX "</body>\n";
    print OUTPUT_INDEX "</html>\n";
    
    print OUTPUT_INDEX "<!-- ";
    print OUTPUT_INDEX "<report>";
    print OUTPUT_INDEX "$datahiddenreport{GLOBAL}";
    print OUTPUT_INDEX "<bnews>$datahiddenreport{BNEWS}</bnews>" if($datahiddenreport{BNEWS});
    print OUTPUT_INDEX "<cts>$datahiddenreport{CTS}</cts>" if($datahiddenreport{CTS});
    print OUTPUT_INDEX "<confmtg>$datahiddenreport{CONFMTG}</confmtg>" if($datahiddenreport{CONFMTG});
    print OUTPUT_INDEX "<all>$datahiddenreport{ALL}</all>" if($datahiddenreport{ALL});
    print OUTPUT_INDEX "</report>";
    print OUTPUT_INDEX " -->\n";
    
    close OUTPUT_INDEX;
}

sub ReportConditionalHTML
{
    my ($self, $output, $stats, $dset) = @_;
    
    open(OUTPUT_INDEX, ($self->{STD}->{LANGUAGE} eq "mandarin") ? ">:encoding(gb2312)" : ">:encoding(utf8)", "$output/index.html") or die "cannot open '$output/index.html'";
    
    my @all_TermSet;
    my @all_SourcetypeSet;
    
    my $nbrTermSet = 0;
    my $nbrSourcetypeSet = 0;
    
    foreach my $termset(sort keys %{ $stats })
    {
        next if($termset eq "TOTAL" || $termset eq "MEAN" || $termset eq "COEFF");
        push (@all_TermSet, $termset);
        $nbrTermSet += 1;
    }
    
    foreach my $sourcetypeset(sort keys %{ $stats->{TOTAL} })
    {
        next if($sourcetypeset eq "SEARCH_TIME" || $sourcetypeset eq "ALL");
        push (@all_SourcetypeSet, $sourcetypeset);
        $nbrSourcetypeSet += 1;
    }
    
    my %datahiddenreport;
    $datahiddenreport{GLOBAL} = "";
    
    if($self->{STD}->{LANGUAGE} eq "mandarin")
    {
        print OUTPUT_INDEX "<?xml version=\"1.0\" encoding=\"GB2312\"?>\n";
    }
    else
    {
        print OUTPUT_INDEX "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
    }
    
    print OUTPUT_INDEX "<html>\n";
    print OUTPUT_INDEX "<head>\n";
    print OUTPUT_INDEX "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=gb2312\" />\n" if($self->{STD}->{LANGUAGE} eq "mandarin");
    print OUTPUT_INDEX "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />\n" if($self->{STD}->{LANGUAGE} ne "mandarin");
    print OUTPUT_INDEX "<title>$self->{STD}->{SYSTEM_ID}</title>\n";    
    print OUTPUT_INDEX "</head>\n";
    print OUTPUT_INDEX "<body leftmargin=0 topmargin=0 marginwidth=0 marginheight=0>\n";
    print OUTPUT_INDEX "<table align=center bgcolor=#fefefe border=0>\n";
    print OUTPUT_INDEX "<tr valign=top>\n";
    print OUTPUT_INDEX "<td>\n"; 
    print OUTPUT_INDEX "<table>\n";
    
    my $indexingtimedisplay = sprintf("%.2f", $self->{STD}->{INDEXING_TIME});
    print OUTPUT_INDEX "<tr><td>Indexing Time: </td><td> $indexingtimedisplay</td></tr>\n";
    print OUTPUT_INDEX "<tr><td>Language: </td><td> $self->{STD}->{LANGUAGE}</td></tr>\n";
    
    $datahiddenreport{GLOBAL} .= "<language>$self->{STD}->{LANGUAGE}</language>";
    
    print OUTPUT_INDEX "<tr><td>Index size: </td><td> $self->{STD}->{INDEX_SIZE}</td></tr>\n";
    
    $datahiddenreport{GLOBAL} .= "<index_size>$self->{STD}->{INDEX_SIZE}</index_size>";
    
    print OUTPUT_INDEX "<tr><td>System ID: </td><td> $self->{STD}->{SYSTEM_ID}</td></tr>\n";
    
    $datahiddenreport{GLOBAL} .= "<system_id>$self->{STD}->{SYSTEM_ID}</system_id>";
    
    print OUTPUT_INDEX "<tr><td>Coefficient C: </td><td> ".sprintf("%.4f",$stats->{COEFF}{KOEFC})."</td></tr>\n";
    print OUTPUT_INDEX "<tr><td>Coefficient V: </td><td> ".sprintf("%.4f",$stats->{COEFF}{KOEFV})."</td></tr>\n";
    print OUTPUT_INDEX "<tr><td>Trials Per Second: </td><td> ".sprintf("%.4f",$stats->{COEFF}{TRIALSPERSEC})."</td></tr>\n";
    print OUTPUT_INDEX "<tr><td>Probability of a Term: </td><td> ".sprintf("%.4f",$stats->{COEFF}{PROBOFTERM})."</td></tr>\n";
    
    my $minmaxdecstr = "";
    
    if ($self->{STD}->{MIN_YES} >= $self->{STD}->{MAX_NO})
    {
        $minmaxdecstr = "OK";
    }
    else
    {
        $minmaxdecstr = "Inconsistent";
    }
    
    print OUTPUT_INDEX "<tr><td>Decision Score: </td><td> ".sprintf("%s (Max NO: %.4f, Min YES: %.4f)", $minmaxdecstr, $self->{STD}->{MAX_NO}, $self->{STD}->{MIN_YES})."</td></tr>\n";
    
    print OUTPUT_INDEX "</table>\n";
    print OUTPUT_INDEX "<table width=100% border=0>\n";
    
    print OUTPUT_INDEX "<tr bgcolor=#A2C0DF>\n";
    print OUTPUT_INDEX "<td colspan=2 align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF><b>TermSets</b></font></td>\n";
    
    foreach my $sourcetype(sort @all_SourcetypeSet)
    {
        if($sourcetype eq "")
        {
            print OUTPUT_INDEX "<td colspan=9 align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF><b>All Source Types</b></font></td>\n";
        }
        else
        {
            print OUTPUT_INDEX "<td colspan=9 align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF><b>$sourcetype</b></font></td>\n";
        }
    }
    
    print OUTPUT_INDEX "</tr>\n";
            
    print OUTPUT_INDEX "<tr bgcolor=#A2C0DF>\n";
    print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF><b>TermSet</b></font></td>\n";
    print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF><b>Search Time</b></font></td>\n";
    
    foreach my $sourcetype(sort @all_SourcetypeSet)
    {
        $datahiddenreport{$sourcetype} = "";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>Ref</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>Corr</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>FA</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>Miss</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>Occ.<BR>Value</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>P(FA)</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>P(Miss)</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>Nbr<br>Trials</font></td>\n";
        print OUTPUT_INDEX "<td align=center bgcolor=#A2C0DF><font face=\"Verdana, Arial, Helvetica, sans-serif\" color=#FFFFFF>TW<br>Value</font></td>\n";
    }
        
    print OUTPUT_INDEX "</tr>\n";
    
    
    foreach my $termset(sort @all_TermSet)
    {
        print OUTPUT_INDEX "<tr>\n";
        
        print OUTPUT_INDEX "<td bgcolor=#DADADA><font face=\"Verdana, Arial, Helvetica, sans-serif\">$termset</font></td>\n";
        
        my $display_searchtime = sprintf("%.2f", $stats->{$termset}{SEARCH_TIME});
        
        print OUTPUT_INDEX "<td bgcolor=#DADADA align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\">$display_searchtime</font></td>\n";
        
        foreach my $sourcetype(sort @all_SourcetypeSet)
        {
            my $display_ref = $stats->{$termset}{$sourcetype}{REF};
            my $display_corr = $stats->{$termset}{$sourcetype}{CORR};
            my $display_fa = $stats->{$termset}{$sourcetype}{FA};
            my $display_miss = $stats->{$termset}{$sourcetype}{MISS};
            my $display_Pfa = (($stats->{$termset}{$sourcetype}{PFA} != -1000.0) ? sprintf("%.5f", $stats->{$termset}{$sourcetype}{PFA}) : "N/A");
            my $display_Pmiss = (($stats->{$termset}{$sourcetype}{PMISS} != -1000.0) ? sprintf("%.3f", $stats->{$termset}{$sourcetype}{PMISS}) : "N/A");
            my $display_NbrTrials = sprintf("%7d", $stats->{$termset}{$sourcetype}{NUMTRIALS});
            my $display_TWValue = sprintf("%.3f", $stats->{$termset}{$sourcetype}{TERMWEIGHTEDVALUE});
            my $display_value = (($stats->{$termset}{$sourcetype}{VALUE} != -1000.0) ? sprintf("%.3f", $stats->{$termset}{$sourcetype}{VALUE}) : "N/A");
            
            print OUTPUT_INDEX "<td bgcolor=#EEEEEE align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$display_ref</font></td>\n";
            print OUTPUT_INDEX "<td bgcolor=#EEEEEE align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$display_corr</font></td>\n";
            print OUTPUT_INDEX "<td bgcolor=#EEEEEE align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$display_fa</font></td>\n";
            print OUTPUT_INDEX "<td bgcolor=#EEEEEE align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$display_miss</font></td>\n";
            print OUTPUT_INDEX "<td bgcolor=#EEEEEE align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$display_value</font></td>\n";
            print OUTPUT_INDEX "<td bgcolor=#EEEEEE align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$display_Pfa</font></td>\n";
            print OUTPUT_INDEX "<td bgcolor=#EEEEEE align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$display_Pmiss</font></td>\n";
            print OUTPUT_INDEX "<td bgcolor=#EEEEEE align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$display_NbrTrials</font></td>\n";
            print OUTPUT_INDEX "<td bgcolor=#EEEEEE align=center><font face=\"Verdana, Arial, Helvetica, sans-serif\" size=-1>$display_TWValue</font></td>\n";
        }
        
        print OUTPUT_INDEX "</tr>\n";
    }   

    print OUTPUT_INDEX "</table>\n";
    print OUTPUT_INDEX "</td>\n";
    print OUTPUT_INDEX "</tr>\n";
    print OUTPUT_INDEX "</table>\n";
    
    if ($dset->hasDETs())
    {
        print OUTPUT_INDEX "\n";
        $dset->writeMultiDET("$output/DET");
        
        my $purged_filename = $dset->{COMBINED_DET_PNG};
        $purged_filename =~ s/^.+\///;
        $datahiddenreport{GLOBAL} .= "<combined_det_png>$purged_filename</combined_det_png>";
        
        print OUTPUT_INDEX "<hr>\n";
        print OUTPUT_INDEX "<table border=0>\n";
        print OUTPUT_INDEX "<tr bgcolor=#A2C0DF>\n";
        print OUTPUT_INDEX "<th colspan=8 align=center>DET Curve Analysis Summary<br><img src=\"$purged_filename\" alt=\"Combined DET Plot\"/></th></tr>\n";
        print OUTPUT_INDEX "<tr bgcolor=#A2C0DF>\n";
        print OUTPUT_INDEX "<th rowspan=2>Description</th>\n";
        print OUTPUT_INDEX "<th colspan=2>Term Weighted</th>\n";
        print OUTPUT_INDEX "<th rowspan=2>P(Fa)</th>\n";
        print OUTPUT_INDEX "<th rowspan=2>P(Miss)</th>\n";
        print OUTPUT_INDEX "<th rowspan=2>Decision<br>Score</th>\n";
        print OUTPUT_INDEX "<th rowspan=2>DET Curve</th>\n";
        print OUTPUT_INDEX "<th rowspan=2>Threshold Plot</th>\n";
        print OUTPUT_INDEX "</tr>\n";
        
        print OUTPUT_INDEX "<tr bgcolor=#A2C0DF>\n";
        print OUTPUT_INDEX "<th>Max Value</th>\n";
        print OUTPUT_INDEX "<th>Actual Value</th>\n";
        print OUTPUT_INDEX "</tr>\n";
        
        foreach my $termset(sort @all_TermSet)
        {
            foreach my $sourcetype (sort @all_SourcetypeSet)
            {
                my $titledetset = "$termset $sourcetype";
                my $displayNAs = 0;
                
                $displayNAs = 1 if ( !$dset->{DETS}->{$titledetset} );

                if(!$displayNAs && $dset->{DETS}->{$titledetset}->successful())
                {
                    my $maxvaluedisplay = sprintf("%.4f", $dset->{DETS}->{$titledetset}->getMaxValueValue());
                    my $pfadisplay = sprintf("%.5f", $dset->{DETS}->{$titledetset}->getMaxValuePFA());
                    my $pmissdisplay = sprintf("%.3f", $dset->{DETS}->{$titledetset}->getMaxValuePMiss());
                    my $decisiondisplay = sprintf("%.8f", $dset->{DETS}->{$titledetset}->getMaxValueDetectionScore());
                    
                    print OUTPUT_INDEX "<tr align=center>\n";
                    print OUTPUT_INDEX "<TH bgcolor=#DADADA>$titledetset</TH>\n";
                    print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$maxvaluedisplay</TD>\n";
                    
                    my $displayactual = sprintf("%.4f", ($dset->{DETS}->{$titledetset}->getStyle() eq "pooled" ? $stats->{$termset}{$sourcetype}{VALUE} : $stats->{$termset}{$sourcetype}{TERMWEIGHTEDVALUE}));
                    
                    print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$displayactual</TD>\n";
                    print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$pfadisplay</TD>\n";
                    print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$pmissdisplay</TD>\n";
                    print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>$decisiondisplay</TD>\n";
                    
                    my $DETpngdisplay = $dset->{DETS}->{$titledetset}->getDETPng();
                    $DETpngdisplay =~ s/^.+\///;
                    
                    my $Threshdisplay = $dset->{DETS}->{$titledetset}->getThreshPng();
                    $Threshdisplay =~ s/^.+\///;
                    print OUTPUT_INDEX "<TD><A target=\"_blank\" href=\"$DETpngdisplay\">DET</a></TD>\n";
                    print OUTPUT_INDEX "<TD><A target=\"_blank\" href=\"$Threshdisplay\">Threshold</a></TD>\n";
                    print OUTPUT_INDEX "</tr>\n";
                    
                    $datahiddenreport{$titledetset} .= "<mtwv>$maxvaluedisplay</mtwv>" if($dset->{DETS}->{$titledetset}->getStyle() ne "pooled");
                    $datahiddenreport{$titledetset} .= "<atwv>$displayactual</atwv>";
                    $datahiddenreport{$titledetset} .= "<twdet>$DETpngdisplay</twdet>";
                    
                    my $serialized = $dset->{DETS}->{$titledetset}->getSerializedDET();
                    $serialized =~ s/^.+\///;
                    $datahiddenreport{$titledetset} .= "<srldet>$serialized</srldet>";
                }
                
                if($displayNAs)
                {
                    print OUTPUT_INDEX "<tr align=center>\n";
                    print OUTPUT_INDEX "<TH bgcolor=#DADADA>$titledetset</TH>\n";
                    print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";		
                    print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";
                    print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";
                    print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";
                    print OUTPUT_INDEX "<TD bgcolor=#EEEEEE>N/A</TD>\n";
                    print OUTPUT_INDEX "<TD>N/A</TD>\n";
                    print OUTPUT_INDEX "<TD>N/A</TD>\n";
                    print OUTPUT_INDEX "</tr>\n";
                    $datahiddenreport{$titledetset} .= "<mtwv>N/A</mtwv>";
                    $datahiddenreport{$titledetset} .= "<atwv>N/A</atwv>";
                    $datahiddenreport{$titledetset} .= "<twdet>N/A</twdet>";
                    $datahiddenreport{$titledetset} .= "<srldet>N/A</srldet>";
                }
            }
        }
                
        print OUTPUT_INDEX "</tr>\n</table>\n";
    }
    
    print OUTPUT_INDEX "<hr>\n";
    
    print OUTPUT_INDEX "</body>\n";
    print OUTPUT_INDEX "</html>\n";
    
    print OUTPUT_INDEX "<!-- ";
    print OUTPUT_INDEX "<conditional_report>";
    print OUTPUT_INDEX "$datahiddenreport{GLOBAL}";
    
    foreach my $termset(sort @all_TermSet)
    {
        foreach my $sourcetype (sort @all_SourcetypeSet)
        {
            my $titledetset = "$termset $sourcetype";
            print OUTPUT_INDEX "<termset><name>$titledetset</name>$datahiddenreport{$titledetset}</termset>"
        }
    }
    
    print OUTPUT_INDEX "</conditional_report>";
    print OUTPUT_INDEX " -->\n";
    
    close OUTPUT_INDEX;
}

sub GenerateDETReport
{
    my ($self, $filter_termsIDs, $filter_filechannels, $filter_types, $lineTitle, $KoefC, $KoefV, $trialsPerSec, $probOfTerm, $pooledTermDETs) = @_;

    my $sysMinScore = 9e99;

    my $trial = new Trials("Term Detection", "Term", "Occurrence");
    
    my %filechantype;

    my $signalDuration = 0.0;
    
    for (my $i=0; $i<@{ $self->{ECF}->{EXCERPT} }; $i++)
    {
        $filechantype{$self->{ECF}->{EXCERPT}[$i]->{FILE}}{$self->{ECF}->{EXCERPT}[$i]->{CHANNEL}} = uc($self->{ECF}->{EXCERPT}[$i]->{SOURCE_TYPE});
	
        next if(!PairInList($filter_filechannels, $self->{ECF}->{EXCERPT}[$i]->{FILE},$self->{ECF}->{EXCERPT}[$i]->{CHANNEL}));

        if ($self->{ECF}->{EXCERPT}[$i]->{CHANNEL} == 1)
        {
            next if(!EltInList($filter_types, uc($self->{ECF}->{EXCERPT}[$i]->{SOURCE_TYPE})));
            $signalDuration += $self->{ECF}->{EXCERPT}[$i]->{DUR};
        }
    }
    
    foreach my $termid(sort keys %{ $self->{MAPPINGS} } )
    {
        next if(!EltInList($filter_termsIDs, $termid));
            
        for(my $i=0; $i<@{ $self->{MAPPINGS}->{$termid}{MAPPED} }; $i++)
        {
            my $file = $self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{FILE};
            my $channel = $self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{CHAN};
            
            next if(!PairInList($filter_filechannels, $file, $channel));
            
            my $type = $filechantype{$file}{$channel};
            
            next if(!EltInList($filter_types, $type));
            
            $trial->addTrial($termid, $self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{SCORE}, $self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{DECISION}, 1);

            if ($self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{SCORE} < $sysMinScore)
            {
                $sysMinScore = $self->{MAPPINGS}->{$termid}{MAPPED}[$i][0]->{SCORE} 
            }	    
        }
        
        for(my $i=0; $i<@{ $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS} }; $i++)
        {
            my $file = $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{FILE};
            my $channel = $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{CHAN};
            
            next if(!PairInList($filter_filechannels, $file, $channel));
            
            my $type = $filechantype{$file}{$channel};
            
            next if(!EltInList($filter_types, $type));
            
            $trial->addTrial($termid, $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{SCORE}, $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{DECISION}, 0);

            if ($self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{SCORE} < $sysMinScore)
            {
                $sysMinScore = $self->{MAPPINGS}->{$termid}{UNMAPPED_SYS}[$i]->{SCORE};
            }	    
        }
        
        for(my $i=0; $i<@{ $self->{MAPPINGS}->{$termid}{UNMAPPED_REF} }; $i++)
        {
            my $file = $self->{MAPPINGS}->{$termid}{UNMAPPED_REF}[$i]->{FILE};
            my $channel = $self->{MAPPINGS}->{$termid}{UNMAPPED_REF}[$i]->{CHAN};
            
            next if(!PairInList($filter_filechannels, $file, $channel));
            
            my $type = $filechantype{$file}{$channel};
            
            next if(!EltInList($filter_types, $type));
            
            $trial->addTrial($termid, $sysMinScore, "OMITTED", 1);
        }      
    }
    
    $trial->setPooledTotalTrials(sprintf("%.0f",$trialsPerSec * $signalDuration));
    
    return(new DETCurve($trial, $pooledTermDETs ? "pooled" : "blocked", undef, $lineTitle, $KoefC, $KoefV, $probOfTerm));
}

sub MergeDETs
{
    my($self, $all_dets) = @_;
    
    my $murged_dets;
    
    # TODO: Merged the dets contained in the list $all_dets (Jon)
    
    return($murged_dets);
}

sub DETReport
{
    my ($self, $output, $det) = @_;
    
    $det->writeGNUGraph($output);
}

sub EltInList
{
    # return 1 if Elt is in List or if the list is empty, unless 0
    my($List, $Elt) = @_;
    
    if(@{ $List })
    {
        for(my $i=0; $i<@{ $List }; $i++)
        {
            return(1) if($Elt =~ /$List->[$i]/i);
        }
        
        return(0);
    }
    else
    {
        return(1);
    }
}

sub PairInList
{
    # return 1 if Elt is in List or if the list is empty, unless 0
    my($List, $File, $Channel) = @_;
    
    if(@{ $List })
    {
        for(my $i=0; $i<@{ $List }; $i++)
        {
            return(1) if( ($File =~ /$List->[$i][0]/i) && ($List->[$i][1] eq $Channel) );
        }
        
        return(0);
    }
    else
    {
        return(1);
    }
}

1;


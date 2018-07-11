# STDEval
# STDTermRecord.pm
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

package STDTermRecord;
use strict;

sub new
{
    my $class = shift;
    my $self = {};

    $self->{FILE} = shift;
    $self->{CHAN} = shift;
    $self->{BT} = shift;
    $self->{DUR} = shift;
    $self->{ET} = $self->{BT} + $self->{DUR};
    $self->{MID} = $self->{BT} + ($self->{DUR} / 2.0);
    $self->{SCORE} = shift;
    $self->{DECISION} = shift;
        
    bless $self;
    return $self;
}

sub toString
{
    my $self = shift;
    my $s = "STDTermRecord: ".
	" FILE=".$self->{FILE}.
	" CHAN=".$self->{CHAN}.
	" BT=".$self->{BT}.
	" MID=".$self->{MID}.
	" ET=".$self->{ET}.
	" SCORE=".$self->{SCORE}.
	" DECISION=".$self->{DECISION};
}

1;

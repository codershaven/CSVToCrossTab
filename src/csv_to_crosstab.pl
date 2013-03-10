#!/usr/bin/perl

################################################################################
#
# Copyright(c) 2013 - CodersHaven.net
#
# Name: 	csv_to_crosstab.pl
# Author:	CodersHaven.net
# Email:	ch.lab@codershaven.net
# Description:	This program is a simple program to convert a CSV file to a
#		cross tab CSV file.
#
################################################################################

use lib "$ENV{'HOME'}/codershaven.net/lib/";

# DO NOT MODIFY PASSED HERE

use FileReader;
use strict;
use Getopt::Std;

our($opt_f, $opt_r, $opt_n, $opt_m, $opt_c, $opt_v, $opt_s, $opt_F);

getopts('f:r:m:c:sF:n:v:');

sub process($);
sub processCSV($);
sub usage($);

# Perform some validation.

if(length($opt_f) == 0 || length($opt_r) == 0 || length($opt_n) == 0 || 
	length($opt_c) == 0 || length($opt_v) == 0 || length($opt_F) == 0)
{
	usage(1);
}

if(($opt_r eq $opt_v) || ($opt_r eq $opt_c) ||
	($opt_c eq $opt_v))
{
	print STDERR "The row field index, crosstab field index and value field index cannot be equal.\n";
	exit(1);
}

if($opt_r !~ /^[\d]+$/ || $opt_r < 0)
{
	print STDERR "The row field index must be a valid number greater than or equal to zero.\n";
	exit(1);
}

if($opt_c !~ /^[\d]+$/ || $opt_c < 0)
{
	print STDERR "The crosstab field index must be a valid number greater than or equal to zero.\n";
	exit(1);
}

if($opt_v !~ /^[\d]+$/ || $opt_v < 0)
{
	print STDERR "The value field index must be a valid number greater than or equal to zero.\n";
	exit(1);
}

our %headings = ();

my $headingFile = $opt_m;
my $csvInputFile = $opt_f;
our $delimiter = $opt_F;
our $rowName = $opt_n;
our $rowIndex = $opt_r;
our $valueIndex = $opt_v;
our $crossTabIndex = $opt_c;
our %uniqueRow = ();
our %recordsByRowColumn = ();
our $skipHeading = $opt_s;

our $inDelimiter = $delimiter;

# Because the split() method uses regex, we need to escape the
# | delimiter as it will cause problems.
if($delimiter eq "|")
{
	$inDelimiter = "\\$inDelimiter";
}

# Check for crosstab heading file.
if($headingFile)
{
	my $fr = new FileReader($headingFile);
	# Open the file.
	if($fr->open() > 0)
	{
		# Pass a reference to our local process subroutine to the file reader
		# process function.
		if(!$fr->process(\&process))
		{
			print STDERR "Unable to process the file.\n";
		}

		# Close the file.
		$fr->close();
	}
	else
	{
		print STDERR "Unable to open the file $headingFile.\n";
		exit(1);
	}
}

our $figureOutHeadings = 0;

if(!keys(%headings))
{
	# Need to figure out what the unique list of heading should be.
	$figureOutHeadings = 1;
}

our $lineCount = 0;
my $fr = new FileReader($csvInputFile);

# Open the file.
if($fr->open() > 0)
{
	if(!$fr->process(\&processCSV))
	{
		print STDERR "Unable to process the file.\n";
	}

	# Close the file.
	$fr->close();

	my $printed = 0;
	foreach my $tab (sort keys(%headings))
	{
		if(!$printed)
		{
			print "$rowName$delimiter";
		}
		else
		{
			print "$delimiter";
		}

		print "$tab";
		$printed = 1;
	}

	print "\n";

	foreach my $row (sort keys(%uniqueRow))
	{
		$printed = 0;
		foreach my $tab (sort keys(%headings))
		{
			my $key = "$row-$tab";
			if(!$printed)
			{
				print "$row$delimiter";
			}
			else
			{
				print "$delimiter";
			}

			print "$recordsByRowColumn{$key}";
			$printed = 1;
		}
		print "\n";
	}
}
else
{
	print STDERR "Unable to open the file $csvInputFile.\n";
	exit(1);
}


# Heading field filter file process() method.
sub process($)
{
	my $line = shift;

	if($line ne "")
	{
		$headings{$line} = 1;
	}
}

# CSV file process() method.
sub processCSV($)
{
	my $line = shift;
	my $skipLine = 0;
	my $addRecord = 0;

	$lineCount++;

	if($skipHeading && $lineCount == 1)
	{
		$skipLine = 1;
	}

	if(!$skipLine)
	{
		my @tmp = split(/$inDelimiter/, $line);

		if(!$figureOutHeadings)
		{
			if(defined($headings{$tmp[$crossTabIndex]}))
			{
				$addRecord = 1;
			}
		}
		else
		{
			$addRecord = 1;
		}

		if($addRecord)
		{
			$headings{$tmp[$crossTabIndex]} = 1;
			$uniqueRow{$tmp[$rowIndex]} = 1;
			my $key = "$tmp[$rowIndex]-$tmp[$crossTabIndex]";

			$recordsByRowColumn{$key} = $tmp[$valueIndex];
		}
	}
}

# Usage method.
sub usage($)
{
	my $exitStatus = shift;

	print<<END;
Usage:
	$0 -f <input file> -F , -r 0 -n "date" -c 1 -v 2 [-m <heading file>, -s]

Options:
	-f	Input file name.
	-F	Field delimiter.
	-r	Display row field index.
	-n	Display row heading name.
	-c	Cross tab field index.
	-v	Value field index.
	-m	Heading filter file.
	-s	Skip input file header (line 1).
END
	exit($exitStatus);
}

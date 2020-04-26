#!/usr/bin/perl
# Copyright (c) Askari Azikin (askari.azikin@kawananu.com)
#
# Usage: perl sort_missing_number.pl input_file.xlsx output.txt  
#
# Revision:
# 22/11/2019 Askari Azikin First Draft
#
# use strict;
# use warnings;
# use Data::Dumper;
 
use Spreadsheet::Read;
use Spreadsheet::ParseXLSX;
 
usage() if ($#ARGV != 1) ;

my $workbook    = ReadData ("$ARGV[0]");
my $output_file = $ARGV[1];
my (@column_sorted) = ();
my $sheet = $workbook->[1];       # First data sheet
my @columns = $sheet->{cell}[3];  # Column 'C' 
 
foreach my $col (@columns) {
   for (@$col) {
     if (defined $_) {
         push (@column_sorted, $_) if ($_ ne "Number");
     }
   }
}
 
parse (\@column_sorted);
 
sub parse {
    my ($ref) = @_;
    (@$ref) = sort (@$ref);
    my $eci_start = $ref->[0];
    my $eci_cur   = $ref->[0];
    my %hash      = ();
    my $eci_end = 0; my $flag_skip = 0; 
 
    for my $i (1 .. $#{$ref}) {
       $flag_skip = 0;
       if ( ($ref->[$i] - $eci_cur) > 1 ) {      
           $flag_skip = 1;       
           $eci_end = $eci_cur;   
       }    
       $eci_cur = $ref->[$i];   
       if ($flag_skip) {       
          if ($eci_start eq $eci_end) {           
                push @{$hash{'event'}}, "$eci_start $eci_start";                      
                $eci_start = $eci_end = $eci_cur;       
          }       
          else {           
               push @{$hash{'event'}}, "$eci_start $eci_end";                     
               $eci_start = $eci_end = $eci_cur;       
          }  
       }   
       $eci_end = $eci_cur unless $flag_skip;   
       if ($i eq $#{$ref}) {       
           unless ($flag_skip) {           
               push @{$hash{'event'}}, "$eci_start $eci_end";       
           }       
           else {           
               push @{$hash{'event'}}, "$eci_start $eci_start";       
           }   
      }
   }
   create_script(%hash);
}
 
sub create_script {
   my (%hash_) = @_;
   my $start_point = 1;
   my %hash_reporting = ();
   open (FH, '>', $output_file) or die $!;
  
   print FH "## Special event list\n";
   foreach my $key (sort keys %hash_) {
     foreach (@{$hash_{$key}}) {
        if ($_ =~ /(\d+)\s+(\d+)/)
        {
             print FH "perl add_range -param param_tests${start_point} -first $1 -last $2\n";
             push @{$hash_reporting{'params'}},"param_tests${start_point}";
             $start_point++;
        }
     }  
   }
   print FH "\n\n## Configure special event\n";
   foreach (keys %hash_reporting){
       print FH "perl create_reporting -param 200000000 -param_tests ";
       print FH $_ for (join(",",@{$hash_reporting{$_}}))
   }
   print FH "\n";
 close(FH);
 }
 
sub usage {
print <<EOF; 
Options:
         input_file.xlsx : the excel sheet file to be parsed, use "" if there is space on the filename, or just using tab 
         output.txt      : script produced
         e.g:
         perl parse.pl "Input File list_test.xlsx" script_output.txt
EOF
 exit;
}


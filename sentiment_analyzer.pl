## usage: sentiment_analyser [pos_tweets] [neg_tweets] [unclassified_tweets]

use strict;
use warnings;


# Getting arguments
my ($pos_tweets, $neg_tweets, $unclass_tweets) = @ARGV;

if (not defined $pos_tweets or not defined $neg_tweets or not defined $unclass_tweets) {
  print "usage: sentiment_analyser [pos_tweets] [neg_tweets] [unclassified_tweets]\n";
  exit;
}


####################################
### CREATES WORD FREQUENCY LISTS ###
my $freqs = `/bin/bash create_freq_list $pos_tweets $neg_tweets`;
my $pos_freq = "pos_freq";
my $neg_freq = "neg_freq";


############################
### PUPULATES THE HASHES ###
open FILE_POS_FREQ, $pos_freq or die $!;
open FILE_NEG_FREQ, $neg_freq or die $!;

my %hash_pos;
my %hash_neg;

#POSITIVE HASH
while (my $line = <FILE_POS_FREQ>) {
  chomp($line);

  if ($line =~ /([0-9]+) (.+$)/) {
    $hash_pos{$2} = $1;
  }
}

#NEGATIVE HASH
while (my $line = <FILE_NEG_FREQ>) {
  chomp($line);

  if ($line =~ /([0-9]+) (.+$)/) {
    $hash_neg{$2} = $1;
  }
}

close FILE_POS_FREQ;
close FILE_NEG_FREQ;


#############################
### CLASSIFIES THE TWEETS ###
open FILE_UNC, $unclass_tweets or die $!;
my $results = 'results';
open(my $fh, '>', $results) or die $!;


my $pos_tweet_count = `cat $pos_tweets | wc -l`; # total positive tweets
my $neg_tweet_count = `cat $neg_tweets | wc -l`; # total negative tweets
my @words;                     # array to hold words of each tweet
my $prob_pos = 0;              # positive probability
my $prob_neg = 0;              # negative probability
my $v_pos = keys %hash_pos;    # total unique words from positive tweets
my $v_neg = keys %hash_neg;    # total unique words from negative tweets
my $alpha = 0.5;               # for smoothing
my $result;                    # classification to print to results file


# for each line, capture the line number and tweet, then split tweet into array
while (my $line = <FILE_UNC>) {
  if ($line =~ /([0-9]+)\s(.+$)/) {
    @words = split(/\s+/,$2);
  }

  foreach my $word (@words) {
   #POSITIVE
    if (exists $hash_pos{$word}) {
      $prob_pos = $prob_pos + log( ($hash_pos{$word} + $alpha) / ($pos_tweet_count + ($alpha*$v_pos)) )/log(2);
    }
    else {
      $prob_pos = $prob_pos + log( ($alpha) / ($pos_tweet_count + ($alpha*$v_pos)) )/log(2);
    }

    #NEGATIVE
    if (exists $hash_neg{$word}) { 
      $prob_neg = $prob_neg + log( ($hash_neg{$word} + $alpha) / ($neg_tweet_count + ($alpha*$v_neg)) )/log(2);
    }
    else {
      $prob_neg = $prob_neg + log( ($alpha) / ($neg_tweet_count + ($alpha*$v_neg)) )/log(2);
    }
  }

  # Compare prob_pos and prob_neg
  $result = ($prob_pos, $prob_neg)[$prob_pos < $prob_neg];
  if ($result == $prob_pos) { print $fh "P\n"; }
  else { print $fh "N\n"; }


  undef @words;
  $prob_pos = 0;
  $prob_neg = 0;
}
 

close $fh;
close FILE_UNC;
my $remove = `rm pos_freq neg_freq`;


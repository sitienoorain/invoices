#!/usr/bin/perl

use strict; 
use warnings;
use Data::Dumper;
use Template;
use JSON;
use autodie qw(:all);

# enable autoflush
$|++;

if (!defined($ARGV[0])) {
  print "Please specify invoice number to generate from data directory.\n";
  die;
}

my $id = $ARGV[0];

if ( ! -f "data/$id.json") {
  die "The file id \"$id\" does not exist!\n";
}

local $/;
open( my $fh, '<', "data/$id.json" );
my $json_text = <$fh>;
close($fh);

my $data = decode_json( $json_text );

my $tt = Template->new;

$data->{id} = $id;

my @items;

my $int = 0;
foreach my $item ( @{$data->{items}}) {
  $data->{price_total} += $item->{price};
  $data->{items}->[$int]->{descr} = pack("A60", $data->{items}->[$int]->{descr}); 
  $int++;
};

$tt->process('tt/ps_uk.tt', $data, "ps/${id}_uk.ps") or die $tt->error;
$tt->process('tt/ps_sk.tt', $data, "ps/${id}_sk.ps") or die $tt->error;

# transform to jpg
system "gs -dNOPAUSE -q -sDEVICE=jpeg -sOutputFile=out/${id}_uk.jpg -sPAPERSIZE=a4 -r200 - < ps/${id}_uk.ps";
system "gs -dNOPAUSE -q -sDEVICE=jpeg -sOutputFile=out/${id}_sk.jpg -sPAPERSIZE=a4 -r200 - < ps/${id}_sk.ps";
# transform to pdf 
system "gs -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=out/${id}_uk.pdf -sPAPERSIZE=a4 -r200 - < ps/${id}_uk.ps";
system "gs -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=out/${id}_sk.pdf -sPAPERSIZE=a4 -r200 - < ps/${id}_sk.ps";

print "Done.\n";

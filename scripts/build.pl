#!/usr/bin/perl 
use strict;
use warnings;

my %sites = (
	FR => '0.03',
	IT => '0.12',
);

die if not -d 'out';

foreach my $lang (keys %sites) {
	my $outpath = lc $lang;
	system "$^X scripts/build-perldoc-static.pl --language $outpath --output-path out/$outpath";
	system "$^X scripts/build-perldoc-html.pl --output-path out/$outpath --input-path src/POD2-$lang-$sites{$lang}/$lang --cache cache/$lang.cache";
}
system "cp -r www out/www";


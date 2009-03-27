package Perldoc::Config;

use strict;
use warnings;

our $VERSION = '0.01';


#--------------------------------------------------------------------------

our %option = (
  output_path  => '/tmp/perldoc',
  site_href    => 'http://perldoc.perl.org',
  site_title   => 'perldoc.perl.org',
  perl_version => sprintf("%vd",$^V),
  perl_source  => '/Users/jj/perl/src/perl-'.sprintf("%vd",$^V),
);

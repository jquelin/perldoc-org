package Perldoc::Config;

use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME

Perldoc::Config - Code generating the perldoc.org web site

=cut


#--------------------------------------------------------------------------

our %option = (
  site_href    => 'perldoc.org',
  site_title   => 'perldoc.org',
  perl_version => sprintf("%vd",$^V),
);

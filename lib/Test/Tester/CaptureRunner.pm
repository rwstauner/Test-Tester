# $Header: /home/fergal/my/cvs/Test-Tester/lib/Test/Tester/CaptureRunner.pm,v 1.3 2003/03/05 01:07:55 fergal Exp $
use strict;

package Test::Tester::CaptureRunner;

use Test::Tester::Capture;
require Exporter;

sub new
{
	return __PACKAGE__;
}

sub run_tests
{
	my $self = shift;

	my $test = shift;

	capture()->reset;

	&$test();
}

sub get_results
{
	return capture()->details;
}

sub get_premature
{
	return capture()->premature;
}

sub capture
{
	return Test::Tester::Capture->new;
}

__END__

=head1 NAME

Test::Tester::CaptureRunner - Help testing test modules built with Test::Builder

=head1 DESCRIPTION

This stuff if needed to allow me to play with other ways of monitoring the
test results.

=head1 AUTHOR

Copyright 2003 by Fergal Daly <fergal@esatclear.ie>.

=head1 LICENSE

Under the same license as Perl itself

See http://www.perl.com/perl/misc/Artistic.html

=cut

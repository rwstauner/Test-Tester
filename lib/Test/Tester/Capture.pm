use strict;

package Test::Tester::Capture;

use vars qw( @ISA $Result @EXPORT);
@ISA = qw( Test::Builder Exporter );
@EXPORT = qw( $Result );


sub new
{
	return __PACKAGE__;
}

sub ok {
	my $self = shift;

	if ($Result->{tested})
	{
		Test::Tester::save_result();
	}
	my ($ok, $name) = @_;
	$Result->{ok} = $ok;
	$Result->{name} = $name;
	$Result->{tested} = 1;
	$Result->{diag} ||= "";
#	$Result->{type} = "";

	return $ok;
}

sub diag {
	my $self = shift;

	my @diag = @_;
	my $diag = join("", @diag);
	$Result->{diag} .= $diag;

	return 0;
}

1;

__END__

=head1 NAME

Test::Tester::Capture - Help testing test modules built with Test::Builder

=head1 NOTIHING TO SEE HERE

Please read the docs in Test::Tester to find out more.

=head1 AUTHOR

The rest copywrite 2003 Fergal Daly <fergal@esatclear.ie>.

=head1 LICENSE

Under the same license as Perl itself

See http://www.perl.com/perl/misc/Artistic.html

=cut

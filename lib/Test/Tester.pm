# $Header: /home/fergal/my/cvs/Test-Tester/lib/Test/Tester.pm,v 1.8 2003/03/02 17:26:41 fergal Exp $
use strict;

package Test::Tester;

use Test::Builder;
use Test::Tester::Capture qw( $Result );
require Exporter;

use vars qw( @ISA @EXPORT $VERSION $Result );

$VERSION = "0.01";
@EXPORT = qw( run_tests check_tests check_test cmp_results );
@ISA = qw( Exporter );

my @PreviousResults;
$Result = {};

my $Test = Test::Builder->new;

sub capture
{
	return Test::Tester::Capture->new;
}

sub save_result
{
	if (%$Result)
	{
		push(@PreviousResults, $Result);
		$Result = {};
	}
}

sub run_tests
{
	my $test = shift;
	my $name = shift || "";

	my $res_start = $#PreviousResults + 1;

	if (%$Result)
	{
		require Data::Dumper;
		warn "Result is contaminated before test\n".Data::Dumper::Dumper($Result);
		$Result = {};
	}

	$Result->{expected_name} = $name;
	$Result->{tested} = 0;

	&$test();

	save_result();

	my $res_end = $#PreviousResults;

	my $result = $Result;

	return @PreviousResults[$res_start..$res_end];
}

sub check_test
{
	my $test = shift;
	my $expect = shift;
	my $name = shift;

	local $Test::Builder::Level = $Test::Builder::Level + 1;

	check_tests($test, [$expect], $name);
}

sub check_tests
{
	my $test = shift;
	my $expects = shift;
	my $name = shift;

	my (@results) = eval {
		local $Test::Builder::Level = $Test::Builder::Level + 1;
		run_tests($test, $name);
	};

	$Test->ok(! $@, "Test '$name' completed") || $Test->diag($@);

	$Test->ok($results[0]->{tested}, "Test '$name' gives a complete result");

	local $Test::Builder::Level = $Test::Builder::Level + 1;
	cmp_results(\@results, $expects, $name);
	return @results;
}

sub cmp_result
{
	my ($result, $expect, $name, $test_num) = @_;

	$test_num = defined($test_num) ? " $test_num of" : "";

	defined($expect->{ok}) || die "No expected value for ok in '$name'";

	if ($result->{tested})
	{
		$Test->ok( ! ($result->{ok} xor $expect->{ok}),
			"Test$test_num '$name' correct result" ) ||
			$Test->diag(<<EOM);
Expected result: '$expect->{ok}'
Got result     : '$result->{ok}'
EOM

		if (defined $name)
		{
			$Test->is_eq($result->{name}, $name,
				"Test$test_num '$name' correct name");
		}

		if (defined $expect->{diag})
		{
			$Test->is_eq($result->{diag}, $expect->{diag}, "Test$test_num '$name' correct diag");
		}
	}
	else
	{
		$Test->fail("Test$test_num '$name' didn't test, cannot check result");
		$Test->fail("Test$test_num '$name' didn't test, cannot check name") if defined($name);
		$Test->fail("Test$test_num '$name' didn't test, cannot compare diag") if defined $expect->{diag};
	}
}

sub cmp_results
{
	my ($results, $expects, $name) = @_;

	$Test->is_num(scalar @$results, scalar @$expects, "Test '$name' result count");

	for (my $i = 0; $i < @$expects; $i++)
	{
		my $expect = $expects->[$i];
		my $result = $results->[$i];

		local $Test::Builder::Level = $Test::Builder::Level + 1;
		cmp_result($result, $expect, $name, $i + 1);
	}
}

sub get_result
{
	return $Result;
}

sub get_all_results
{
	return @PreviousResults;
}

######## nicked from Test::More
sub plan {
    my(@plan) = @_;

    my $caller = caller;

    $Test->exported_to($caller);

    my @imports = ();
    foreach my $idx (0..$#plan) {
        if( $plan[$idx] eq 'import' ) {
            my($tag, $imports) = splice @plan, $idx, 2;
            @imports = @$imports;
            last;
        }
    }

    $Test->plan(@plan);

    __PACKAGE__->_export_to_level(1, __PACKAGE__, @imports);
}

sub import {
    my($class) = shift;
    goto &plan;
}

sub _export_to_level
{
      my $pkg = shift;
      my $level = shift;
      (undef) = shift;                  # redundant arg
      my $callpkg = caller($level);
      $pkg->export($callpkg, @_);
}


############

1;

__END__

=head1 NAME

Test::Tester - Help testing test modules built with Test::Builder

=head1 SYNOPSIS

  use Test::Tester qw( tests => 5);

  use Test::MyStyle;

  Test::MyStyle::set_builder(Test::Tester->capture);

  check_test(
    sub {
      is_mystyle_eq("this", "that", "not eq");
    },
    {
      name => "not eq",
      ok => 0,
      diag => "Expected: 'this'\nGot: 'that'",
    }
  );

=head1 DESCRIPTION

If you have written a test module based on Test::Builder then Test::Tester
makes it easier for you to test your tests. It provides an object from
Test::Tester::Capture which inherits from Test::Builder but overrides the
ok() and diag() methods so that it can prevent test output and also capture
test results and diagnostics for examination.

=head1 HOW TO USE IT

Make your module use the Test::Tester::Capture object instead of the
Test::Builder one. How to do this depends on your module but assuming that
your module holds the Test::Builder object in $Test and that all your test
routines access it through $Test then providing a function something like this

  sub set_builder
  {
    $Test = shift;
  }

should allow your test scripts to do

  Test::YourModule::set_builder(Test::Tester->capture);

and after that any tests inside your module will captured.

=head1 TEST RESULTS

Some of the functions exported return catured test results. The results of
each test is captured in a hash can include the following fields:

=over 4

=item tested

This is 1 if a test was actually carried, 0 otherwise

=item ok

This will be true if the captured test passed, false otherwise

=item name

This is the name of the test, as supplied to ok

=item diag

Any diagnostics output by the test

=back

=head1 EXPORTED FUNCTIONS

=over 4 

=item cmp_result(\%result, \%expect, $name)

\%result is a ref to a test result hash. \%expect is a ref to an
hash of expected values for the test result. cmp_result checks that a test
result checks that the result was actually produced and that it matches the
expected result. If any differences are found it outputs diagnostics. You
may leave out the "name" or "diag" field from the expected result if you
don't want to test them.

=item cmp_results(\@results, \@expects, $name)

\@results is a ref to an array of test results. \@expects is a ref to an
array of hash refs. cmp_results checks that the results match the expected
results and if any differences are found it outputs diagnostics. It first
checks that the number of elements in \@results and \@expects is the same.
Then it goes through each result checking it against the expected result as
in cmp_result() above.

=item run_tests(\&test_sub, $name)

\&test_sub is a reference to a subroutine. $name is a string. run_tests runs
the subroutine in $test_sub and returns an B<ARRAY> of test results. It may
run more than 1 test. If you only run 1 test it run_tests still returns an
B<ARRAY>.

=item check_tests(\&test_sub, \@expects, $name)

\&test_sub is a reference to a subroutine. \@expect is a ref to an array of
hash refs which are expected test results. check_test combines run_test and
cmp_tests into a single call.

=item check_test(\&test_sub, \%expect, $name)

\&test_sub is a reference to a subroutine. \%expect is a ref to an hash of
expected values for the test result. check_test is a wrapper around
check_tests. It combines run_tests and cmp_tests into a single call. It
assumes that only a single test is run inside \&test_sub.

=back

=head1 SEE ALSO

Test::Builder

=head1 AUTHOR

Plan handling lifted from Test::More, written by Michael G Schwern
<schwern@pobox.com>.

The rest copywrite 2003 Fergal Daly <fergal@esatclear.ie>.

=head1 LICENSE

Under the same license as Perl itself

See http://www.perl.com/perl/misc/Artistic.html

=cut


# $Header: /home/fergal/my/cvs/Test-Tester/lib/Test/Tester.pm,v 1.24 2003/07/27 20:01:03 fergal Exp $
use strict;

package Test::Tester;

use Test::Builder;
use Test::Tester::CaptureRunner;
use Test::Tester::Capture;
use Test::Tester::Delegate;

require Exporter;

use vars qw( @ISA @EXPORT $VERSION );

$VERSION = "0.08";
@EXPORT = qw( run_tests check_tests check_test cmp_results );
@ISA = qw( Exporter );

my $Test = Test::Builder->new;
my $Runner = Test::Tester::CaptureRunner->new;
my $Delegator = Test::Tester::Delegator->new;

sub capture
{
	return Test::Tester::Capture->new;
}

sub fh
{
	# experiment with capturing output, I don't like it
	$runner = Test::Tester::FHRunner->new;

	return $Test;
}

sub run_tests
{
	$runner->run_tests(@_);
	return ($runner->get_premature, $runner->get_results);
}

sub check_test
{
	my $test = shift;
	my $expect = shift;
	my $name = shift;
	$name = "" unless defined($name);

	my ($prem, @results) = do
	{
		local $Test::Builder::Level = $Test::Builder::Level + 1;
		check_tests($test, [$expect], $name);
	};

	return ($prem, @results);
}

sub check_tests
{
	my $test = shift;
	my $expects = shift;
	my $name = shift;
	$name = "" unless defined($name);

	my ($prem, @results) = eval { run_tests($test, $name) };

	$Test->ok(! $@, "Test '$name' completed") || $Test->diag($@);
	$Test->ok(! length($prem), "Test '$name' no premature diagostication") ||
		$Test->diag("Before any testing anything, your tests said\n$prem");

	local $Test::Builder::Level = $Test::Builder::Level + 1;
	cmp_results(\@results, $expects, $name);
	return ($prem, @results);
}

sub cmp_field
{
	my ($result, $expect, $field, $desc) = @_;

	if (defined $expect->{$field})
	{
		$Test->is_eq($result->{$field}, $expect->{$field},
			"$desc compare $field");
	}
}

sub cmp_result
{
	my ($result, $expect, $name) = @_;

	my $sub_name = $result->{name};
	$sub_name = "" unless defined($name);

	my $desc = "subtest '$sub_name' of '$name'";

	{
		local $Test::Builder::Level = $Test::Builder::Level + 1;

		cmp_field($result, $expect, "ok", $desc);

		cmp_field($result, $expect, "actual_ok", $desc);

		cmp_field($result, $expect, "type", $desc);

		cmp_field($result, $expect, "reason", $desc);

		cmp_field($result, $expect, "name", $desc);
	}

	if (defined $expect->{diag})
	{
		if (not $Test->ok($result->{diag} eq $expect->{diag},
			"subtest '$sub_name' of '$name' compare diag")
		)
		{
			my $glen = length($result->{diag});
			my $elen = length($expect->{diag});

			$Test->diag(<<EOM);
Got diag ($glen bytes):
$result->{diag}
Expected diag ($elen bytes):
$expect->{diag}
EOM

		}
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
		cmp_result($result, $expect, $name);
	}
}

######## originally nicked from Test::More
sub plan {
    my(@plan) = @_;

    my $caller = caller;

    $Test->exported_to($caller);

    my @imports = ();
    my $auto = 0;
    foreach my $idx (0..$#plan) {
        if( $plan[$idx] eq 'import' ) {
            my($tag, $imports) = splice @plan, $idx, 2;
            @imports = @$imports;
        }
        elsif( $plan[$idx] eq 'auto' ) {
            splice @plan, $idx, 1;
            $auto = 1;
        }
    }
    
    if ($auto)
    {
			no warnings 'redefine';
			*Test::Builder::new = \&Test::Tester::Capture::new;
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

  use Test::Tester tests => 5, 'auto';

  use Test::MyStyle;

  check_test(
    sub {
      is_mystyle_eq("this", "that", "not eq");
    },
    {
      ok => 0,
      name => "not eq",
      diag => "Expected: 'this'\nGot: 'that'",
    }
  );

or

  use Test::More tests => 2;

  use Test::Tester 'auto';

  use Test::MyStyle;

	my @results = run_tests(sub {
   is_mystyle_eq("this", "that", "not eq");
	});

	is($result[1]->name, "not eq", "test name");

=head1 DESCRIPTION

If you have written a test module based on Test::Builder then Test::Tester
makes it easier for you to test it with the minimum of effort.

=head1 HOW TO USE (THE EASY WAY)

From version 0.08 Test::Tester involves no messing around and adding things
to your test modul. Simply

  use Test::Tester 'auto';

load up the module you want to test and test away.

Other modules based on Test::Builder can be used to with the testing. These
must be loaded before Test::Tester.

The easiest way to test is to do something like

  check_test(
  	sub { is_mystyle_eq("this", "that", "not eq") },
    {
      ok => 0,
      name => "not eq",
      diag => "Expected: 'this'\nGot: 'that'",
    }
  );

this will execute the is_mystyle_eq test 

=head1 HOW TO USE (THE HARD WAY)

B<This remains for compatibility>

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

=begin _scrapped_for_now

=head1 HOW TO USE THE HORRIBLE NEW WAY

There is now another way to use this, maybe it's a better way, I don't know.
Just do a Test::Tester::fh() and it then it'll be set up to run in
filehandle capture mode. This means that when you run a test using one of
the functions provided below, the output form Test::Builder will be
captured. The results that are returned are exactly what you get from
Test::Builder's details method but each result also has it's diagnostic
output added to the hash under the 'diag' key. For failed tests, the failure
notice is removed.

This is another quite dodgy way of doing things as it fiddles with
Test::Builder's current_test counter and does nasty things to it's
@Test_Result array.

=end

=head1 TEST RESULTS

The result of each test is captured in a hash. This hash is the same as the
one of the hashes returned by the Test::Builder->details method but it has
an extra field, B<diag>, which contains the diagnostic output for that test.

Some of the Test::Testers functions return arrays of these hashes, just like
Test::Builder->details.

=head1 EXPORTED FUNCTIONS

=head3 cmp_result(\%result, \%expect, $name)

\%result is a ref to a test result hash.

\%expect is a ref to a hash of expected values for the test result.

cmp_result compares the result with the expected values. If any differences
are found it outputs diagnostics. You may leave out any field from the
expected result and cmp_result will not do the comparison of that field.

=head3 cmp_results(\@results, \@expects, $name)

\@results is a ref to an array of test results.

\@expects is a ref to an array of hash refs.

cmp_results checks that the results match the expected results and if any
differences are found it outputs diagnostics. It first checks that the
number of elements in \@results and \@expects is the same. Then it goes
through each result checking it against the expected result as in
cmp_result() above.

=head3 ($prem, @results) = run_tests(\&test_sub, $name)

\&test_sub is a reference to a subroutine.

$name is a string.

run_tests runs the subroutine in $test_sub and captures the results of any
tests inside it. There may be more than 1 test inside.

$prem is a string containg any diagnostic output from before the first test.

@results is an array of test results.

=head3 ($prem, @results) = check_tests(\&test_sub, \@expects, $name)

\&test_sub is a reference to a subroutine.

\@expect is a ref to an array of hash refs which are expected test results.

check_tests combines run_tests and cmp_tests into a single call. It also
checks if the tests died at any stage.

It returns the same values as run_tests, so you can do further tests.

=head3 ($prem, @results) = check_test(\&test_sub, \%expect, $name)

\&test_sub is a reference to a subroutine. 

\%expect is a ref to an hash of expected values for the test result.

check_test is a wrapper around check_tests. It combines run_tests and
cmp_tests into a single call, checking if the test died. It assumes that
only a single test is run inside \&test_sub and test to make this is true.

It returns the same values as run_tests, so you can do further tests.

=head1 HOW IT WORKS

In auto mode, it replaces Test::Builder::new

Normally, a test module (let's cal it Test:MyStyle) calls Test::Builder->new
to get the Test::Builder object. Test::MyStyle calls methods on this object
to record information about test results. When Test::Tester is loaded, it
replaces Test::Builder's new() method with one which returns a
Test::Tester::Capture object. This behaves exactly like a Test::Builder
object and records all the results of the tests. The key different is that
it doesn't output anything and it doesn't interact at all with the real
Test::Builder object. Instead you can examine these stored results to ensure
that they are are what was expected.

The overwriting of the new() methods takes place at load time so if you want
to use Test::More to help you to test Test::MyStyle you need to load it
before loading Test::Tester

=head1 SEE ALSO

Test::Builder the source of testing goodness. Test::Builder::Tester for an
alternative approach to the problem tackled by Test::Tester.

=head1 AUTHOR

This module is copyright 2004 Fergal Daly <fergal@esatclear.ie>, some parts
are based on other people's work.

Plan handling lifted from Test::More. written by Michael G Schwern
<schwern@pobox.com>.

Test::Tester::Capture is a cut down and hacked up version of Test::Builder.
Test::Builder was written by chromatic <chromatic@wgz.org> and Michael G
Schwern <schwern@pobox.com>.

=head1 LICENSE

Under the same license as Perl itself

See http://www.perl.com/perl/misc/Artistic.html

=cut


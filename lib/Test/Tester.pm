#!perl
#
# Documentation, copyright and license is at the end of this file.
#
package  Test::Tester;

use 5.001;
use strict;
use warnings;
use warnings::register;

use Test;
use Data::Dumper;
use Test::TestUtil;

use vars qw($VERSION $DATE);
$VERSION = '1.02';
$DATE = '2003/06/12';

#####
# Because Test::TestUtil uses SelfLoader, the @ISA
# method of inheriting Test::TestUtil has problems.
#
# Use AUTOLOAD inheritance technique below instead.
#
# use vars qw(@ISA);
# @ISA = qw(Test::TestUtil);

$Test::TestLevel = 1;

####
# Using an object to pass localized object data
# between functions. Makes the functions reentrant
# where out right globals can be clobbered when
# used with different threads (processes??)
#
sub new
{
    my ($class, $test_log) = @_;
    $class = ref($class) if ref($class);

    ###########
    # $self->[0]  Keep and restore $Test::TESTOUT
    # $self->[1]  test log file
    # $self->[2]  skip rest of the tests

    my @self = ('','','','','');
    my $self = bless \@self, $class;

    $self[1] = $test_log if $test_log;
    if($self[1]) {
        $self[0] = $Test::TESTOUT;
        unless ( open($Test::TESTOUT, ">>$self[1]") ) {
            warn( "Cannot open $self[1]\n" );
            $self->skip_rest();
            return undef
        }
        binmode $Test::TESTOUT; # make the test friendly for more platforms
    }

    $self
}

#####
# Done with the test
#
sub finish # end a test
{
   my ($self)=@_;
   if( $self->[1] ) {
       $self->[1]= '';
       unless (close( $Test::TESTOUT )) {
           warn( "Cannot close $self->[1]\n" );
       }
       $Test::TESTOUT = $self->[0];
   }
   1
}


#######
# Sets flag to skip rest of tests
#
sub skip_rest( $value )
{
   my ($self,$value) =  @_;
   my $result = $self->[2];
   $value = 1 unless $value;
   $self->[2] = $value;
   $result;   
}


######
# Cover function for &Test::plan
#
sub work_breakdown  # open a file
{
   my $self=shift @_;
   plan( @_ );
   1
}


#######
#
# Cover function for &TEST::ok that uses Dumper 
# so can test arbitary inputs
#
sub test
{
   my ($self, $actual_p, $expected_p, $name) = @_;
   print $Test::TESTOUT "# $name\n" if $name;
   if($self->[2]) {  # skip rest of tests switch
       print $Test::TESTOUT "# Test invalid because of previous failure.\n";
       skip( 1, 0, '');
       return 1; 
   }
   my $actual = Dumper(@$actual_p);
   my $expected = Dumper(@$expected_p);
   ok($actual, $expected, '');
}


#######
#
# Cover function for &TEST::skip so that uses Dumper 
# so can test arbitary inputs
#
sub verify  # store expected array for later use
{
   my ($self, $mod, $actual_p, $expected_p, $name) = @_;

   print $Test::TESTOUT "# $name\n" if $name;

   if($self->[2]) {  # skip rest of tests switch
       print $Test::TESTOUT "# Test invalid because of previous failure.\n";
       skip( 1, 0, '');
       return 1; 
   }
  
   my $actual = Dumper(@$actual_p);
   my $expected = Dumper(@$expected_p);
   my $test_ok = skip($mod, $actual, $expected, '');
   $test_ok = 1 if $mod;  # make sure do not stop 
   $test_ok

}


######
# Actual data
#
sub demo
{
   my ($self, $quoted_expression, @expression_results) = @_;

   #######
   # A demo trys to simulate someone typing expresssions
   # at a console.
   #

   #########
   # Print quoted expression so that see the non-executed
   # expression. The extra space is so when pasted into
   # a POD, the POD will process the line as code.
   #
   $quoted_expression =~ s/(\n+)/$1 => /g;
   print $Test::TESTOUT ' => ' . $quoted_expression . "\n";   

   ########
   # @data is the result of the script executing the 
   # quoted expression.
   #
   # The demo output most likely will end up in a pod. 
   # The the process of running the generated script
   # will execute the setup. Thus the input is the
   # actual results. Putting a space in front of it
   # tells the POD that it is code.
   #
   return unless @expression_results;
  
   $Data::Dumper::Terse = 1;
   my $data = Dumper(@expression_results);
   $data =~ s/(\n+)/$1 /g;
   $data =~ s/\\\\/\\/g;
   $data =~ s/\\'/'/g;

   print $Test::TESTOUT ' ' . $data . "\n" ;

}



#######
# Any other function use TestUtil
#
sub AUTOLOAD
{
    our $AUTOLOAD;

    my $self_p = shift @_;

    my $func_p = $AUTOLOAD; 
    $func_p =~ s/.*:://g; # trim the autoload

    return Test::TestUtil->$func_p( @_ );

}

1

__END__


=head1 NAME
  
Test::Tester - extends the capabilites of the I<Test> module

=head1 SYNOPSIS

  use Test::Tester

  $T = new Test::Tester;
  $success = $T->work_breakdown(@args);
  $test_ok = $T->test(\@actual_results, \@expected_results, $test_name);
  $test_ok = $T->verify(test, \@actual_results,  \@expected_results, $test_name);
  $success = $T->skip_rest();
  $success = $T->finish( );

  $success = $T->demo( $quoted_expression, @expression_results );

=head1 DESCRIPTION

The Test::Tester module extends the capabilities of
the Test module as follows:

=over 4

=item *

Compare almost any data structure by passing variables
through I<Data::Dumper> before making the comparision

=item *

Method to skip the rest of the tests upon a critical failure

=item *

Method to generate demos that appear as an interactive
session using the methods under test

=back

The Test::Tester module is an integral part of the US DOD SDT2167A bundle
of modules.
The dependency of the program modules in the US DOD STD2167A bundle is as follows:

 Test::TestUtil
     Test::Tester
        DataPort::FormDB
            Test::STDmaker ExtUtils::SVDmaker

=head2 new method

 $T = new Test::Tester;

The I<new> method creates a new I<Test::Tester> object.

=head2 work_breakdown method

 $success = $T->work_breakdown(@args);

The I<work_breakdown> method is a cover method for &Test::plan.
The I<@args> are passed unchanged directory to &Test::plan.
All arguments are options. Valid options are as follows:

=over 4

=item tests

The number of tests. For example

 tests => 14,

=item todo

An array of test that will fail. For example

 todo => [3,4]

=item onfail

A subroutine that the I<Test> module will
execute on a failure. For example,

 onfail => sub { warn "CALL 911!" } 

=back

=head2 test method

  $test_ok = $T->test(\@actual_results, \@expected_results, $test_name);

The I<test> method is a cover function for the &Test::ok subroutine
that extends the &Test::ok routine as follows:

=over 4

=item *

Prints out the I<$test_name> to provide an English identification
of the test.

=item *

The I<test> method passes the arrays
I<@actual_results> and I<@expectet_results> through &Data::Dumper::Dumper.
The I<test> method then uses &Test::ok to compare the text results
from &Data::Dumper::Dumper.

=item *

Response to a flag set by the L<skip_rest method|Test::Tester/skip_rest method>
and skips the test completely.

=back

=head2 verify method

  $test_ok = $T->verify(test, \@actual_results,  \@expected_results, $test_name);

The I<test> method is a cover function for the &Test::skip subroutine
that extends the &Test::skip the same as the I<test> method extends
the I<&Test::ok> subroutine.
See L<test method|Test::Tester/test method>

=head2 skip_rest method

  $success = $T->skip_rest();

The I<skip_rest> method sets a flag that causes the
I<test> and the I<verify> methods to skip testing.

=head2 finish method

  $success = $T->finish( );

The I<finish> method shuts down the I<$T Test::Tester> object.

head2 Test::TestUtil methods

The I<Test::Tester> program module inherits all the methods
from the L<Test::TestUtil|Test::TestUtil> module.

=head1 NOTES

=head2 AUTHOR

The holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 COPYRIGHT NOTICE

Copyrighted (c) 2002 Software Diamonds

All Rights Reserved

=head2 BINDING REQUIREMENTS NOTICE

Binding requirements are indexed with the
pharse 'shall[dd]' where dd is an unique number
for each header section.
This conforms to standard federal
government practices, 490A (L<STD490A/3.2.3.6>).
In accordance with the License, Software Diamonds
is not liable for any requirement, binding or otherwise.

=head2 LICENSE

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code must retain
the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=back

SOFTWARE DIAMONDS, http::www.softwarediamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE. 

=head1 SEE ALSO

L<Test> L<Test::TestUtil>

=for html
<p><br>
<!-- BLK ID="NOTICE" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="OPT-IN" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="EMAIL" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="COPYRIGHT" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>

=cut

### end of file ###
# $Id: Seconds.pm,v 1.1 2000/03/23 12:31:57 matt Exp $

package Time::Seconds;
use strict;
use vars qw/@EXPORT @ISA/;

@ISA = 'Exporter';

@EXPORT = qw(ONE_MINUTE ONE_HOUR ONE_DAY ONE_WEEK);

use constant ONE_MINUTE => 60;
use constant ONE_HOUR => 3_600;
use constant ONE_DAY => 86_400;
use constant ONE_WEEK => 604_800;

use overload 
        '0+' => \&seconds,
        '""' => \&seconds;

sub new {
        my $class = shift;
        my ($val) = @_;
		$val = 0 unless defined $val;
        bless \$val, $class;
}

sub seconds {
        my $s = shift;
        $$s;
}

sub minutes {
        my $s = shift;
        $$s / 60;
}

sub hours {
        my $s = shift;
        $s->minutes / 60;
}

sub days {
        my $s = shift;
        $s->hours / 24;
}

sub weeks {
        my $s = shift;
        $s->days / 7;
}

sub years {
        my $s = shift;
        $s->days / 365.2425;
}

1;
__END__

=head1 NAME

Time::Seconds - a simple API to convert seconds to other date values

=head1 SYNOPSIS

    use Time::Object;
    use Time::Seconds;
    
    my $t = localtime;
    $t += ONE_DAY;
    
    my $t2 = localtime;
    my $s = $t - $t2;
    
    print "Difference is: ", $s->days, "\n";

=head1 DESCRIPTION

This module is part of the Time::Object distribution. It allows the user
to find out the number of minutes, hours, days, weeks or years in a given
number of seconds. It is returned by Time::Object when you delta two
Time::Object objects.

Time::Seconds also exports the following constants:

    ONE_DAY
    ONE_WEEK
    ONE_HOUR
    ONE_MINUTE

Since perl does not (yet?) support constant objects, these constants are in
seconds only, so you cannot, for example, do this: C<print ONE_WEEK-E<gt>minutes;>

=head1 METHODS

The following methods are available:

    my $val = Time::Seconds->new(SECONDS)
    $val->seconds;
    $val->minutes;
    $val->hours;
    $val->days;
    $val->weeks;
    $val->years;

The methods make the assumption that there are 24 hours in a day, 7 days in
a week, and 365.2425 days in a year.

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

=head1 LICENSE

Please see Time::Object for the license.

=head1 Bugs

Currently the methods aren't as efficient as they could be, for reasons of
clarity. This is probably a bad idea.

=cut

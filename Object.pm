package Time::Object;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

require Exporter;
use POSIX 'strftime';
use Time::Seconds;
use Carp;

@ISA = qw(Exporter);

@EXPORT = qw(
	localtime
	gmtime
);

@EXPORT_OK = qw(
	overrideGlobally
);

$VERSION = '0.05';

use constant 'c_sec' => 0;
use constant 'c_min' => 1;
use constant 'c_hour' => 2;
use constant 'c_mday' => 3;
use constant 'c_mon' => 4;
use constant 'c_year' => 5;
use constant 'c_wday' => 6;
use constant 'c_yday' => 7;
use constant 'c_isdst' => 8;
use constant 'c_epoch' => 9;
use constant 'c_islocal' => 10;

sub localtime {
	my $time = shift;
	$time = time if (!defined $time);
	_mktime($time, 1);
}

sub gmtime {
	my $time = shift;
	$time = time if (!defined $time);
	_mktime($time, 0);
}

sub _mktime {
	my ($time, $islocal) = @_;
	my @time = $islocal ? 
			CORE::localtime($time)
			:
			CORE::gmtime($time);
	wantarray ? @time : bless [@time, $time, $islocal], 'Time::Object';
}

sub import {
	# replace CORE::GLOBAL localtime and gmtime if required
	my $class = shift;
	my %params;
	map($params{$_}++,@_,@EXPORT);
	if ($params{'overrideGlobally'}) {
		$class->export('CORE::GLOBAL', keys %params);
	}
	else {
		$class->export((caller)[0], keys %params);
	}
}

## Methods ##

sub sec {
	my $time = shift;
	$time->[c_sec];
}

sub min {
	my $time = shift;
	$time->[c_min];
}

sub hour {
	my $time = shift;
	$time->[c_hour];
}

sub mday {
	my $time = shift;
	$time->[c_mday];
}

sub mon {
	my $time = shift;
	$time->[c_mon] + 1;
}

sub _mon {
	my $time = shift;
	$time->[c_mon];
}

sub monname {
	my $time = shift;
	POSIX::strftime('%B', (@$time)[c_sec..c_isdst]);
}

sub year {
	my $time = shift;
	$time->[c_year] + 1900;
}

sub _year {
	my $time = shift;
	$time->[c_year];
}

sub yr {
	my $time = shift;
	$time->[c_year] % 100;
}

sub wday {
	my $time = shift;
	$time->[c_wday] + 1;
}

sub _wday {
	my $time = shift;
	$time->[c_wday];
}

sub wdayname {
	my $time = shift;
	POSIX::strftime('%A', (@$time)[c_sec..c_isdst]);
}

sub yday {
	my $time = shift;
	$time->[c_yday];
}

sub isdst {
	my $time = shift;
	$time->[c_isdst];
}

# Thanks to Tony Olekshy <olekshy@avrasoft.com> for this algorithm
sub tzoffset {
	my $time = shift;

	my $epoch = $time->[c_epoch];

	my $j = sub { # Tweaked Julian day number algorithm.
			my @T; $_[0] ? 
				(@T = CORE::localtime $epoch)
				:
				(@T = CORE::gmtime $epoch);

			my ($s,$n,$h,$d,$m,$y) = @T; $m += 1; $y += 1900;

			# Standard Julian day number algorithm without constant.
			#
			my $y1 = $m > 2 ? $y : $y - 1;

			my $m1 = $m > 2 ? $m + 1 : $m + 13;

			my $days = int(365.25 * $y1) + int(30.6001 * $m1) + $d;

			# Modify to include hours/mins/secs in floating portion.
			#
			return $days + ($h + ($n + $s / 60) / 60) / 24;
		};

	# Compute floating offset in hours.
	#
	my $delta = 24 * (&$j(1) - &$j(0));

	# Return value in hours rounded to nearest minute.
	#
	return Time::Seconds->new(int($delta * 60 + 0.5 * ($delta >= 0 ? 1 : -1)) / 60);
}

sub epoch {
	my $time = shift;
	$time->[c_epoch];
}

sub hms {
	my $time = shift;
	sprintf('%02d:%02d:%02d', $time->[c_hour], $time->[c_min], $time->[c_sec]);
}

sub ymd {
	my $time = shift;
	sprintf('%d/%02d/%02d', $time->year, $time->mon, $time->[c_mday]);
}

sub mdy {
	my $time = shift;
	sprintf('%02d/%02d/%d', $time->mon, $time->[c_mday], $time->year);
}

sub dmy {
	my $time = shift;
	sprintf('%02d/%02d/%d', $time->[c_mday], $time->mon, $time->year);
}

use overload '""' => \&date;

sub date {
	my $time = shift;
	if ($time->[c_islocal]) {
		return scalar(CORE::localtime($time->[c_epoch]));
	}
	else {
		return scalar(CORE::gmtime($time->[c_epoch]));
	}
}

use overload
		'-' => \&subtract,
		'+' => \&add;

sub subtract {
	my $time = shift;
	my $rhs = shift;
	if (ref($rhs) && $rhs->isa('Time::Object')) {
		return Time::Seconds->new($time->[c_epoch] - $rhs->epoch);
	}
	else {
		# rhs is seconds.
		return _mktime(($time->[c_epoch] - $rhs), $time->[c_islocal]);
	}
}

sub add {
	my $time = shift;
	my $rhs = shift;
	croak "Invalid rhs of addition" if ref($rhs);
	
	return _mktime(($time->[c_epoch] + $rhs), $time->[c_islocal]);
}

use overload
		'<=>' => \&compare;

sub compare {
	my $time = shift;
	my $rhs = shift;
	if (ref($rhs) && $rhs->isa('Time::Object')) {
		return $time->[c_epoch] <=> $rhs->epoch;
	}
	else {
		return $time->[c_epoch] <=> $rhs;
	}
}

1;
__END__

=head1 NAME

Time::Object - Object Oriented time objects

=head1 SYNOPSIS

    use Time::Object;
    
    my $t = localtime;
    print "Time is $t\n";
    print "Year is ", $t->year, "\n";

=head1 DESCRIPTION

This module replaces the standard localtime and gmtime functions with
implementations that return objects. It does so in a backwards
compatible manner, so that using localtime/gmtime in the way documented
in perlfunc will still return what you expect.

The module actually implements most of an interface described by
Larry Wall on the perl5-porters mailing list here:
http://www.xray.mpe.mpg.de/mailing-lists/perl5-porters/2000-01/msg00241.html

=head1 USAGE

After importing this module, when you use localtime or gmtime in a scalar
context, rather than getting an ordinary scalar string representing the
date and time, you get a Time::Object object, whose stringification happens
to produce the same effect as the localtime and gmtime functions. The
following methods are available on the object:

    $t->sec
    $t->min
    $t->hour
    $t->mday
    $t->mon             # based at 1
    $t->_mon            # based at 0
    $t->monname         # February (uses POSIX::strftime)
    $t->year            # based at 0 (year 0 AD is, of course 1 BC).
    $t->_year           # year minus 1900
    $t->yr              # 2 digit year
    $t->wday            # based at 1 (Sunday)
    $t->_wday           # based at 0 (Also Sunday!)
    $t->wdayname        # Tuesday (uses POSIX::strftime)
    $t->yday
    $t->isdst
    $t->hms             # 01:23:45
    $t->ymd             # 2000/02/29
    $t->mdy             # 02/29/2000
    $t->dmy             # 29/02/2000
    $t->date            # Tue Feb 29 01:23:45 2000
    "$t"                # same as $t->date
    $t->epoch           # seconds since the epoch
    $t->tzoffset        # timezone offset in hours

=head2 Date Calculations

It's possible to use simple addition and subtraction of objects:

    use Time::Seconds;
	
	my $seconds = $t1 - $t2;
	$t1 += ONE_DAY; # add 1 day (constant from Time::Seconds)

The following are valid ($t1 and $t2 are Time::Object objects):

	$t1 - $t2; # returns Time::Seconds object
	$t1 - 42; # returns Time::Object object
	$t1 + 533; # returns Time::Object object

However adding a Time::Object object to another Time::Object object
will cause a runtime error.

Note that the first of the above returns a Time::Seconds object, so
while examining the object will print the number of seconds (because
of the overloading), you can also get the number of minutes, hours,
days, weeks and years in that delta, using the Time::Seconds API.

=head2 Date Comparisons

Date comparisons are also possible, using the full suite of "<", ">",
"<=", ">=", "<=>", "==" and "!=".

=head2 Global Overriding

Finally, it's possible to override localtime and gmtime everywhere, by
including the 'overrideGlobally' tag in the import list:

	use Time::Object 'overrideGlobally';

I'm not too keen on this name yet - suggestions welcome...

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

=head2 License

This module is free software, you may distribute it under the same terms
as Perl.

=head2 Bugs

The test harness leaves much to be desired. Patches welcome.

=cut

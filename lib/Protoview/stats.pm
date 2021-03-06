############################################################################
# This file is part of protoview.					   #
# 									   #
# Protoview is free software: you can redistribute it and/or modify	   #
# it under the terms of the GNU General Public License as published by     #
# the Free Software Foundation, either version 3 of the License, or	   #
# (at your option) any later version.				           #
# 									   #
# Protoview is distributed in the hope that it will be useful,  	   #
# but WITHOUT ANY WARRANTY; without even the implied warranty of	   #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the	           #
# GNU General Public License for more details.			           #
# 									   #
# You should have received a copy of the GNU General Public License	   #
# along with Protoview.  If not, see <http://www.gnu.org/licenses/>	   #
# 									   #
# Tosh (duretsimon73 -at- gmail -dot- com)				   #
# - 2014 -								   #
#                                                                          #
############################################################################

package stats;

use strict;
use warnings;

use Protoview::protocols;
use Protoview::format;

# Stats constructor
sub new {
    my $class = shift;
    my $this = {};

    bless($this, $class);

    $this->{_tot_bytes} = 0;
    $this->{_tot_pkt} = 0;
    $this->{_timestamp} = time;

    return $this;
}

# Update statistiques
# Called for every packets received in the wire
sub add_pkt {
    my ($this, $pkt) = @_;
    my $cur_ref = \$this;

    $this->inc_tot_pkt;
    $this->inc_tot_bytes($pkt->get_len);

    foreach my $ref(@{$pkt->{PROTO_REFS}}) {
	$cur_ref = \$$cur_ref->{$ref->[0]};

	if(exists $protocols::list->{$ref->[0]}) {
	    $protocols::list->{$ref->[0]}->{update}($cur_ref, $ref->[1]);
	}
    }
}

# Increment the total packet received
sub inc_tot_pkt {
    my $this = shift;

    $this->{_tot_pkt}++;
}

# Increment total bytes received
sub inc_tot_bytes {
    my ($this, $bytes) = @_;

    $this->{_tot_bytes} += $bytes;
}

# Get the curent elapsed time in seconds
sub get_elapsed_time {
    return time - $_[0]->{_timestamp};
}

# Get the number of packet per seconds
sub get_pkt_per_sec {
    my $this = shift;

    return 0 unless $this->get_elapsed_time;
    return sprintf "%.2f", $this->get_tot_pkt/$this->get_elapsed_time;
}

# Get the total packet received
sub get_tot_pkt {
    return $_[0]->{_tot_pkt};
}

# Get the total bytes received
sub get_tot_bytes {
    return $_[0]->{_tot_bytes};
}

# Get the (K/M/G)bits per seconds rate
sub get_bits_per_sec {
    my $this = shift;
    my $bits;
    my $unit = 'b/sec';

    if($this->get_elapsed_time) {
	$bits = ($this->get_tot_bytes*8) / $this->get_elapsed_time;
    } else {
	$bits = $this->get_tot_bytes*8;
    }

    if($bits > 1000) {
	$unit = 'Kb/sec';
	$bits /= 1000;
    }

    if($bits > 1000) {
	$unit = 'Mb/sec';
	$bits /= 1000;
    }

    if($bits > 1000) {
	$unit = 'Gb/sec';
	$bits /= 1000;
    }

    return sprintf "%.2f %s", $bits, $unit;
}

# Get the average bytes per packet
sub get_bytes_per_pkt {
    my $this = shift;

    return 0 unless $this->get_tot_pkt;
    return sprintf "%.2f", $this->get_tot_bytes / $this->get_tot_pkt;
}

# Build lines for the displayer
sub build_lines {
    my $this = shift;
    my @lines;
    my $i = 0;

    $lines[$i++] = format::menu("++ INFOS");
    $lines[$i++] = format::line("   Packets captured",  $this->get_tot_pkt);
    $lines[$i++] = format::line("   Packets/sec",  $this->get_pkt_per_sec);
    $lines[$i++] = format::line("   Bandwidth", $this->get_bits_per_sec);
    $lines[$i++] = format::line("   bytes/packet", $this->get_bytes_per_pkt);
    $lines[$i++] = format::line("   Elapsed secondes", $this->get_elapsed_time);
    $lines[$i++] = ' ';

    _build_lines_rec(\$this, 0, \@lines, \$i);

    return \@lines;

}

# Build lines recursivly for the displayer
sub _build_lines_rec {
    my ($ref, $spaces, $lines, $i) = @_;

    foreach my $k(keys %{$$ref}) {
	if($k =~ m/^[A-Z0-9]+$/) {
	    if(exists $protocols::list->{$k}) {
		$lines->[$$i++] = format::menu('+'x$spaces . "++ $k");
		$protocols::list->{$k}->{build_lines}(\$$ref->{$k}, $spaces, $lines, $i);
	    }
	    _build_lines_rec(\$$ref->{$k}, $spaces + 3, $lines, $i);
	}
    }
}

1;

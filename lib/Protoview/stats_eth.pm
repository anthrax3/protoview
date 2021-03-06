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

package stats_eth;

use strict;
use warnings;

use Protoview::format;
use Protoview::misc;

my %eth_types = (
    0x0800 => 'ipv4',
    0x86DD => 'ipv6',
    0x0806 => 'arp',
    0x8035 => 'rarp',
    0x80F3 => 'appletalk-arp',
    0x8100 => 'vlan-tagged-frame',
    0x88E1 => 'homeplug-av',
    );

# This function is called for every ETHERNET packet
# Update stats object
sub update {
    my ($stats_ref, $pkt_ref) = @_;

    $$stats_ref->{tot}++;
    $$stats_ref->{src}{$$pkt_ref->{src}}++;
    $$stats_ref->{dst}{$$pkt_ref->{dst}}++;
    $$stats_ref->{proto}{$$pkt_ref->{proto}}++;
}

# Build lines for the displayer
sub build_lines {
    my ($ref, $spaces, $lines, $i) = @_;
    my @keys;

    $lines->[$$i++] = format::line(' 'x$spaces . "   Total packets", $$ref->{tot});
    $lines->[$$i++] = ' ';

    _build_proto_lines($ref, $spaces, $lines, $i);
    $lines->[$$i++] = ' ';

    _build_addr_lines($ref, $spaces, $lines, $i);
    $lines->[$$i++] = ' ';
}

# Build lines corresponding to the protocol
sub _build_proto_lines {
   my ($ref, $spaces, $lines, $i) = @_;
   my @keys;

   @keys = sort {$$ref->{proto}{$b} <=> $$ref->{proto}{$a}} keys %{$$ref->{proto}};
   foreach my $p(@keys) {
       $lines->[$$i++] = format::line(' 'x$spaces . "   Proto:" . _proto_to_str($p), 
				      $$ref->{proto}{$p} . ' (' . misc::percentage($$ref->{proto}{$p}, $$ref->{tot}) . '%)');
   }   
}

# Build lines corresponding to src/dst address
sub _build_addr_lines {
    my ($ref, $spaces, $lines, $i) = @_;
    my @keys;

    unless($main::options->{addr}) {
	$lines->[$$i++] = ' ';

	@keys = sort {$$ref->{src}{$b} <=> $$ref->{src}{$a}} keys %{$$ref->{src}};
	foreach my $p(@keys) {
	    $lines->[$$i++] = format::line(' 'x$spaces . "   Src:$p", 
					   $$ref->{src}{$p} . ' (' . misc::percentage($$ref->{src}{$p}, $$ref->{tot}) . '%)');
	}

	$lines->[$$i++] = ' ';

	@keys = sort {$$ref->{dst}{$b} <=> $$ref->{dst}{$a}} keys %{$$ref->{dst}};
	foreach my $p(@keys) {
	    $lines->[$$i++] = format::line(' 'x$spaces . "   Dst:$p", 
					   $$ref->{dst}{$p} . ' (' . misc::percentage($$ref->{dst}{$p}, $$ref->{tot}) . '%)');
	}
    }
}

sub _proto_to_str {
    my $proto = shift;

    if(exists($eth_types{$proto})) {
	return $eth_types{$proto};
    }

    return $proto;
}

1;

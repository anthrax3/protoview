package pcap;

# Standard modules
use strict;
use warnings;

# Non-standard modules
use Net::Pcap;

sub new {
    my ($class, $dev, $callback, $user) = @_;
    my $this = {};

    bless($this, $class);

    $this->_init_dev($dev);
    $this->{_callback} = $callback;
    $this->{_user} = $user;
    $this->{_handle} = pcap_get_selectable_fd($this->{_pcap});
    $this->{_timestamp} = time();

    return $this;    
}

sub _init_dev {
    my ($this, $dev) = @_;
    my $err;

    unless(defined $dev) {
	$dev = Net::Pcap::lookupdev(\$err);
	unless(defined $dev) {
	    die "[-] Can't lookupdev: $err\n";
	}
    }

    $this->{_dev} = $dev;

    $this->{_pcap} = Net::Pcap::open_live($dev, 1500, 0, -1, \$err);

    unless(defined $this->{_pcap}) {
	die "[-] Can't open live ($dev): $err\n";
    }
}

sub next_pkt {
    my ($this) = @_;
    my (%hdr, $pkt);

    $pkt = Net::Pcap::next($this->{_pcap}, \%hdr); 
    if(defined $pkt) {
	$this->{_callback}($pkt, \%hdr, $this->{_user});
    }
}

sub get_dev {
    my $this = shift;

    return $this->{_dev};
}

sub get_handle {
    my $this = shift;

    return $this->{_handle};
}

sub handle {
    my ($raw, $hdr, $stats) = @_;
    my $pkt = pkt->new($raw);

    $stats->add_pkt($pkt);    
}

1;

package protocols;

our $list;

use pkt_eth;
use pkt_ipv4;

sub new {
    my ($class) = @_;
    my $this = {};

    bless($this, $class);    

    return $this;
}

sub add {
    my ($this, $name, $h) = @_;

    %{$this->{$name}} = %{$h};
    
}

BEGIN {
    $list = protocols->new();

    $list->add('ETHERNET', {
	parser       => \&pkt_eth::parse,
	build_lines  => \&stats_eth::build_lines,
	update       => \&stats_eth::update
		    });

    $list->add('IPV4', {
	parser      => \&pkt_ipv4::parse,
	build_lines => \&stats_ipv4::build_lines,
	update      => \&stats_ipv4::update,
	from        => 'ETHERNET',
	field       => ['proto', 0x0800]
		    });    

}

1;

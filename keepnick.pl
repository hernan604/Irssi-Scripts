use Irssi;                                                                                                                                                                                                                                                               
#ABSTRACT: Keeps the user nickname in case of a reconnect
#this scripts binds to server events. When a network emits a server event this script will try to change nick accordingly.

#installation: add or link this script in .irssi/scripts/autorun

my $config = {
    nick => {
        'the_nick' => [ #chatnets to keep this channel
            'chatnet0',
            'chatnet1',
        ]
    }
};

#   multiples nicks in multiples networks.
#   my $config = {
#       nick => {
#           'the_nick' => [ #chatnets to keep this channel
#               'chatnet0',
#               'chatnet1',
#           ],
#           'other_nick' => [ #chatnets to keep this channel
#               'chatnet2',
#               'chatnet3',
#           ],
#       }
#   };

sub server_event {
    my ( $server, $data, $nick, $address ) = @_;
    for ( keys %{ $config->{ nick } } ) {
        my $nick     = $_;
        my $chatnets = $config->{ nick }->{ $nick };
        my $chatnet  = $server->{ chatnet }; #current chatnet that fired server event
#       Irssi::command()
        Irssi::Server::command( $server, "nick $nick" )
            if $nick ne $server->{nick}
            and grep /^$chatnet$/, @$chatnets
            ;
    }
}

Irssi::signal_add("server event", "server_event");



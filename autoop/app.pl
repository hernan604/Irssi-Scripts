use Irssi;
use lib $ENV{HOME}.'/.irssi/scripts/autoop/lib';
use DDP;
use AutoOp;
#ABSTRACT: Auto op anyone in any chan

our $VERSION = 0.01;

#irssi commands:
#   /autoop_help
#   /autoop_list
#   /autoop_add
#   /autoop_del
#   /autoop_set

my $autoop = AutoOp->new( db_file => $ENV{HOME}.'/.irssi/scripts/autoop.json' );

sub event_join {
    my ( $server, $channel, $nick, $address ) = @_;
    $channel =~ s#^:##g; #removes leading :
    if ( $autoop->should_op_nick( $channel, $nick, $address, $server->{chatnet} ) ) {
        Irssi::Server::command( $server, "mode $channel +o $nick" );
        #or $server->command( "mode $channel +o $nick" );
    }
}

sub cmd_nick_opped {
    my ( $server, $channel, $opped_by_nick, $hostname, $mode ) = @_;
    return if 
        !   $mode
        or  $channel !~ m|^#|
        and (
                $mode !~ m#^\+o#
            and $mode !~ m#^\-o#
            )
        ;
    my $chan = $server->channel_find( $channel );
    my $my_nick = $server->{ nick };

    my $opped_by_me = sub {
        my $nick = shift;
        return 
            $opped_by_nick eq $my_nick #i gave the ops ?
            and $nick ne $opped_by_nick  #and its not me
    };

    for ( $chan->nicks ) {
        next if $_->{nick} eq $my_nick;
        if ( $autoop->should_op_nick( $channel, $_->{nick}, $_->{host}, $server->{chatnet} ) ) {
            $server->channel_find($channel)->command("op $_->{nick}");
            #Irssi::Server::command( $server, qq"mode $channel +o $_->{nick}" );
            #or $server->command( "mode $channel +o $nick" );
            #warn "+o $_->{nick} in $channel";
        } else {
            # better dont deop anyone
           #$server->channel_find($channel)->command("deop $_->{nick}")
           #    if ( ! $opped_by_me->($_->{nick}) );
            #Irssi::Server::command( $server, qq"mode $channel -o $_->{nick}" );
            #warn qq"-o $_->{nick} in $channel";
        }
    }
}


sub cmd_autoop_help {
    Irssi::print( $autoop->help );
}

sub cmd_autoop_list {
    Irssi::print( $autoop->list );
}

sub cmd_autoop_add {
    my $nick = shift;
    Irssi::print( $autoop->add( $nick ) );
}

sub cmd_autoop_del {
    my $nick = shift;
    Irssi::print( $autoop->del( $nick ) );
}

sub cmd_autoop_set {
    my @args = split / +/, shift;
    my $nick = shift @args;
    my $action = shift @args;
    my $value = join " ", @args;
    Irssi::print( $autoop->set( $nick, $action, $value ) );
}

#SIGNAL ADD
Irssi::signal_add("event join", "event_join");
Irssi::signal_add('message irc mode',  'cmd_nick_opped');



#COMMAND_BIND
Irssi::command_bind('autoop_help', 'cmd_autoop_help');
Irssi::command_bind('autoop_list', 'cmd_autoop_list');
Irssi::command_bind('autoop_add',  'cmd_autoop_add');
Irssi::command_bind('autoop_del',  'cmd_autoop_del');
Irssi::command_bind('autoop_set',  'cmd_autoop_set');


Irssi::print("AutoOp $VERSION loaded - /autoop_help");

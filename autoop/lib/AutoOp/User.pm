package AutoOp::User;
use Moo;
use Perl6::Form;

has [qw|nick|] => ( is => 'rw' ); #user nick
has [qw|alternatives hostnames channels networks|] => ( is => 'rw', default => sub { [ ] } );

sub to_hash {
    my $self = shift;
    return {
        nick         => $self->nick,
        alternatives => $self->alternatives,
        hostnames    => $self->hostnames,
        channels     => $self->channels,
    };
}

sub stats {
    my $self = shift;
    return form "      {<<<<<<<<<<} {[[[[[[[[[[} {[[[[[[[[[[[[[[[[[[[[[[[[} {[[[[[[[[[[[[[[[[[[[[[[[[} {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
                        $self->nick,
                                    ( $self->alternatives||[''] ),
                                                 ( $self->channels||[''] ),
                                                                            ( $self->networks||[''] ),
                                                                                                       ( $self->hostnames||[''] )
    ;
}


sub matches {
    #trys to identify this user against $args->{chan}, $args->{nick} and $args->{host}
    my $self = shift;
    my $args = shift;
    
        if ( $self->chan_valid( $args->{ chan } )
    and      $self->nick_valid( $args->{ nick } )
    and      $self->network_valid( $args->{ network } )
    and      $self->host_valid( $args->{ host } ) ) {
        return 1;
    }
    return 0;
}

sub chan_valid {
    my $self = shift;
    my $chan = lc shift;
    #checks if this user should be opped in given chan
    return 1 if ( 
           grep /^\*$/, @{ $self->channels } # user has op in * chan
        or grep {
                lc $_ =~ m/^\Q$chan\E$/i
                    ? 1
                    : ()
                    ;
            } @{ $self->channels } # user has op in given chan
    );
    return 0;
}

sub nick_valid {
    my $self = shift;
    my $nick = shift;
    #checks if this nick is from this user
    return 1 if (
        $nick eq $self->nick
        or grep /^\Q$nick\E$/, @{ $self->alternatives }
        or grep /^\*$/, @{ $self->alternatives }
    );
    return 0;
}

sub host_valid {
    my $self = shift;
    my $host = shift;
    #checks if the given host is from this user and should be opped
    return 1 if (
            grep /^\Q$host\E$/, @{ $self->hostnames } #matches specific hostname
        or  grep /^\*$/, @{ $self->hostnames } #user has hostnames of *
    );

    for ( @{ $self->hostnames } ) {
        my $hostname = $_;
        if ( $hostname =~ m#\*#g ) {
            $hostname =~ s#\.#\\.#g;
            $hostname =~ s#\*#\.\*#g;
            if ( $host =~ m#$hostname#g ) {
                return 1;
            }
        }
    }
    return 0;
}

sub network_valid {
    my $self = shift;
    my $network = shift;
    #checks if the given host is from this user and should be opped
    return 0 if ! $network;
    return 1 if (
            grep /^\Q$network\E$/, @{ $self->networks }
        or  grep /^\*$/, @{ $self->networks }
    );

    for ( @{ $self->networks } ) {
        my $_network = $_;
        if ( $_network =~ m#\*#g ) {
            $_network =~ s#\.#\\.#g;
            $_network =~ s#\*#\.\*#g;
            if ( $network =~ m#$_network#g ) {
                return 1;
            }
        }
    }
    return 0;
}

1;

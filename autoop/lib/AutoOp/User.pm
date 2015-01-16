package AutoOp::User;
use Moo;
use Perl6::Form;

has [qw|nick alternatives hostnames channels|] => ( is => 'rw' ); #user nick

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
    return form "      {<<<<<<<<<<} {[[[[[[[[[[} {[[[[[[[[[[[[[[[[[[[[[[[[} {[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[[}",
                        $self->nick,
                                    ( $self->alternatives||[''] ),
                                                 ( $self->channels||[''] ),
                                                                            ( $self->hostnames||[''] )
    ;
}


sub matches {
    #trys to identify this user against $args->{chan}, $args->{nick} and $args->{host}
    my $self = shift;
    my $args = shift;
    
        if ( $self->chan_valid( $args->{ chan } )
    and      $self->nick_valid( $args->{ nick } )
    and      $self->host_valid( $args->{ host } ) ) {
        return 1;
    }
    return 0;
}

sub chan_valid {
    my $self = shift;
    my $chan = shift;
    #checks if this user should be opped in given chan
    return 1 if ( 
           grep /^\*$/, @{ $self->channels } # user has op in * chan
        or grep /^\Q$chan\E$/, @{ $self->channels } # user has op in given chan
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

1;

package AutoOp;
use Moo;
use JSON::XS qw|decode_json encode_json|;
use File::Slurp;
use Perl6::Form;
use AutoOp::User;
use DDP;

has db_file => ( is => 'rw', default => sub { 'autoop.json' } );
has json_db => ( is => "lazy", default => sub {
    my $self = shift;

    if ( -e $self->db_file ) {
        my $data = decode_json read_file $self->db_file;
        for ( keys %{ $data->{nick} } ) {
            my $user = AutoOp::User->new( $data->{nick}->{$_} );
            $data->{nick}->{ $_ } = $user;
        }
        return $data;
    }
    
    return { nick => { } };
} );

sub help {
    my $self = shift;
    return <<'HELP';
AutoOp - Help
Command                                                                     Description
list                                                                        Lists users added in autoop tool
add <nick>
set <nick> alternatives nick1 nick2 nick3                                   Identify the user with other nicks
set <nick> hostnames ~first@200.* ~second@1.2.3.4 ~third@domain.com         Multiple hostnames for this user
set <nick> hostnames *                                                      Any hostname for this user
set <nick> channels #chan1 #chan2 #chan3                                    Only op user in these channels
set <nick> channels *                                                       Op user in any channel
del <nick>                                                                  Remove nick from autoop db
HELP
}

sub save {
    my $self = shift;
    #persist $Self->json_db in file
    my $data = {nick=>{}};
    for ( keys %{ $self->json_db->{ nick } } ) {
        my $nick = $_;
        $data->{nick}->{$nick} = $self->json_db->{ nick }->{ $nick }->to_hash;
    }
    write_file $self->db_file, encode_json $data;
}

sub list {
    #There are currently N users added in autoop tool.
    #Num Nick      Alternatives   Channels        Hostnames
    #01  somEnick  oneAltNick     #achan1         ~first@200.*
    #              twoAltNick     #achan2         ~second@1.2.3.4
    #                             #achan3         ~third@domain.com
    #
    #02  someguy   oneAltNick     #achan1         ~first@200.*
    #                             #achan2         ~second@1.2.3.4
    #                             #achan3         ~third@domain.com
    my $self = shift;
    my $total_users = scalar keys %{ $self->json_db->{ nick } };
    my $out = form "There are currently $total_users users added in autoop tool.\n";
#   $out .= "There are currently $total_users users added in autoop tool.\n";
    return $out if $total_users == 0;
    my $counter = 1;
    $out .= form "      {<<<<<<<<<<} {<<<<<<<<<<} {<<<<<<<<<<<<<<<<<<<<<<<<} {<<<<<<<<<<<<<<<<<<<<<<<<} {<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<}",
                 (qw| Nick Alternatives Channels Networks Hostnames|);
    for ( sort keys %{ $self->json_db->{ nick } } ) {
        $out .= $self->json_db->{ nick }->{$_}->stats;
    }
    $out;
}

sub trim {
    my $self = shift;
    my $value = shift;
    $value =~ s#^(( |\s|\n|\t|\r)+)|(( |\s|\n|\t|\r)+)$##g;
    $value;
}

sub set {
    #set attr value
    my $self = shift;
    my $nick = $self->trim( shift );
    my $attribute = $self->trim(shift);
    my $value = shift;
    #ABSTRACT: Sets alternative nicks for $nick.
    #ie: alternatives('some_nick', 'alernativenick1 altnick2')
    return "You must pass a nick to set $attribute" if ! $nick;
    return "You must pass the action (hostnames,channels,alternatives) nick for $nick" if ! $attribute;
    return "Nick $nick not found in db. Add nick first" if ! exists $self->json_db->{ nick }->{ $nick };
    return "You must pass a value for $attribute" if ! defined $value;
    return "Action unkown $attribute " if ! $self->json_db->{ nick }->{ $nick }->can( $attribute );
    $self->json_db->{ nick }->{ $nick }->$attribute([map { $self->trim( $_ ) } split / +/, $value]);
    $self->save;
    return "Modified $nick $attribute to: $value";
}

sub add {
    #add nick to autoop tool
    my $self = shift;
    my $nick = $self->trim( shift );
    return "You must pass a nick to add" if ! $nick;
    if ( ! exists $self->json_db->{nick}->{ $nick } ) {
        $self->json_db->{ nick }->{ $nick } = AutoOp::User->new({
            nick         => $nick,
            hostnames    => [],
            alternatives => [],
            channels     => [],
        });
        $self->save;
        return "User $nick added";
    }
}

sub del {
    #delete nick from  autoop tool
    my $self = shift;
    my $nick = $self->trim( shift );
    return "You must pass a nick to del" if ! $nick;
    if ( exists $self->json_db->{ nick }->{ $nick } ) {
        delete $self->json_db->{ nick }->{ $nick };
        $self->save;
        return "User $nick deleted";
    } else {
        return "User $nick not found";
    }
}

sub should_op_nick {
    #this method should be called every time a user joins a channel
    my $self = shift;
    my $chan = $self->trim( shift );
    my $nick = $self->trim( shift );
    my $host = $self->trim( shift );
    my $network = $self->trim( shift );

    for ( keys %{ $self->json_db->{ nick } } ) {
        my $key_nick = $_;
        my $user = $self->json_db->{ nick }->{ $key_nick };
        return 1 if $user->matches( {
            chan => $chan,
            nick => $nick,
            host => $host,
            network => $network,
        } );
    }

    return 0;
}

1;

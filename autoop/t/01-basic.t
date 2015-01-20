use Test::More;
use AutoOp;
unlink 'tests_db.json';
my $autoop = AutoOp->new( db_file => 'tests_db.json' );

#help
#AutoOp tool v0.01 - Avaliable commands
#
# Command       Description
# list          Lists users added in autoop tool
# add <nick>
# set <nick> alternatives nick1 nick2 nick3
# set <nick> hostnames ~first@200.* ~second@1.2.3.4 ~third@domain.com
# set <nick> hostnames *
# set <nick> channels #chan1 #chan2 #chan3
# set <nick> channels *
# del <nick>
ok( $autoop->help =~ m|AutoOp - Help|, "test label" );
#
#list
#There are currently N users added in autoop tool.
#Num Nick      Alternatives   Channels        Hostnames
#01  somEnick  oneAltNick     #achan1         ~first@200.*
#              twoAltNick     #achan2         ~second@1.2.3.4
#                             #achan3         ~third@domain.com
#
#02  someguy   oneAltNick     #achan1         ~first@200.*
#                             #achan2         ~second@1.2.3.4
#                             #achan3         ~third@domain.com
ok( $autoop->list =~ m#There are currently 0 users#, "0 users" );

#add nick                   
#Added nick to autoop users

my $user1 = {
    nick        => 'Somenick',
    alternatives => "alt_nick othernick",
    hostnames   => '~first@200.* ~second@1.2.3.4 ~third@domain.com',
    channels    => "*",
    networks     => "_local _perl",
};

$autoop->add( $user1->{ nick } );

ok( $autoop->list =~ m#There are currently 1 users#, "1 user added" );

#set nick alternatives othernick thirdnick
#Modified nick alternatives to: othernick thirdnick
ok( 
    $autoop->set( "nick", 'alternatives', "altnick1 altnick2" )
    =~ m#Nick nick not found in db. Add nick first#, 
    "Nick not found" );

#set nick hostnames ~first@200.* ~second@1.2.3.4 ~third@domain.com
#Modified nick hostnames to: ~first@200.* ~second@1.2.3.4 ~third@domain.com
ok(
    $autoop->set( "nick", 'hostnames', '~first@200.* ~second@1.2.3.4 ~third@domain.com' )
    =~ m#nick not found#,
    "Nick not found"
);

{
    $autoop->set( $user1->{ nick }, 'alternatives', $user1->{ alternatives } );
    $autoop->set( $user1->{ nick }, 'hostnames', $user1->{ hostnames } );
    $autoop->set( $user1->{ nick }, 'channels', $user1->{ channels } );
    $autoop->set( $user1->{ nick }, 'networks', $user1->{ networks } );

    my $current_list = $autoop->list;

    my @lines = split "\n", <<'LINES';
There are currently 1 users added in autoop tool.
      Nick         Alternatives Channels                   Networks                   Hostnames
      Somenick     alt_nick     *                          _local                     ~first@200.*
                   othernick                               _perl                      ~second@1.2.3.4
                                                                                      ~third@domain.com
LINES
    for ( @lines ) {
        my $line = $_;
        ok( $current_list =~ m#\Q$line\E#g , ' line matched ' );
    }
}

{
    #set nick hostnames *
    #Modified nick hostnames to: *
    ok( $autoop->set( $user1->{ nick }, 'hostnames', '*' ) =~ m#Modified $user1->{ nick } hostnames to: *# , "modified hostname" );

    #list users after modify user hostnames
    my $current_list = $autoop->list;

    my @lines = split "\n", <<'LINES';
      Nick         Alternatives Channels                   Networks                   Hostnames
      Somenick     alt_nick     *                          _local                     *
                   othernick                               _perl

LINES
    for( @lines ) {
        my $line = $_;
        ok( $current_list =~ m#\Q$line\E#, "xx" );
    }
}

#set nick channels #chan1 #chan2 #chan3
#Modified nick channels to: #chan1 #chan2 #chan3

#set nick channels *
#Modified nick channels to: *

#del nick
#Deleted nick from autoop tool

ok( !$autoop->should_op_nick( "#somechan", "badnick", 'identd@1.2.3.4', '_local' ), "" );
ok( $autoop->should_op_nick( '#somechan', 'Somenick', '~bla@xxxxxxxxxxxx.com', '_local' ), '' );
ok( !$autoop->should_op_nick( '#somechan', 'unknown_nick', '~bla@xxxxxxxxxxxx.com', '_local' ), '' );
ok( $autoop->should_op_nick( '#somechan', 'Somenick', '~bla@200.201.202.203', '_local' ), '' );

{
    $autoop->set( $user1->{ nick }, 'hostnames', $user1->{ hostnames } );
    ok( !$autoop->should_op_nick( '#somechan', 'Somenick', '~bla@210.201.202.203', '_local' ), '' );
}

{
    $autoop->set( $user1->{ nick }, 'hostnames', $user1->{ hostnames } );
    $autoop->set( $user1->{ nick }, 'channels', '#chan1 #chan2' );
    ok( $autoop->should_op_nick( '#chan1', 'Somenick', '~second@1.2.3.4', '_local' ), '' );
    ok( $autoop->should_op_nick( '#chan1', 'Somenick', '~first@200.1.2.3', '_local' ), '' );
    ok(!$autoop->should_op_nick( '#chan3', 'Somenick', '~first@200.1.2.3', '_local' ), '' );
    ok(!$autoop->should_op_nick( '#chan3', 'Somenick', 'xxx@200.1.2.3', '_local' ), '' );

    $autoop->set( $user1->{ nick }, 'hostnames', "*@*" );
    ok( $autoop->should_op_nick( '#chan1', 'Somenick', 'xxx@200.1.2.3', '_local' ), '' );
    $autoop->set( $user1->{ nick }, 'hostnames', "*@1.2.3.4" );
    ok( $autoop->should_op_nick( '#chan1', 'Somenick', 'xxx@1.2.3.4', '_local' ), '' );
    ok(!$autoop->should_op_nick( '#chan1', 'Somenick', 'xxx@4.3.2.1', '_local' ), '' );
}

{
    #give op to user in any channel... add user to any channel
    $autoop->set( $user1->{ nick }, 'alternatives', "*" );
    #ok();
    ok( $autoop->should_op_nick( '#chan1', 'AnewNick', 'xxx@1.2.3.4', '_local' ), 'user is allowed to have * nicks.. so any nick with matched hostname and channel should be opped' );
}

{
    #autoop in specific channel
    $autoop->add( 'freeops_anychan' );
    $autoop->set( 'freeops_anychan', 'channels', '*' );
    $autoop->set( 'freeops_anychan', 'alternatives', '*' );
    $autoop->set( 'freeops_anychan', 'hostnames', '*@*' );
    $autoop->set( 'freeops_anychan', 'networks', '*' );
    ok( $autoop->should_op_nick( '#chandsa1', 'dasdasAnewNick', 'dsaxxx@1dsa.2.3.4', '_local' ), 'everyone gets ops' );
    $autoop->set( 'freeops_anychan', 'channels', '#specific_channel' );
    not( $autoop->should_op_nick( '#chandsa1', 'dasdasAnewNick', 'dsaxxx@1dsa.2.3.4', '_local' ), 'everyone gets ops' );
    ok(!$autoop->should_op_nick( '#chandsa1', 'dasdasAnewNick', 'dsaxxx@1dsa.2.3.4', '_local' ), 'everyone gets ops' );
    ok( $autoop->should_op_nick( '#specific_channel', 'XXXdasdasAnewNick', 'YYY@123.123.123.123', '_local' ), 'everyone gets ops' );
    ok( $autoop->should_op_nick( '#specific_channel', 'XXXdasdasZZZ', 'ZZZ@4.3.2.1', '_local' ), 'everyone gets ops' );
}

unlink 'tests_db.json';

done_testing;

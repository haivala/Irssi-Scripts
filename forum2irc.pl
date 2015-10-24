#!/usr/bin/perl
#
# Change the variables!
# ... That's about it, enjoy!
# 
use HTML::Entities;
use HTML::Strip;
use warnings;
use Irssi;
use DBI;
use vars qw($VERSION %IRSSI);
use strict;

if ($INC{'config.pl'}){ delete $INC{"config.pl"}; }
require 'config.pl';

$VERSION = "2.0";
%IRSSI = (
    authors => 'Harri Häivälä',
    contact => 'webmaster\@entropy.fi ',
    name => 'Mchat MYSQL table fetch to IRC',
    description => 'a IRSSI script for accessing an mchat mysql database through IRC',
    license => 'GNU GPL v2 or later',
    url => 'https://github.com/haivala/mChat-Irssi-Scripts'
);

# User Variables 
  my $d = get_database(); 
  my $u = get_databaseu(); 
  my $p = get_databasep();
  my $h = get_databaseh();
  my $mt = get_phpBB_table_prefix()."mchat"; 
  my $pu = get_phpBB_table_prefix()."users"; 
  my $pp = get_phpBB_table_prefix()."posts";
  my $pf = get_phpBB_table_prefix()."forums";
  my $baseurl = get_phpBB_base_url();
  my $url = get_phpBB_viewtopic_url(); 
  my $channel = get_irc_channel(); 
  my $cmd = get_react_cmd(); 

#Used Variables
  my $hs = HTML::Strip->new();
  my $howmany = 0;
  my $last = 0;
  my $now = 0;
  my ($queryFromMchat, @mchat, @users, @posts, @forum_name, @count);
  my ($mcmessage, $query, $users, $usernick, $rows, $topic, $messageToIRC, $dbh, $exed, $status);

sub chanmsg {
      my ($server, $data, $nick, $mask, $target) = @_;

      # Initialize or die
      if (($last == "0") or ($now < $last)){
        $last = $now = init();
        if ($last == -1){ # not configured properly
            Irssi::signal_remove('server event', 'chanmsg');
            Irssi::signal_remove('event privmsg', 'msgfromirc');
            return;
        }
      }
      # Check if there is new messages
      if ($now == $last){
        check();
      }

      if (($last != $now) and ($now > $last)) { # There is new messages
        $howmany = $now-$last;

        # Get the messages;
        $queryFromMchat = $dbh->prepare("(SELECT * FROM $mt order by message_id desc limit $howmany) order by message_id asc;");
        $exed = $queryFromMchat->execute;
        if ($exed >= 1) {
          while ( @mchat = $queryFromMchat->fetchrow_array() ) {
            $query = $dbh->prepare("select * from $pu where user_id=$mchat[1]");
            $exed = $query->execute;
            @users = $query->fetchrow_array();
            $query = $dbh->prepare("select * from $pp where post_id=$mchat[9]");
            $exed = $query->execute;
            @posts = $query->fetchrow_array();

            $mcmessage = "$mchat[3]\n";

            if (@posts >= 1){ # It's a new Post; Check for forum name
                $query = $dbh->prepare("select forum_name from $pf where forum_id=$posts[2]");
                $exed = $query->execute;
                @forum_name = $query->fetchrow_array( );
            
                if (($mcmessage =~ m/New Reply/) or ($mcmessage =~ m/New Topic/) or ($mcmessage =~m/a Quote/)){ # In any case
                    $topic = decode_entities($posts[13]);
                    if ($topic =~ m/Re:/){
                        $topic = substr($topic, 4);
                    }
                    @forum_name = decode_entities($forum_name[0]);
                    $messageToIRC = "\x02Forum\x02: @forum_name \x02Post\x02: $topic | $url$mchat[9]";
                }
            }
            else {
              $mcmessage = decode_entities($mcmessage);
              if ($mcmessage =~ m/viewtopic.php/) { # when forums own post is pasted to mChat It has to have whole url in irc
                    $mcmessage =~ s{viewtopic.php}{$baseurl/viewtopic.php}g;
              }
              $mcmessage = $hs->parse( $mcmessage );
              $messageToIRC ="\x02$users[7]\x02: ".$mcmessage;
            }
            $server->command ( "msg $channel $messageToIRC");
            $hs->eof;
            $last=$now;
         }
       } 
    }
}

sub init {
    if(connectmysql()==1){
        Irssi::print("MYSQL Connected");
    }
    else {
            Irssi::print("MYSQL says NO!. Is this script properly configured? Is the mysql server started? BYE BYE! I'll DIE NOW..\n");
            return -1;
    }
    $query = $dbh->prepare("SELECT count(message_id) FROM $mt;");
    $rows = $query->execute;
    @count = $query->fetchrow_array(  );
    return ( "$count[0]");
}
sub check {
    checkmysqlconnection();
    if ($status==0) {
        return;
    }
    $query = $dbh->prepare("SELECT count(message_id) FROM $mt;");
    $rows = $query->execute;
    @count = $query->fetchrow_array(  );
    $now = "$count[0]";

    if ($now =="1") {$last = init();} # Mchat messages purged
}

sub checkmysqlconnection {
    if($status==1){
        unless($dbh->ping){
            Irssi::print("MYSQL says NO!. Reconnecting..");
            $status=connectmysql();
        }
    }
    else { 
        if (connectmysql()==1){
            Irssi::print("MYSQL Connected");
        }
    }
}

sub connectmysql {
    #Irssi::print("$d, $u , $p");
    $dbh = DBI->connect("DBI:mysql:$d:$h","$u","$p") or return 0;
    $dbh->{'mysql_enable_utf8'} = 1;
    $dbh->do(qq{SET NAMES 'utf8';});
    $status=1;
    return 1;
}

sub msgfromirc { #If someone sends message from IRC to mchat don't echo that to the channel
	my ($server, $data, $nick, $mask, $target) =@_;
	my ($ircnick, $text) = $data =~ /^(\S*)\s:(.*)/;
	  if ($text =~ /^$cmd[:,\;\-] */i ) {
		$last=$now=$last+1;
        #$server->command ( "msg $channel script:forum2irc funtion:msgfromirc last: $last now: $now");
	  }	
}


Irssi::signal_add('event privmsg', 'msgfromirc');
Irssi::signal_add('server event', 'chanmsg');

#!/usr/bin/perl
#
# In phpBB you need to make custom profile field called "irc_nick" this to work.
# ... That's about it, enjoy!
# 

#use strict;
use warnings;
use Irssi;
use DBI;
use strict;

use utf8;
use encoding 'utf8';
use vars qw($VERSION %IRSSI);

if ($INC{'config.pl'}){ delete $INC{"config.pl"}; }
require 'config.pl';

$VERSION = "1.0";
%IRSSI = (
    authors => 'TheH',
    contact => 'webmaster\@entropy.fi ',
    name => 'IRC to mChat integration',
    description => 'a script for accessing an mchat mysql database through irc',
    license => 'tell me if you use it?',
    url => 'https://github.com/haivala/mChat-Irssi-Scripts'
);

  my $d = get_database();
  my $u = get_databaseu();
  my $p = get_databasep();
  my $h = get_databaseh();
  my $cmd = get_react_cmd();

  # Variables
  my ($dbh, $mes2f, $query, $exec, $t, $ip, $text);
  my (@users, @nicksearch);

sub msg2forum { 
  my ($server, $data, $nick, $mask, $target) =@_;
  my ($nickfromirc, $text) = $data =~ /^(\S*)\s[:,\;\-](.*)/;
  if ($text =~ /^$cmd[:,\;\-\s](.*)/i ) {
	($mes2f) = $text =~ /^$cmd[:,\;\-\s](.*)/i;
    $dbh = DBI->connect("DBI:mysql:$d:$h","$u","$p") or return Irssi::print('No MYSQL connection');
	$dbh->{'mysql_enable_utf8'} = 1;
    $dbh->do(qq{SET NAMES 'utf8';});
    $query = $dbh->prepare("SELECT * FROM phpbb_profile_fields_data where pf_irc_nick like \"$nick%\";");
    $exec = $query->execute;
 	if ($exec == 1){
	    @nicksearch = $query->fetchrow_array(  );
		$mes2f = $dbh->quote($mes2f);
	    $query = $dbh->prepare("SELECT * FROM phpbb_users where user_id=$nicksearch[0];");
        $exec = $query->execute;
		if ($exec==1){
		    @users = $query->fetchrow_array(  );
            $t = time();
		    $ip = $users[5];
		    if (!$ip) {$ip = "0.0.0.0";}
            $query = "INSERT INTO phpbb_mchat (forum_id, post_id, user_id, user_ip, bbcode_options, message, message_time) VALUES (0,0,$nicksearch[0],\"$users[5]\",5,$mes2f,$t);";
            #$server->command ( "msg $nick ip: $ip, $nicksearch[0],\"$users[5]\",5,mes2f:$mes2f,text: $text, $t");
	        $query = $dbh->prepare("$query");
	        $exec = $query->execute;
            #$server->command ( "msg $nick viesti menny forumille");
		}
 	}
    elsif ($exec == 0) {  $server->command ( "msg $nick You have to set right IRC nick to your profile settings in the phpBB forum!"); }
 }
 else { }
}

Irssi::signal_add('event privmsg', 'msg2forum');

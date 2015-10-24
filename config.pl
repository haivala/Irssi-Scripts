#!/usr/bin/perl
use strict;
use warnings;

# Change only return values!

# MSQL Database name
sub get_database { return 'database'; } 
# MSQL Database user with read rights
sub get_databaseu { return 'user'; } 
# MSQL Database password 
sub get_databasep { return 'password'; } 
# MSQL Database host
sub get_databaseh { return 'localhost'; }

# phpBB table prefix: can be found in phpBB install dirs config.php
sub get_phpBB_table_prefix { return 'phpbb_'; }
# Base Url for accessing the phpBB forum without trailing slash
sub get_phpBB_base_url { return "http://example.org/phpBB3"; }

# Url that is echoed to IRC.
# TIP: Use apache rewrite rule to make it more simple? ie http://example.org/t/ and translate that to ..viewtopic.php?p=number#number to get it properly working
sub get_phpBB_viewtopic_url { return "http://example.org/phpBB3/viewtopic.php?p="; } 

# Irc channel/nick where the messages are posted
sub get_irc_channel { return "#example"; }

# nick/identifier to react when someone is sending message from IRC to mChat (uses another script to actually do that)
sub get_react_cmd { return "myforumnick"; } 
1;


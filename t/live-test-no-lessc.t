#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib2";

BEGIN {
    $ENV{TESTAPP_CONFIG} = '{ "CatalystX::Less" => { no_lessc => 1 }, "static" => { "include_path" => ["t/lib2/alt_root", "t/lib2/TestApp/root"] } }';
};

# make sure testapp works
use TestApp;

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';

my $mech = Test::WWW::Mechanize::Catalyst->new;

$mech->get_ok('http://localhost/', 'get main page');
$mech->content_contains("static/less.js");
$mech->follow_link_ok({url_regex => qr/\.less$/}, "Can follow the less link");
$mech->back;
$mech->get_ok('http://localhost/static/less.js');
$mech->content_contains("LESS - Leaner CSS v1.3.0", "right less.js");

done_testing;

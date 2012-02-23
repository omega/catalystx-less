#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
    $ENV{TESTAPP_CONFIG} = '{ "CatalystX::Less" => { "max_age" => 3600 } }';
};

# make sure testapp works
use ok 'TestApp';

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';
my $mech = Test::WWW::Mechanize::Catalyst->new;
$mech->get_ok('http://localhost/', 'get main page');
$mech->content_like(qr/it works/i, 'see if it has our text');
$mech->follow_link_ok({url_regex => qr/\.css$/}, "Can follow the css link");

is($mech->ct, "text/css", "right content type");
is($mech->res->header('Cache-Control'), 's-maxage=3600', "right cache-control");

$mech->content_contains("h1 span");
$mech->content_contains("font-family:");

done_testing;


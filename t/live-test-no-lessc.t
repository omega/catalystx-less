#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use Spawn::Safe;
if(!spawn_safe({ argv => [qw{ lessc }], timeout => 2 })->{error}) { plan skip_all => 'Found lessc so tests are meaningless.'; }

# setup library path
use FindBin qw($Bin);
use lib "$Bin/lib2";

BEGIN {
    $ENV{TESTAPP_CONFIG} = '{ "static" => { "include_path" => ["t/lib2/alt_root", "t/lib2/TestApp/root"] } }';
};

# make sure testapp works
use_ok('TestApp');

# a live test against TestApp, the test application
use Test::WWW::Mechanize::Catalyst 'TestApp';

my $mech = Test::WWW::Mechanize::Catalyst->new;

$mech->get_ok('http://localhost/', 'get main page');
note($mech->content);
$mech->content_contains("cloudhead/less.js");
$mech->follow_link_ok({url_regex => qr/\.less$/}, "Can follow the less link");

done_testing;

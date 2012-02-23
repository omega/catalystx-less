package TestApp;
use Moose;
use namespace::autoclean;
our $VERSION = '0.01';
use Catalyst qw/+CatalystX::Less Static::Simple/;

extends 'Catalyst';
__PACKAGE__->config(eval ($ENV{TESTAPP_CONFIG} || '{}'));
__PACKAGE__->setup;

1;

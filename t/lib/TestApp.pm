package TestApp;
use Moose;
use namespace::autoclean;

use Catalyst qw/+CatalystX::Less/;

extends 'Catalyst';
__PACKAGE__->config();
__PACKAGE__->setup;

1;

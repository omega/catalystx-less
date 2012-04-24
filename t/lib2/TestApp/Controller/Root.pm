package TestApp::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(
    namespace => q{},
    less_js_path => "https://github.com/cloudhead/less.js/blob/master/dist/less-1.3.0.min.js"
);

sub base : Chained('/') PathPart('') CaptureArgs(0) {}

# your actions replace this one
sub main : Chained('base') PathPart('') Args(0) {
    my ($self, $ctx) = @_;
    my $less = $ctx->less_for('base.less', 'fonts.less');
    $ctx->res->body($less . '<h1>It works</h1>');
}

__PACKAGE__->meta->make_immutable;

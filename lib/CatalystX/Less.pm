package CatalystX::Less;
#ABSTRACT: Provide easy access to less as css

=head1 SYNOPSIS

    # in YourApp.pm
    use Catalyst qw/+CatalystX::Less/;

    # in root/wrapper.tt
    <link rel="stylesheet" href="[% c.uri_for_combined_less('base.less', 'fonts.less') %]"></link>

=head1 JUSTIFICATION

Working with LESS is much prefered by most front end developers, but getting
the toolchain just right for everyone can be a chore. What we do here, is we
set up a less compiler endpoint in the app. This end point compiles the less
into css on request. In our production environment we just cache this with
varnish, so the added time isn't an issue.

=cut



use Moose::Role;
use namespace::autoclean;
use CatalystX::InjectComponent;

after 'setup_components' => sub {
    my $class = shift;
    CatalystX::InjectComponent->inject(
        into => $class,
        component => 'CatalystX::Less::Controller::LessCompiler',
        as => 'Controller::Less',
    );
};

=method uri_for_combined_less(@less_files)

This will return a special url to the (auto-magical) LessCompiler controllers
less action. The url will include parts of the filenames.


=cut

sub uri_for_combined_less {
    my $c = shift;
    my $cfg = $c->config->{'CatalystX::Less'};
    my $basepath = $cfg->{base_path} || '/less';

    my @lesses = @_;

    # We strip out .less and join by ; for now
    my $encoded = join(";", (map { s/\.less$//; $_;} @lesses));
    my $uri = $c->uri_for($c->controller('Less')->action_for('less'),  $encoded  . ".css");
    return $uri;
}

1;





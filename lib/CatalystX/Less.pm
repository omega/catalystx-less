package CatalystX::Less;
#ABSTRACT: Provide easy access to less as css

=head1 SYNOPSIS

    # in YourApp.pm
    use Catalyst qw/+CatalystX::Less/;

    # in root/wrapper.tt
    <link rel="stylesheet" href="[% c.uri_for_combined_less('base.less', 'fonts.less') %]"></link>

    # or
    [% c.less_for('base.less', 'fonts.less') %]

=head1 JUSTIFICATION

Working with LESS is much prefered by most front end developers, but getting
the toolchain just right for everyone can be a chore. What we do here, is we
set up a less compiler endpoint in the app. This end point compiles the less
into css on request. In our production environment we just cache this with
varnish, so the added time isn't an issue.

=head1 WORKING WITH OTHERS

If we find the (albeit private) method C<_locate_static_file> on C<$c>, we will
use this to locate static files. This makes sure we search all the folders that
the static plugin does.

=head1 CONFIGURATION

We expose some config options, you can put that in a C<CatalystX::Less> section
of your config

In YourApp.pm file (default config):

    __PACKAGE__->config(
        'CatalystX::Less' => {
            version_path => 1,
        }
    );

In yourapp.yml (or yourapp_local.yml)

    CatalystX::Less:
        version_path: 1

=head2 max_age seconds

If this config is set, we add a C<Cache-Control> header to the css response. This
value should be supplied in seconds. This value is respected by Varnish for instance

=head2 version_path true|false

This defaults to true, and will include the C<$YourApp::VERSION> in the url.
The reasoning is that this makes cache handling easier. If you release your app
and bump the version, it will automatically expire the css caches in clients,
because the path is different.

NOTE that there is nothing for maintaining the old paths.

If you do not have a $VERSION defined, it will be as if the version_path was
set to false

=head2 no_lessc true|false

If set to false, we will never use or look for C<lessc>, enabling the JS
fallback by default

=head2 less_js_url /static/less.js

If we have no lessc, or no_lessc is true, we fall back to a javascript
solution. By default we will serve the less.js version we bundle, but if for
some reason you want to do that yourself, set the url here

=cut



use Moose::Role;
use namespace::autoclean;
use CatalystX::InjectComponent;
use Spawn::Safe;

after 'setup_components' => sub {
    my $class = shift;
    my $impl;
    if ($class->config->{'CatalystX::Less'}->{no_lessc}) {
        $class->log->debug("Not using lessc, per config") if $class->debug;
        $impl = "_less_for_no_lessc";
    } elsif(my $error = spawn_safe({ argv => [qw{ lessc }], timeout => 2 })->{error}) {
        $class->log->debug("COuld not use lessc: " . $error) if $class->debug;
        $impl = "_less_for_no_lessc";
    } else {
        $class->log->debug("Using lessc!") if $class->debug;
        $impl = "_less_for_lessc";
    }

    {
        no strict 'refs';
        *{$class . "::less_for"} = \*{$class . "::${impl}"};
    }
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
    my @args;
    my @lesses = @_;

    # We strip out .less and join by ; for now
    my $encoded = join(";", (map { s/\.less$//; $_;} @lesses));

    push(@args, $encoded . ".css");

    my $action = $c->controller('Less')->action_for('less_to_css');
    if ($c->VERSION and (not defined($cfg->{version_path}) or $cfg->{version_path})) {
        $action = $c->controller('Less')->action_for('less_to_css_versioned');
        unshift(@args, $c->VERSION);
    }

    my $uri = $c->uri_for($action,@args);
    return $uri;

}

sub _less_for_lessc {
    my $c = shift;

    return "<link href=\"". $c->uri_for_combined_less(@_) ."\" type=\"text/css\">";
}
sub _less_for_no_lessc {
    my $c = shift;

    # TODO: configurable?
    my $lessc_path = $c->config->{'CatalystX::Less'}->{less_js_url} ||
        $c->uri_for('/static/less.js');
    my $ret = "<script src=\"".$lessc_path."\" type=\"text/javascript\"></script>";
    foreach my $less (@_) {
        # TODO: hardcoded
        $ret = $ret . "<link href=\"". $c->uri_for("/static/less/".$less) ."\" type=\"text/less\">";
    }
    return $ret;
}

1;





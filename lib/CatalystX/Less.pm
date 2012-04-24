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
            less_js_path => "https://github.com/cloudhead/less.js/blob/master/dist/less-1.3.0.min.js"
        }
    );

In yourapp.yml (or yourapp_local.yml)

    CatalystX::Less:
        version_path: 1
        less_js_path: https://github.com/cloudhead/less.js/blob/master/dist/less-1.3.0.min.js

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

=cut



use Moose::Role;
use namespace::autoclean;
use CatalystX::InjectComponent;
use Spawn::Safe;

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

sub less_for {
	my $c = shift;
	my $ret;
	my $cfg = $c->config->{'CatalystX::Less'};
	
	if(not defined($cfg->{node_js_path})) {
		$c->config->{'CatalystX::Less'}{node_js_path} = "https://github.com/cloudhead/less.js/blob/master/dist/less-1.3.0.min.js";
	}
	
	if(_has_lessc($c)) {
		$ret = "<link href=\"". $c->uri_for_combined_less(@_) ."\" type=\"text/css\">";
	} else {
		# TODO: configurable?
		$ret = "<script src=\"".$cfg->{node_js_path}."\" type=\"text/javascript\"></script>";
	    foreach my $less (@_) {
	    	# TODO: hardcoded
	    	$ret = $ret . "<link href=\"". $c->uri_for("/static/less/".$less) ."\" type=\"text/less\">";
	    }
	}
	return $ret;
}

sub _has_lessc {
    my $c = shift;
    my $cfg = $c->config->{'CatalystX::Less'}{has_lessc};
    if(not defined($cfg)) {
    	my $results = spawn_safe({ argv => [qw{ lessc }], timeout => 2 });
	    if($results->{error}) {
	    	$c->log->warn('Cannot use lessc: '.$results->{error});
		    $c->config->{'CatalystX::Less'}{has_lessc} = 0;
	    } else {
		    $c->config->{'CatalystX::Less'}{has_lessc} = 1;
	    }
    }
    return $cfg;
}

1;





package CatalystX::Less::Controller::LessCompiler;
#ABSTRACT: Compile a bunch of less files to a css file
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' };
use Spawn::Safe;
use Path::Class::File qw();

=method less file;file2

Will try to locate the less directory (default is root/static/less), and then
compile and concatenate the less into css.

=cut

sub less_to_css_versioned : Path('/static/less_to_css') Args(2) {
    my ($self, $c, $version, $files) = @_;
    if ("$version" ne $c->VERSION) {
        $c->log->debug("Version missmatch in less compiler, old cached link?");
    }
    $c->forward('less_to_css', [$files]);

}
sub less_to_css : Path('/static/less_to_css') Args(1) {
    my ($self, $c, $files) = @_;

    $files =~ s/\.css$//;
    my @files = map { $_ . '.less' } split(";", $files);
    # compile and return
    my $cfg = $c->config->{'CatalystX::Less'};

    $c->res->content_type('text/css');
    if ($cfg->{max_age}) {
        $c->res->header('Cache-Control' => 's-maxage=' . $cfg->{max_age});
    }

    # TODO: Put in support for using $c->cache if it exists
    my $base_folder = $cfg->{base_folder} || 'root/static/less/';

    # If the config is absolute path, leave it alone
    $base_folder = $c->path_to($base_folder) unless $base_folder =~ m|^/|;

    foreach my $file (@files) {
        my $full = $self->_find_less_file($c, $file, $base_folder);
        unless (-f $full) {
            $c->log->warn("LESS: $full not found, skipping");
            next;
        }
        my $results = spawn_safe({ argv => ['lessc', $full], timeout => 2 });
        $c->res->print($results->{stdout});
    }
}

sub _find_less_file {
    my ($self, $c, $file, $base_folder) = @_;

    if ($c->can('_locate_static_file')) {
        # Enter Static::Simple mode!
        # XXX: Hardcoded, BAD!
        return Path::Class::File->new($c->_locate_static_file('static/less/' . $file));
    } else {
        # old skool!
        return Path::Class::File->new($base_folder, $file);
    }
}

# Just to make sure nothing else gets done
sub end : Private {}
1;



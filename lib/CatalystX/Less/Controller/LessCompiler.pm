package CatalystX::Less::Controller::LessCompiler;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' };
use CSS::LESSp;
use Path::Class::File qw();

sub less : Path('') Args(1) {
    my ($self, $c, $files) = @_;
    $files =~ s/\.css$//;
    my @files = map { $_ . '.less' } split(";", $files);
    # compile and return
    my $cfg = $c->config->{'CatalystX::Less'};
    my $base_folder = $cfg->{base_folder} || 'root/static/less/';

    # If the config is absolute path, leave it alone
    $base_folder = $c->path_to($base_folder) unless $base_folder =~ m|^/|;

    $c->res->content_type('text/css');
    foreach my $file (@files) {
        my $full = Path::Class::File->new($base_folder, $file);
        unless (-f $full) {
            $c->log->warn("LESS: $full not found, skipping");
            next;
        }

        my $in = $full->openr;
        $c->res->print(CSS::LESSp->parse(join("\n", $in->getlines)));
    }
}
1;



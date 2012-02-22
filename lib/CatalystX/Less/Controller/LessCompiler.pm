package CatalystX::Less::Controller::LessCompiler;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' };
use CSS::LESSp;

sub less : Path('') Args(1) {
    my ($self, $c, $files) = @_;
    $files =~ s/\.css$//;
    my @files = map { $_ . '.less' } split(";", $files);
    # compile and return
    $c->res->body(join("\n", @files));
}
1;



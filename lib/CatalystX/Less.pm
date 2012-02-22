package CatalystX::Less;
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
sub uri_for_combined_less {
    my $c = shift;
    my $cfg = $c->config->{'CatalystX::Less'};
    my $basepath = $cfg->{base_path} || '/less';

    my @lesses = @_;

    # We strip out .less and join by ; for now
    my $encoded = join(";", (map { s/\.less$//; $_;} @lesses));
    my $uri = $c->uri_for('/less',  $encoded  . ".css");
    return $uri;
}

1;

=head1 NAME

CatalystX::Less - 

=head1 DESCRIPTION

=head1 METHODS

=head1 BUGS

=head1 AUTHOR

=head1 COPYRIGHT & LICENSE

Copyright 2009 the above author(s).

This sofware is free software, and is licensed under the same terms as perl itself.

=cut


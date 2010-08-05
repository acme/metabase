package Metabase::Index::ElasticSearch;
use Moose;
use ElasticSearch;
use SQL::Abstract;
use Try::Tiny;

our $VERSION = '0.004';

with 'Metabase::Index';

has 'elasticsearch' => (
    is       => 'ro',
    isa      => 'ElasticSearch',
    required => 1,
    default  => sub {
        ElasticSearch->new(
            servers => 'localhost:9200',

            #    trace_calls => 'log_file',
            #    debug       => 1,
        );
    },
);

sub add {
    my ( $self, $fact ) = @_;

    Carp::confess("can't index a Fact without a GUID") unless $fact->guid;

    my $metadata = $self->clone_metadata($fact);

    $self->elasticsearch->index(
        index => 'metabase',
        type  => 'fact',
        id    => lc $fact->guid,
        data  => $metadata,
    );
}

sub search {
    my ( $self, %spec ) = @_;

    my $results = $self->elasticsearch->search(
        index  => 'metabase',
        type   => 'fact',
        query  => { field => \%spec },
        fields => ['core.guid'],
    );

    my @results = map { $_->{_id} } @{ $results->{hits}->{hits} };
    return \@results;

}

sub exists {
    my ( $self, $guid ) = @_;
    return scalar @{ $self->search( 'core.guid' => lc $guid ) };
}

# DO NOT lc() GUID
sub delete {
    my ( $self, $guid ) = @_;
    Carp::confess("can't delete without a GUID") unless $guid;

    $self->elasticsearch->delete(
        index => 'metabase',
        type  => 'fact',
        id    => $guid,
    );
}

1;

__END__

=for Pod::Coverage::TrustPod add search exists

=head1 NAME

Metabase::Index::ElasticSearch - Metabase ElasticSearch index

=head1 SYNOPSIS

  require Metabase::Index::ElasticSearch;
  Metabase::Index:ElasticSearch->new();

=head1 DESCRIPTION

Metabase index using ElasticSearch.

=head1 USAGE

See L<Metabase::Index> and L<Metabase::Librarian>.

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.
Bugs can be submitted through the web interface at
L<http://rt.cpan.org/Dist/Display.html?Queue=Metabase>

When submitting a bug or request, please include a test-file or a patch to an
existing test-file that illustrates the bug or desired feature.

=head1 AUTHOR

=over

=item *

Leon Brocard (acme)

=back

=head1 COPYRIGHT AND LICENSE

Portions Copyright (c) 2010 by Leon Brocard

Licensed under terms of Perl itself (the "License").
You may not use this file except in compliance with the License.
A copy of the License was distributed with this file or you may obtain a
copy of the License from http://dev.perl.org/licenses/

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package SWISH::API::More::MetaList;
use strict;
use warnings;
use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( ml base ));

my $loaded = 0;
sub setup
{
    return if $loaded++;
    SWISH::API::More::native_wrappers(
        [
            qw(
              Name Type ID
              )
        ],
        __PACKAGE__,
        'ml'
                            );
}

1;

__END__

=head1 NAME

SWISH::API::More::MetaList - do more with SWISH::API::MetaList

=head1 SYNOPSIS

See SWISH::API::MetaList.

=head1 SEE ALSO

L<http://swish-e.org/>

L<SWISH::API>, L<SWISH::API::More>

=head1 AUTHOR

Peter Karman, E<lt>karman@cpan.orgE<gt>

Thanks to L<Atomic Learning|http://www.atomiclearning.com/> for supporting some
of the development of this module.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

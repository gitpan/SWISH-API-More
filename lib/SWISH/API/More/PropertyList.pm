package SWISH::API::More::PropertyList;
use strict;
use warnings;
use Carp;
use Data::Dump qw(pp);
use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( pl base ));

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
        'pl'
                            );
}

1;

__END__

=head1 NAME

SWISH::API::More::PropertyList - do more with SWISH::API::PropertyList

=head1 SYNOPSIS

See SWISH::API::PropertyList.

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

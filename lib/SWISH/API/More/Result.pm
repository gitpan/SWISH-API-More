package SWISH::API::More::Result;
use strict;
use warnings;
use base qw( Class::Accessor::Fast );
__PACKAGE__->mk_accessors(qw( result base ));

my $loaded = 0;
sub setup
{
    return if $loaded++;
    SWISH::API::More::native_wrappers(
        [
            qw(
              Property ResultPropertyStr ResultIndexValue
              FuzzyMode
              )
        ],
        __PACKAGE__,
        'result'
                                    );
}

sub fuzzy_word { shift->fw(@_) }
sub FuzzyWord  { shift->fw(@_) }

sub fw
{
    my $self = shift;
    my $fw   = $self->result->FuzzyWord(@_);
    return $self->base->whichnew('FuzzyWord')
      ->new({fw => $fw, base => $self->base});
}

sub MetaList  { shift->ml(@_) }
sub meta_list { shift->ml(@_) }

sub ml
{
    my $self = shift;
    my $ml   = $self->result->MetaList(@_);
    return $self->base->whichnew('MetaList')
      ->new({ml => $ml, base => $self->base});
}

sub PropertyList  { shift->pl(@_) }
sub property_list { shift->pl(@_) }

sub pl
{
    my $self = shift;
    my $pl   = $self->result->PropertyList(@_);
    return $self->base->whichnew('PropertyList')
      ->new({pl => $pl, base => $self->base});
}

1;

__END__

=head1 NAME

SWISH::API::More::Result - do more with SWISH::API::Result

=head1 SYNOPSIS

See SWISH::API::Result.

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

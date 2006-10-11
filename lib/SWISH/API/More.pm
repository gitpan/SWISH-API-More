package SWISH::API::More;

use strict;
use warnings;
use SWISH::API;
use Carp;
use Data::Dump qw/pp/;
use base qw/ Class::Accessor::Fast /;

our $VERSION = '0.02';

__PACKAGE__->mk_accessors(
    qw/
      indexes
      log
      /
);

sub _dispSymbols
{
    my ($hashRef) = shift;
    for (sort keys %$hashRef)
    {
        printf("%-20.20s| %s\n", $_, $hashRef->{$_});
    }
}

# for each class and subclass in SWISH::API
# typeglob each method to a closure
# that passes the enclosing object on to the SUPER equivalent

# this is the hard way. the easy way would be 'use base "SWISH::API"'
# but because it's all XS, the swish_handle is always just a blessed C pointer
# and not our friendly blessed Perl hashref

sub wrap_methods
{
    my $self = shift;
    my $w    = shift || $self->{wrappers} || {};

    return if $self->{_wrap_methods_called}++;

    #carp "thisclass = $self->{_thisclass}";
    #carp "thispackage = $self->{_thispackage}";
    #carp "thissubclass = $self->{_thissubclass}";

    no strict;
  SUBCLASS: for my $class (grep { m/::$/ } keys %SWISH::API::)
    {

        local *c = $SWISH::API::{$class};
        (my $classname = $class) =~ s,::$,,;
        my $subclass = $self->{_thisclass} . '::' . $classname;

        next SUBCLASS if $classname eq $self->{_thissubclass};
        next SUBCLASS if $classname eq $self->{_thispackage};

      METH: foreach my $meth (keys %c)
        {
            next METH if $meth eq 'DESTROY';    # special name

            next METH if $subclass->can($meth); # explicitly defined

            #$self->logger("$subclass cannot -> $meth") if $self->log;

            my $sub = $w->{$classname} || sub { };

            *{"${subclass}::${meth}"} = sub {
                my $sam = shift;
                $sub->($sam, @_);

                # alias the original method to just pass on what we got
                *{'SWISH::API::' . $class . $meth}->($sae, @_);
            };

        }

        #carp "$class Symbol table";
        #_dispSymbols(\%{"${subclass}::"});
    }

  CLASS: for my $meth (grep { !m/::$/ } keys %SWISH::API::)
    {

        next CLASS if $meth eq 'DESTROY';    # special name

        next CLASS if $self->{_thisclass}->can($meth);    # explicitly defined

        #$self->logger("$self->{_thisclass} cannot -> $meth") if $self->log;

        my $sub = $w->{$self->{_thisclass}} || sub { };

        *{$self->{_thisclass} . "::${meth}"} = sub {
            my $sam = shift;
            $sub->($sam, @_);
            *{'SWISH::API::' . $meth}->($sam->handle, @_);

        };

    }

    #carp "$thisclass Symbol table";
    #_dispSymbols(\%{$thisclass . '::'});
    #carp "$thisclass can -> abort_last_error"
    #  if $thisclass->can('abort_last_error');
}

sub make_methods
{
    my $self = shift;
    my $w    = shift || $self->{wrappers} || {};

    return if $self->{_make_methods_called}++;

    #carp "thisclass = $self->{_thisclass}";
    #carp "thispackage = $self->{_thispackage}";
    #carp "thissubclass = $self->{_thissubclass}";

    no strict;
  SUBCLASS: for my $class (grep { m/::$/ } keys %SWISH::API::)
    {

        local *c = $SWISH::API::{$class};
        (my $classname = $class) =~ s,::$,,;
        my $subclass = $self->{_thisclass} . '::' . $classname;

        next SUBCLASS if $classname eq $self->{_thissubclass};
        next SUBCLASS if $classname eq $self->{_thispackage};

      METH: foreach my $meth (keys %c)
        {
            next METH if $meth eq 'DESTROY';    # special name

            #$self->logger("checking $subclass -> $meth");

            my $before = $subclass->can($meth . '_before');
            my $after  = $subclass->can($meth . '_after');

            if ($before && $after)
            {

                #$self->logger("$subclass ->can $meth _before && _after");

                my $orig = *{'SWISH::API::' . $class . $meth};

                undef *{'SWISH::API::' . $class . $meth};

                *{'SWISH::API::' . $class . $meth} = sub {
                    my @r = $before->($self, @_);
                    if (@r && defined $r[0])
                    {
                        @r = $orig->(@r);
                    }
                    else
                    {
                        @r = $orig->(@_);
                    }
                    $after->($self, $orig, [@_], [@r]);
                };

            }
            elsif ($before)
            {

                #$self->logger("$subclass ->can $meth _before");

                my $orig = *{'SWISH::API::' . $class . $meth};

                undef *{'SWISH::API::' . $class . $meth};

                *{'SWISH::API::' . $class . $meth} = sub {
                    my @r = $before->($self, @_);
                    if (@r && defined $r[0])
                    {
                        $orig->(@r);
                    }
                    else
                    {
                        $orig->(@_);
                    }
                };

            }
            elsif ($after)
            {

                #$self->logger("$subclass ->can $meth _after");

                my $orig = *{'SWISH::API::' . $class . $meth};

                undef *{'SWISH::API::' . $class . $meth};

                *{'SWISH::API::' . $class . $meth} = sub {
                    my @r = $orig->(@_);
                    $after->($self, $orig, [@_], [@r]);
                };

            }

        }

        #carp "$class Symbol table";
        #_dispSymbols(\%{"${subclass}::"});
    }

  CLASS: for my $meth (grep { !m/::$/ } keys %SWISH::API::)
    {

        next CLASS if $meth eq 'DESTROY';    # special name

        my $subref;

        if ($subref = $self->{_thisclass}->can($meth . '_before'))
        {

            $self->logger("$self->{_thisclass} ->can $meth _before");

            *{$self->{_thisclass} . "::${meth}"} = sub {
                my $sam = shift;
                $subref->($sam, @_);
                *{'SWISH::API::' . $class . $meth}->($sam->handle, @_);
            };

        }
        elsif ($subref = $self->{_thisclass}->can($meth . '_after'))
        {

            $self->logger("$self->{_thisclass} ->can $meth _before");

            *{$self->{_thisclass} . "::${meth}"} = sub {
                my $sam = shift;
                *{'SWISH::API::' . $class . $meth}->($sam->handle, @_);
                $subref->($sam, @_);
              }

        }

    }

    #carp "$thisclass Symbol table";
    #_dispSymbols(\%{$thisclass . '::'});
    #carp "$thisclass can -> abort_last_error"
    #  if $thisclass->can('abort_last_error');

}

sub new
{
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless($self, $class);
    $self->_init(@_);    # private init of normal object
    $self->init(@_);     # public init of object magic
    return $self;
}

sub _init
{
    my $self = shift;
    $self->{_start} = time();

    unless (defined($self->log) && $self->log eq '0')
    {
        $self->{log} ||= *{STDERR};
    }

    # pairs
    if (@_ and !(scalar(@_) % 2))
    {
        my %extra = @_;
        @$self{keys %extra} = values %extra;

        if (!ref $self->indexes)
        {
            $self->indexes([split(/\ +/, $self->indexes)]);
        }
    }

    # S::A style
    else
    {
        my $i = shift;
        if (ref $i eq 'ARRAY')
        {
            $self->indexes($i);
        }
        else
        {
            $self->indexes([split(/\ +/, $i)]);
        }
    }

    # create our handle
    $self->handle(@{$self->indexes});

}

sub init
{
    my $self = shift;

    # some namespace logic
    $self->{_thisclass} = ref($self) || $self;
    ($self->{_thispackage}  = __PACKAGE__)         =~ s,^SWISH::API::,,;
    ($self->{_thissubclass} = $self->{_thisclass}) =~ s,^SWISH::API::,,;
    
    $self->wrap_methods;
    $self->make_methods;

}

sub handle
{
    my $self = shift;
    if (@_)
    {
        $self->{handle} = SWISH::API->new(join(' ', @_));
    }
    return $self->{handle};
}

sub logger
{
    my $self = shift;
    my $t    = '[' . scalar(localtime()) . ']';
    for (@_)
    {
        print {$self->log} "$t $_\n";
    }
}

1;

package SWISH::API::More::Search;
our @ISA = qw( SWISH::API::Search );

1;

package SWISH::API::More::Results;
our @ISA = qw( SWISH::API::Results );

1;

package SWISH::API::More::Result;
our @ISA = qw( SWISH::API::Result );

1;

__END__

=head1 NAME

SWISH::API::More - do more with the SWISH::API

=head1 SYNOPSIS

  package My::SwishAPI;
  use base qw( SWISH::API::More );
  
  sub init
  {
    my $self = shift;
    $self->SUPER::init(@_);

    # wrap every SWISH::API method with one of your own
    $self->{wrappers} = {

        'My::SwishAPI' => sub {
            my $sam = shift;
            $sam->do_something(@_);
        }

    };

    $self->make_methods;
    $self->wrap_methods;
    
  }
  
  sub do_something
  {
    my $self = shift;   # My::SwishAPI object
  }
  
  
  # or subclass in a traditional way

  sub new_search_object
  {
    my $self = shift;
    my $swish_handle = $self->handle;
    
    # do something with $swish_handle
  }
  
  1;
  
  # set _before and _after methods
  # NOTE the perl and C-style names
  
  package My::SwishAPI::Results;

  sub Hits_before
  {
    my $self = shift;
    $self->logger("fetching hit count");
    return;
  }

  sub hits_before { Hits_before(@_) }

  sub Hits_after
  {    
    my $self = shift;    
    my ($origref,$args,$ret) = @_;
    my $h = $ret->[0];
    $self->logger("found $h hits");
    return $h;
  }

  sub hits_after { Hits_after(@_) }

  1;
  
  # else where in a script
  
  use My::SwishAPI;
  
  my $swish = My::SwishAPI->new(
                indexes => [qw( path/to/index1 path/to/index2 )],
                log     => $a_filehandle
                );
                
  $swish->logger("opened a new swish-e handle");
  
  # use $swish just like you would with SWISH::API->new object.
  # only do More!
  

=head1 DESCRIPTION

SWISH::API::More is a base class for subclassing and extending SWISH::API.
Since SWISH::API is just a thin Perl XS wrapper around the Swish-e C library,
which isn't friendly for subclassing in a traditional Perlish way,
SWISH::API::More allows you to subclass SWISH::API like you would
a native Perl module.

SWISH::API::More does some ugly Symbol table mangling to achieve its magic.
Don't look at the wizard behind the curtain.

=head1 REQUIREMENTS

L<SWISH::API>, L<Class::Accessor::Fast>


=head1 METHODS

=head2 new( @I<args> )

Creates a new SWISH::API::More object.

I<args> may be either a string of space-separated index names (like SWISH::API uses)
or key/value pairs.

Example:

 my $swish = SWISH::API::More->new(
            indexes => [qw( my/index )],
            log   => *{STDERR},     # logger will print to stderr
            );
            
You can use the returned C<$swish> object just like a SWISH::API object. But you can
also use the defined methods in SWISH::API::More -- or create your own by subclassing
(see SYNOPSIS).

You probably don't want to override new() in a subclass. See init() instead.

=head2 init

This makes the magic happen. If you subclass SWISH::API::More you'll likely
want to override init(). See L<SWISH::API::Stat> for an example.

init() is called internally by new(). Override init() not new().


=head2 handle

Returns the SWISH::API handle. The handle is simply a SWISH::API object.
So this:

  my $s = SWISH::API->new;
  
and this:

  my $s = SWISH::API::More->new->handle;
  
give you the same thing. Except SWISH::API::More gives you More.

=head2 indexes

Get/set the indexes to which you connect with handle(). indexes() contains
an arrayref B<only>. The SWISH::API-style space-separated string feature in new()
is stored as an arrayref internally and that's what indexes() returns.


=head2 log

Get/set the filehandle that logger() prints to. Defaults to STDERR.
Set to C<0> to disable the default (but then don't expect logger() to work...).

=head2 logger( I<msg> )

Will print I<msg> to the filehandle set in log().



=head1 EXAMPLES

See the L<SWISH::API::Stat> module for a working example.

=head1 SEE ALSO

L<http://swish-e.org/>

L<SWISH::API>, L<SWISH::API::Stat>

=head1 AUTHOR

Peter Karman, E<lt>karman@cpan.orgE<gt>

Thanks to L<Atomic Learning|http://www.atomiclearning.com/> for supporting some
of the development of this module.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

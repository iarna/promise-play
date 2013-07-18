package Async::Continuable;
use Exception::Base 'Error';
use AnyEvent;
use Method::Signatures::Simple;
use Modern::Perl '2012';
use Scalar::Util qw( reftype );
use Try::Tiny;
use parent qw( Exporter );

use Data::Printer;

our @EXPORT = qw( CONTINUE );

sub CONTINUE_WITHOUT_ERRORS(&) {
    my( $resolvecb ) = @_;
    CONTINUE( sub {
        my $resolve = $_;
        local $_ = func (@args) { $resolve->(@args) };
        $resolvecb->();
    });
}

sub CONTINUE(&);

sub CONTINUE(&) {
    my( $resolvecb ) = @_;
    my @todo;
    my $result;
    my $resolve;
    $resolve = func (@args) {
        if ($result) { Error->throw(message=>"Continuable already resolved") }
        if ( @args == 1 and ref($args[0]) and reftype($args[0]) eq 'CODE' ) {
            $args[0]->( $resolve );
        }
        else {
            ($result = func() { $_->(@args) for @todo; @todo=() })->();
        }
    };
    {local $_=$resolve; $resolvecb->()};

    my $continuable = bless func($then) {
        if ($result) { AE::postpone { $result->() } }
        CONTINUE {
            my $chained_resolve = $_;
            push @todo, func (@args) {
                my @next_result;
                local $@;
                try {
                    my @values = $then->(@args);
                    @next_result = @values ? (undef,@values) : @args;
                }
                catch {
                    @next_result = ($_);
                };
                $chained_resolve->(@next_result);
            };
        };
    }, 'Async::Continuable::Then';
    return $continuable;
}

package Async::Continuable::Then;
use Method::Signatures::Simple;
use Modern::Perl '2012';

method then($success,$failure) {
    return $self->( func ($E,$V) {
        if ($E) {
            if ($failure) {
                $failure->($E);
            }
            die $E;
        }
        return $success->($V);
    });
}

method else($failure,$success) { $self->then($success,$failure) }

1;

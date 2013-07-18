#!perl
use Exception::Base 'Error';
use Modern::Perl '2012';
use Method::Signatures::Simple;
use EV;
use Async::Continuable qw( CONTINUE );
use Data::Printer;

func report (@msg) { say '% ',join ' ', map { $_ // 'undef' } @msg; return; }

my $foo = CONTINUE {
    $_->("BOOM");
    #$_->(undef,"THIS1");
};

$foo->(func ($E,$V) { report("CONTINUE EARLY RESOLVE1:",$E,$V) })
    ->(func ($E,$V) { report("CONTINUE EARLY RESOLVE2:",$E,$V); $E ? () : "$V FOR FOO"; })
    ->(func ($E,$V) { report("CONTINUE EARLY RESOLVE3:",$E,$V) });

my $bar = CONTINUE { my $resolve=$_; AE::postpone { $resolve->(undef,"THIS2") } };

$bar->(func ($E,$V) { report("CONTINUE LATE RESOLVE1:",$E,$V) });
$bar->(func ($E,$V) { report("CONTINUE LATE RESOLVE2:",$E,$V) });
my $baz = CONTINUE { $_->(undef,"ALL DONE") };
my $bark = CONTINUE { $_->($baz) };
$bark->(func($E,$V) { report("CHAINED RESOLVE:",$E,$V) });


my $presolve;
my $promise = CONTINUE { $presolve = $_ };
func ok() {
    my $nresolve;
    my $N = CONTINUE { $nresolve = $_ };
    #nresolve(Error->new(message=>"BAD"));
    $nresolve->(undef,"NYAY");
    $presolve->($N);
    #presolve(undef,"yay");
}

func nok() {
    $presolve->(Error->new(message=>"boo"));
}

ok();
my $P2 = $promise->then(func ($M) { report("PROMISE1:",$M); Error->throw(message=>"Boo") }, func ($M) { report("PROMISE1 (err):",$M) })
                 ->then(func ($M) { report("PROMISE2:",$M) }, func ($M) { report("PROMISE2: (err)",$M) });

$promise->then(func ($M) { report("PROMISE3:",$M) }, func ($M) { report("PROMISE3: (err)",$M) })
        ->then(func ($M) { report("PROMISE4:",$M) }, func ($M) { report("PROMISE4: (err)",$M) });

$P2->then(func ($M) { report("PROMISE5:",$M) }, func ($M) { report("PROMISE5: (err)",$M) });

EV::loop;

Continuables
------------

As a library author, to create a continuable:

    function example1() {
        return Continue(function (resolve) {
            fs.open( '/file', 'r', resolve );
        });
    }

Or to be backwards compatible with a callback based API:

    function example1(callback) {
        C = Continue(function (resolve) {
            fs.open( '/file', 'r', resolve );
        });
        if (callback) { C(callback) }
        return C;
    }

The resolve function has the signature (e,v) following the node convention
of passing an error or null as the first argument.  If the callback you're
using can't report errors, just have it use the withoutErrors variant:

    function example2() {
        return Continue(function (resolve) {
            net.createServer( resolve.withoutErrors );
        });
    }

If sometimes your function might be async and sometimes you have an
immediate answer, you can resolve prior to returning:

    function example3(sleepFor) {
        return Continue(function (resolve) {
            if ( sleepFor ) {
                setTimeout( resolve, sleepFor );
            }
            else {
                resolve();
            }
        });
    }

It should be noted that it is an error to try to resolve the same continable
more then once.  If you try, an error will be thrown.

Someone using your library can use it as if it were callback based like so:

    example1()(function() { console.log("... a second later.") });

Or they can store away the continuable and use it later:

    var onConnect = example();
    // ...
    onConnect(function (e,conn) { /* ... */ });

If they call onConnect again, the new callback is guarenteed to be called with the same
arguments as the original onConnect callback.  This means you can pass the continuable
around as a value, that any number of parts of your program can get data
from without concern as to exactly when the result is actually computed.

Continuables are also chainable-- when you call them, they'll return a new
continuable that will complete after the previous one does along with the
return value of your previous callback.  If your callback throws an
exception it will be passed to the error argument of the next continuable.

    var sleep = example3(500);
    sleep( function(e,v) { console.log("Slept!"); return "FOO" })                     // prints: Slept!
         ( function(e,v) { console.log("Also got out", v); throw new Error("BOOM") }) // prints: Also got out FOO
         ( function(e,v) { console.log(e,v) })                                        // prints: [Error: BOOM] undefined

Like promises, if you resolve with a continuable that continuable will be
used to determine the result of the current continuable:

    var sleep1 = example3(500):
    var c1 = Continue(function (resolve) {
        resolve(sleep1);
    });

    c1( function () { console.log("DONE" } ); // called after sleep1 completes

Promises
--------

Our continuables are also promises, that, is, they expose a "then" method
that takes a success and an error callback.  (There is no onProgress
callback for it is of the devil, use normal events for goodness sake.)

As a library author, there is no difference between the two:

    function example1() {
        return Continue(function (resolve) {
            net.createServer(resolve.withoutErrors);
        });
    }

A more common pattern might be:

    function example1(callback) {
        P = Continue(function (resolve) {
            net.createServer(resolve.withoutErrors);
        });
        if (callback) { P.then(callback) }
        return P;
    }

It should be noted that it is an error to try to resolve the same promise
more then once.  If you try, an error will be thrown.

Someone using your library can use it as if it were callback based like so:

    example3().then(function() { console.log("... a second later.") });

Or they can store away the promise and use it later:

    var onConnect = example1();
    // ...
    onConnect.then(function (conn) { /* ... */ });

If they call onConnect.then again, the new callback is guarenteed to be
called with the same arguments as the original onConnect callback.  This
means you can pass the promise around as a value, that any number of
parts of your program can get data from without concern as to exactly when
the result is actually computed.

Promises are also chainable-- when you call them, they'll return a new
promise that will complete after the previous one does along with the
return value of your previous callback.  If your callback throws an
exception it will be passed to the error argument of the next promise.

    var sleep = example3(500);
    sleep.then( function(v) { console.log("Slept!"); return "FOO" })                     // prints: Slept!
         .then( function(v) { console.log("Also got out", v); throw new Error("BOOM") }) // prints: Also got out FOO
         .then( function(v) { }, function(e) { console.log(e) })                         // prints: [Error: BOOM] undefined

Promises can be used to resolve other promises:

    var sleep1 = example3(500):
    var p1 = Continue( function (resolve) {
        resolve( sleep1 );
    });

    p1.then( function () { console.log("DONE" } ); // called after sleep1 completes

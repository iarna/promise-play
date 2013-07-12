Continuables
------------

As a library author, to create a continuable:

    function example1() {
        C = Continue();
        fs.open( '/file', 'r', C.resolve );
        return C;
    }

The C.resolve function has the signature (e,v) following the node convention
of passing an error or null as the first argument.  If the callback you're
using can't report errors, just have it use the withoutErrors variant:

    function example2() {
        C = Continue();
        net.createServer( C.resolve.withoutErrors );
        return C;
    }

If sometimes your function might be async and sometimes you have an
immediate answer, you can resolve prior to returning:

    function example3(sleepFor) {
        C = Continue();
        if ( sleepFor ) {
            setTimeout( C.resolve, sleepFor );
        }
        else {
            C.resolve();
        }
        return C;
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

Promises allow you to pass a promise object to a promise `resolve` method. 
With continuables, you just pass the resolve method, eg:

    var sleep1 = example3(500):
    var c1 = Continue();
    
    sleep1( c1.resolve );

    c1( function () { console.log("DONE" } ); // called after sleep1 completes

Promises
--------

Promises *do* the same thing and they're implemented using continuables, but
they provide a different interface-- one compatible with most of the
promises specs on CommonJS.  Specifically:

* They return an object with `resolve(value)`, `reject(error)` methods and a
  `deferred` property.
* The `deferred` property has an object with a `then(onSuccess,onError)`
  method (NOTE: no onProgress method, for it is of the devil)

As a library author, to create a promise is almost the same as a continuuable:

    function example1() {
        P = Promise();
        net.createServer(P.resolve);
        return P.deferred;
    }

The P.resolve function only takes a single value.  To notify of an error use
P.reject.  If the callback you're using type typical (e,v) callback
convention used widely in node, use the withCallback variant:

    function example2() {
        P = Promise();
        fs.open('/file','r', P.resolve.withCallback );
        return P;
    }

If sometimes your function might be async and sometimes you have an
immediate answer, you can resolve prior to returning:

    function example3(sleepFor) {
        P = Promise();
        if ( sleepFor ) {
            setTimeout( P.resolve, sleepFor );
        }
        else {
            P.resolve();
        }
        return P;
    }

It should be noted that it is an error to try to resolve the same promise
more then once.  If you try, an error will be thrown.

Someone using your library can use it as if it were callback based like so:

    example3().then(function() { console.log("... a second later.") });

Or they can store away the promise and use it later:

    var onConnect = example1();
    // ...
    onConnect.then(function (e,conn) { /* ... */ });

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
    var p1 = Promise();
    
    p1.resolve( sleep1 );

    p1.deferred.then( function () { console.log("DONE" } ); // called after sleep1 completes

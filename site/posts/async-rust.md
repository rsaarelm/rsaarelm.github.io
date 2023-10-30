:title A short note on async Rust
:date 2023-10-30
:tags cs/rust

I procrastinated for years on figuring out what the deal with async Rust is.
Here's what I wish I'd gotten to read right away.

There is exactly one "magical" bit involved with async Rust and that's marking a function `async` and calling `await` from inside the async function.
This will compile the body of the function into an anonymous state machine type that implements the `Future` trait.
Calling an async function produces a `Future` value that implements the state machine for the function's body.
It must be polled to run the function code.
When the function's future is being executed via polling, an `await` call in the function code can suspend the execution, and it can then be resumed later with a new poll.

The rest of how an async program works can be figured out in terms of regular Rust syntax and the various library types involved.

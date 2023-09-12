:title Game system objects
:date 2023-03-21
:updated 2023-09-12
:tags games/dev cs/rust

I've kept working on Rust game development since I last wrote about it in 2015.

A big initial problem with developing a game is coming up with an idiom for the runtime game object space that has many different types of objects that need to interact with each other in complex ways.
A language without Rust's borrow checking could do a design where the game world object has references to game entity objects and the game entity objects have references to the world object, with everything managed by a garbage collector.
This can get messy, like Joe Armstrong's quip about object-oriented programming, "You wanted a banana but what you got was a gorilla holding the banana and the entire jungle."

With Rust, the starting point is that everything should be tree-shaped.
You don't want an object to link back to where it was linked from, that would be a cyclic graph instead of a tree.
You don't even want multiple branches linking to the same leaf object, an acyclic graph, because now it's unclear which of the branches owns the object.
The whole tree is rooted on the trunk, while branches don't know about the trunk below them and leaves on the branches don't know about the branches.
If you need to do operations with the leaves that involve the rest of the tree, a straightforward approach is to reference the whole tree as a context to the operation.
A future Rust [might provide context-specification as a language feature](https://tmandry.gitlab.io/blog/posts/2021-12-21-context-capabilities/) but now we're stuck with passing it around as a threaded parameter.

## The runtime object

Threading a context parameter turns out to work pretty well for game code.
The context object is very important for the design, and needs strong conventions around it.
So far a good rule of thumb has been "the object that stores everything you need to save in a save game file".
I'm calling this object `Runtime` and use the variable `r` for it in the function signatures.
So I get code like this:

```rust
impl Entity {
    /// Look up other entities near this entity.
    fn get_neighbor(&self, r: &impl AsRef<Runtime>, offset: Vector) -> Option<Entity> {
        let r = r.as_ref();
        // This is a query method that does not change game state.
        r.get_entity(self.position(r) + offset)
    }

    /// Make an entity stronger with a power up effect.
    fn power_up(&self, r: &mut impl AsMut<Runtime>, strength: u32) {
        let r = r.as_mut();
        // This method changes the game state.
        r.set_component(self, PowerUp(strength));
    }
    ...
}
```

The runtime ends up being much like a database.
I'm using the [hecs](https://github.com/Ralith/hecs) entity component system for entity data, and have some additional stuff like global variables in the runtime object.

Entities (the individual game objects like goblins and spaceships) are contained in the runtime and can do very little by themselves.
Entity values are very similar to keys to database tables here.
Anything that needs access to other contents of the runtime or even data associated with a single entity needs a reference to the runtime in the method call.

Having the runtime reference with a known mutability status also helps if I want to make the game multithreaded.
Any methods that access a read-only `&Runtime` can be run in parallel.
These can include pathfinding AI for individual entities, which can make up a large part of the game runtime.
Mutating methods with `&mut Runtime` must be run in sequence.
If the runtime data was stored in a global variable, it would be much trickier to determine method calls that won't mutate the runtime.

It is also straightforward to return iterators to contents of the runtime by just making the iterator object share the lifetime with the runtime reference.

```rust
impl Runtime {
    fn live_entities(&self) -> impl Iterator<Item = Entity> + '_ { ... }
    ...
}
```

The game systems can get nested, a runtime will probably end up inside a higher-level game object that also contains rendering machinery.
Toplevel game code will deal with a top-level system object, so the system-threading interfaces are written with `AsRef` and `AsMut` parameters instead of direct references.
This way the higher-level supersystem can implement `AsRef<Runtime>` and `AsMut<Runtime>`, and it can then take the place of the subsystem reference in the threaded calls, making for nicer syntax in top-level code.
Since `AsRef` and `AsMut` aren't automatically reflexive, the runtime object also needs trivial `AsRef<Runtime>` and `AsMut<Runtime>` implementations.

## Nesting systems

A full program can consist of multiple systems that are contained in a tree-like structure.
The game toplevel could consist of the engine runtime (only manages the runtime game logic) and the rendering state (draws things on screen, manages cached textures).
The toplevel object is used as a context parameter for high-level main game loop functions, and method calls drop down to using the subsystem members when control moves to a subsystem.

```rust
/// Toplevel game system.
struct GameLoop {
    /// Game runtime subsystem.
    r: Runtime,
    /// Graphics rendering subsystem.
    s: Renderer
}

impl GameLoop {
    fn render(&self) {
        // A shorthand for &self.c to make calls below more concise.
        let r = &self.r;

        for e in r.live_entities() {
            // Draw entities with rendering subsystem.
            // An entity's data accessors need the core reference
            // so they can access the ECS store.
            self.s.display(e.pos(r), e.icon(r));
        }
    }
}
```

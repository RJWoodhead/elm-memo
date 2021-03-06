# The Memo Metaphor

This is my first attempt to make intermodule communication in Elm as simple and transparent
as possible. That said, I know just enough about Elm to be dangerous to myself and everyone
in my immediate vicinity, so this could be horribly wrong!

The basic metaphor is that your app is like a large company, and each module is a department.

Now, if departments -- or even the Main office -- were allowed to stick their fingers into
the workings of other departments, chaos would ensue. So instead, the departments use
inter-departmental memos to keep each other apprised of what is going on, on a need-to-know
basis.

In the Memo Metaphor, Cmd Msgs are letters arriving from outside the company,
and memos are internal discussions about how to respond to those letters.

In the Memo metaphor:

* Each module's state is only changed by the module itself. If another module
(including the Main module) needs to make a change, it sends one or more memos.

* The Main module handles initialization, the UI skeleton, and routing memos.
It is largely boilerplate.

* Memo routing is simply and clearly defined in the Main module; a memo can be
sent to multiple modules, or a recipient can subscribe to a memo. The model
can be tested to decide whether to route a memo, and custom routers can be
defined to handle special cases (like Memos with parameters)

* Memos are atomic; each Cmd Msg arriving at Main.elm's update function may end up
triggering a cascade of memos, which in turn create new Msgs, all of which will be
processed before the next Cmd Msg.

* The order in which memos are processed is deterministic (and the list of Msgs
that are processed is saved in the model for debugging purposes)

* If the stack of memos gets too high (due to an infinite recursion caused by incorrect
routing), the router declares a "memo blizzard" and gives up.


### Setup

1. Run `npm install` to install the build process dependancies
2. Run `npm install gulp -g` to install the gulp executable globally
3. Run `elm package install ` to install the elm dependancies

### Start Build Process

1. Run `gulp` to start the build process

### Run the Memo Demo

1. Load http://localhost:4000/ in your browser

2. Add sons and daughters by clicking the buttons. Note that the parents
refuse to acknowledge more than two children (due to conditional routing
of the memos), but the boys and girls keep track of how many sisters and
brothers they have.

Note that each button handles its task in a different way, for purposes of
illustration. There are explanatory notes in the code.

3. You can also generate a blizzard to see how that works (or more precisely,
fails), and test a custom router and Memo with a parameter by adding
quadruplet boys.

### Credits

Project structure cribbed from "Elm Beyond the Basics", available on http://knowthen.com/

Thanks to @jessta on Elm-slack for a key insight -- but don't blame her for my folly!

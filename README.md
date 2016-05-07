![Render Logo](Doc/logo.png)

React-inspired library for writing UIKit UIs which are functions of their state.

#Why

[Render/React] lets us write our UIs as a pure function of their state.


Right now we write UIs by poking at them, manually mutating their properties when something changes, adding and removing views, etc. This is fragile and error-prone. Some tools exist to lessen the pain, but they can only go so far. UIs are big, messy, mutable, stateful bags of sadness.

[Render/React] let us describe our entire UI for a given state, and then it does the hard work of figuring out what needs to change. It abstracts all the fragile, error-prone code out away from us. We describe what we want, React figures out how to accomplish it.
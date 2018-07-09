# stream-json

[![Build status][travis-image]][travis-url]
[![Dependencies][deps-image]][deps-url]
[![devDependencies][dev-deps-image]][dev-deps-url]
[![NPM version][npm-image]][npm-url]


`stream-json` is a collection of node.js stream components for creating custom standard-compliant JSON processors, which requires a minimal memory footprint. It can parse JSON files far exceeding available memory. Even individual primitive data items (keys, strings, and numbers) can be streamed piece-wise. Streaming SAX-inspired event-based API is included as well.

Available components:

* Streaming JSON parsers:
  * Streaming JSON `Parser` is manually implemented based on `RegExp`.
  * Streaming JSON `AltParser` implemented manually without regular expressions.
  * Streaming JSON `ClassicParser` based on [parser-toolkit](http://github.com/uhop/parser-toolkit).
* `Streamer`, which converts tokens into SAX-like event stream.
* `Packer`, which can assemble numbers, strings, and object keys from individual chunks. It is useful, when user knows that individual data items can fit the available memory. Overall, it makes the API simpler.
* `Combo`, which actually packs `Parser`, `Streamer`, and `Packer` together. **Its advantage over individual components is speed**.
* `Filter`, which is a flexible tool to select only important sub-objects using either a regular expression, or a function.
* `Emitter`, which converts an event stream into events by bridging `stream.Writable` with `EventEmitter`.
* `Source`, which is a helper that connects streams using `pipe()` and converts an event stream on the end of pipe into events, similar to `Emitter`.
* Various utilities:
  * `Assembler` to assemble full objects from an event stream.
  * `Stringer` to convert an event stream back to a JSON text stream.
  * `StreamArray` handles a frequent use case: a huge array of relatively small objects similar to [Django](https://www.djangoproject.com/)-produced database dumps. It streams array components individually taking care of assembling them automatically.
  * `StreamFilteredArray` is a companion for `StreamArray`. The difference is that it allows to filter out unneeded objects in an efficient way without assembling them fully.
  * `FilterObjects` filters complete objects and primitives.
  * `StreamObject` streams an object's key-value pairs individually taking care of assembling them automatically. Modeled after `StreamArray`.
  * `StreamJsonObjects` supports [JSON Streaming](https://en.wikipedia.org/wiki/JSON_Streaming) protocol, where individual values are separated statically (like in `"{}[]"`), or with whitespaces (like in `"true 1 null"`). Modeled after `StreamArray`.

Additionally a helper function is available in the main file, which creates a `Source` object with a default set of stream components.

This toolkit is distributed under New BSD license.

See the full documentation below.

## Introduction

The simplest example (streaming from a file):

```js
var makeSource = require("stream-json");
var source = makeSource();

var fs = require("fs");

var objectCounter = 0;
source.on("startObject", function(){ ++objectCounter; });
source.on("end", function(){
    console.log("Found ", objectCounter, " objects.");
});

fs.createReadStream("sample.json").pipe(source.input);

```

## Installation

```
npm install stream-json
```

## Documentation

### Parser

This is the workhorse of the package. It is a [Transform](https://nodejs.org/api/stream.html#stream_class_stream_transform) stream, which consumes text, and produces a stream of tokens. It is always the first in a pipe chain being directly fed with a text from a file, a socket, the standard input, or any other text stream. Its `Writeable` part operates in a buffer mode, while its `Readable` part operates in an [objectMode](http://nodejs.org/api/stream.html#stream_object_mode).

```js
var Parser = require("stream-json/Parser");
var parser = new Parser(options);

// Example of use:
var next = fs.createReadStream(fname).pipe(parser);
```

`options` can contain some technical parameters, and it rarely needs to be specified. You can find it thoroughly documented in [node.js' Stream documentation](http://nodejs.org/api/stream.html). Additionally it recognizes following properties:

* `jsonStreaming` can be `true` or `false` (the default). If `true`, it can parse a stream of JSON objects as described in [JSON Streaming](https://en.wikipedia.org/wiki/JSON_Streaming) as "Concatenated JSON". Technically it will recognize "Line delimited JSON" as well.

The test files for `Parser`: `tests/test_parser.js`, `tests\manual\test_parser.js`. Actually all test files in `tests/` use `Parser`.

If you want to catch parsing errors, attach an error listener directly to a parser component &mdash; unlike data errors do not travel through stream pipes.

### Streamer

`Streamer` is a [Transform](https://nodejs.org/api/stream.html#stream_class_stream_transform) stream, which consumes a stream of tokens, and produces a stream of events. It is always the second in a pipe chain after the `Parser`. It knows JSON semantics and produces actionable events. It operates in an [objectMode](http://nodejs.org/api/stream.html#stream_object_mode).

```js
var Streamer = require("stream-json/Streamer");
var streamer = new Streamer(options);

// Example of use:
var next = fs.createReadStream(fname).
                pipe(parser).pipe(streamer);
```

`options` can contain some technical parameters, and it is rarely needs to be specified. You can find it thoroughly documented in [node.js' Stream documentation](http://nodejs.org/api/stream.html).

Following is a list of all event objects produced by `Streamer`:

```js
{name: "startObject"};
{name: "endObject"};

{name: "startArray"};
{name: "endArray"};

{name: "startKey"};
{name: "stringChunk", value: "actual string value"};
{name: "endKey"};

{name: "startString"};
{name: "stringChunk", value: "actual string value"};
{name: "endString"};

{name: "startNumber"};
{name: "numberChunk", value: "actual string value"};
{name: "endNumber"};

{name: "nullValue", value: null};
{name: "trueValue", value: true};
{name: "falseValue", value: false};

```

The event stream is well-formed:

* All `startXXX` are balanced with `endXXX`.
* Between `startKey` and `endKey` can be zero or more `stringChunk` events. No other event are allowed.
* Between `startString` and `endString` can be zero or more `stringChunk` events. No other event are allowed.
* Between `startNumber` and `endNumber` can be one or more `numberChunk` events. No other event are allowed.
  * All number chunks combined constitute a valid number value.
  * Number chunk values are strings, not numbers!
* After `startObject` optional key-value pairs emitted in a strict pattern: a key-related events, a value, and this cycle can be continued until all key-value pairs are streamed.

The test files for `Streamer`: `tests/test_streamer.js` and `tests/manual/test_streamer.js`.

### Packer

`Packer` is a [Transform](https://nodejs.org/api/stream.html#stream_class_stream_transform) stream, which passes through a stream of events, optionally assembles keys, strings, and/or numbers from chunks, and adds new events with assembled values. It is a companion  for `Streamer`, which frees users from implementing the assembling logic, when it is known that keys, strings, and/or numbers will fit in the available memory. It operates in an [objectMode](http://nodejs.org/api/stream.html#stream_object_mode).

```js
var Packer = require("stream-json/Packer");
var packer = new Packer(options);

// Example of use:
var next = fs.createReadStream(fname).
                pipe(parser).pipe(streamer).pipe(packer);
```

`options` contains some important parameters, and should be specified. It can contain some technical properties thoroughly documented in [node.js' Stream documentation](http://nodejs.org/api/stream.html). Additionally it recognizes following properties:

* `packKeys` can be `true` or `false` (the default). If `true`, a key value is returned as a new event:

  ```js
  {name: "keyValue", value: "assembled key value"}
  ```

  `keyValue` event always follows `endKey`.
* `packStrings` can be `true` or `false` (the default). If `true`, a string value is returned as a new event:

  ```js
  {name: "stringValue", value: "assembled string value"}
  ```

  `stringValue` event always follows `endString`.
* `packNumbers` can be `true` or `false` (the default). If `true`, a number value is returned as a new event:

  ```js
  {name: "numberValue", value: "assembled number value"}
  ```

  `numberValue` event always follows `endNumber`.
  `value` of this event is a string, not a number. If user wants to convert it to a number, they can do it themselves. The simplest way to do it (assuming your platform and JavaScript can handle it), is to force it to a number:

  ```js
  var n = +event.value;
  ```

The test files for `Packer`: `tests/test_packer.js` and `tests/manual/test_packer.js`.

### Combo

`Combo` is a [Transform](https://nodejs.org/api/stream.html#stream_class_stream_transform) stream, which combines `Parser`, `Streamer`, and `Packer`. It accepts the same extra options as `Parser` and `Packer`, and produces a stream of objects expected from `Streamer`, and augmented by `Packer`. Please refer to the documentation of those three components for more details.

While logically `Combo` is a combination of three existing components, it has an important advantage: speed. The codes for `Parser`, `Streamer`, and `Packer` are merged together in one component avoiding overhead of node.js streams completely, which is significant. It is recommended to use `Combo` over a chain of `Parser` + `Streamer`, or `Parser` + `Streamer` + `Packer`.

The test file for `Combo`: `tests/test_combo.js`.

### Emitter

`Emitter` is a [Writeable](https://nodejs.org/api/stream.html#stream_class_stream_writable) stream, which consumes a stream of events, and emits them on itself (all streams are instances of [EventEmitter](https://nodejs.org/api/events.html#events_class_events_eventemitter)). The standard `finish` event is used to indicate the end of a stream. It operates in an [objectMode](http://nodejs.org/api/stream.html#stream_object_mode).

```js
var Emitter = require("stream-json/Emitter");
var emitter = new Emitter(options);

// Example of use:

emitter.on("startArray", function(){
    console.log("array!");
});
emitter.on("numberValue", function(value){
    console.log("number:", value);
});
emitter.on("finish", function(){
    console.log("done");
});

fs.createReadStream(fname).
    pipe(parser).pipe(streamer).pipe(packer).pipe(emitter);
```

`options` can contain some technical parameters, and it is rarely needs to be specified. You can find it thoroughly documented in [node.js' Stream documentation](http://nodejs.org/api/stream.html).

The test file for `Emitter`: `tests/test_emitter.js`.

### Filter

`Filter` is a [Transform](https://nodejs.org/api/stream.html#stream_class_stream_transform) stream, which is an advance selector for sub-objects from a stream of events. It operates in an [objectMode](http://nodejs.org/api/stream.html#stream_object_mode).

```js
var Filter = require("stream-json/Filter");
var filter = new Filter(options);

// Example of use:
var next = fs.createReadStream(fname).
                pipe(parser).pipe(streamer).pipe(filter);
```

`options` contains some important parameters, and should be specified. It can contain some technical properties thoroughly documented in [node.js' Stream documentation](http://nodejs.org/api/stream.html). Additionally it recognizes following properties:

* `separator` is a string to use to separate key and index values forming a path in a current object. By default it is `.` (a dot).
* `filter` can be a regular expression, or a function. By default it allows all events.
  * If it is a function, this function is called in a context of a `Filter` object with two parameters:
    * `path`, which is an array of current key and index values. All keys are represented as strings, while all array indices are represented as numbers. It can be used to understand what kind of object we are dealing with.
    * `event` is an event object described above.
  The function should return a Boolean value, with `true` indicating that we are interested in this event, and it should be passed through.
  * If it is a regular expression, then a current `path` is joined be a `separator` and tested against the regular expression. If a match was found, it indicates that the event should be passed through. Otherwise it will be rejected.
* `defaultValue` is an array of event objects described above, which substitute skipped array items. By default it is `[{name: "nullValue", value: null}]` &mdash; a `null` value.
  * `filter` can skip some array items. If it happens, `defaultValue` events are going to be inserted for every previously skipped item.
    * If all array items were skipped, an empty array will be issued.
    * Skipped items at the end of array are not substituted with `defaultValue`. A truncated array will be issued.
  * **Important:** make sure that the sequence of events make sense, and do not violate JSON invariants. For example, all `startXXX` and `endXXX` should be properly balanced.
  * It is possible to specify an empty array of events.

`Filter` produces a well-formed event stream.

The test files for `Filter`: `tests/test_filter.js` and `tests/manual/test_filter.js`.

#### Path examples

Given a JSON object:

```js
{"a": [true, false, 0, null]}
```

The path of `false` as an array:

```js
["a", 1]
```

The same path converted to a string joined by a default separator `.`:

```js
"a.1"
```

The top element of a stack can be `true` or `false`. The former means that an object was open, but no keys were processed. The latter means that an array was open, but no items were processed. Both values can be present in an array path, but not in a string path.

### Source

`Source` is a convenience object. It connects individual streams with pipes, and attaches itself to the end emitting all events on itself (just like `Emitter`). The standard `end` event is used to indicate the end of a stream. It is based on [EventEmitter](https://nodejs.org/api/events.html#events_class_events_eventemitter).

```js
var Source = require("stream-json/Source");
var source = new Source([parser, streamer, packer]);

// Example of use:

source.on("startArray", function(){
    console.log("array!");
});
source.on("numberValue", function(value){
    console.log("number:", value);
});

fs.createReadStream(fname).pipe(source.input);
```

The constructor of `Source` accepts one mandatory parameter:

* `streams` should be a non-empty array of pipeable streams. At the end the last stream should produce a stream of events.

`Source` exposes three public properties:

* `streams` &mdash; an array of streams so you can inspect them individually, if needed. They are connected sequentially in the array order.
* `input` &mdash; the beginning of a pipeline, which should be used as an input for a JSON stream.
* `output` &mdash; the end of a pipeline, which can be used to pipe the resulting stream of objects for further processing.

The test files for `Source`: `tests/test_source.js` and `tests/manual/test_source.js`.

### main: makeSource()

The main file contains a helper function, which creates a commonly used configuration of streams, and returns a `Source` object.

```js
var makeSource = require("stream-json");
var source = makeSource(options);

// Example of use:

source.on("startArray", function(){
    console.log("array!");
});
source.on("numberValue", function(value){
    console.log("number:", value);
});

fs.createReadStream(fname).pipe(source.input);
```

`options` can contain some technical parameters, and it is completely optional. You can find it thoroughly documented in [node.js' Stream documentation](http://nodejs.org/api/stream.html), and here. It is directly passed to `Combo`, so it will use its custom parameters.

Algorithm:

1. `makeSource()` checks if either of `packKeys`, `packStrings`, or `packNumbers` are specified in options.
  1. If any of them are `true`, a `Combo` instance is created with `options`.
  2. If all of them are unspecified, all pack flags are assumed to be `true`, and a `Combo` is created.
2. A newly created instance of `Combo` is used to create a `Source` instance.

The most common use case is to call `makeSource()` without parametrs. This scenario assumes that all key, string, and/or number values can be kept in memory, so user can use simplified events `keyValue`, `stringValue`, and `numberValue`.

The test files for `makeSource()` are `tests/test_source.js`, `tests/manual/test_main.js`, and `tests/manual/test_chunk.js`.

### ClassicParser

It is a drop-in replacement for `Parser`, but it can emit whitespace, and token position information, yet it is slower than the main parser. It was the main parser for 0.1.x versions.

It doesn't support `jsonStreaming` option.

The test file for `ClassicParser`: `tests/test_classic.js`.

### AltParser

It is another drop-in replacement for `Parser`. Just like `ClassicParser` it can emit whitespace, and token position information, but can be slower than the current main parser on platforms with optimized `RegExp` implementation. It is faster than `Parser` on node.js 0.10.

In general, its speed depends heavily on the implementation of regular expressions by node.js. When node.js has switched from an interpreted regular expressions, to the JIT compiled ones, both `ClassicParser`, and `Parser` got a nice performance boost. Yet, even the latest (as of 0.12) JIT compiler uses a simple yet non-linear algorithm to implement regular expressions instead of [NFA](http://en.wikipedia.org/wiki/Nondeterministic_finite_automaton) and/or [DFA](http://en.wikipedia.org/wiki/Deterministic_finite_automaton). Future enhancements to node.js would make `RegExp`-based parsers faster, potentially overtaking manually written JavaScript-only implementations.

It doesn't support `jsonStreaming` option.

The test file for `AltParser`: `tests/test_alternative.js`.

### utils/Assembler

A helper class to convert a JSON stream to a fully assembled JS object. It can be used to assemble sub-objects.

```js
var makeSource = require("stream-json");
var Assembler  = require("stream-json/utils/Assembler");

var source    = makeSource(options),
    assembler = new Assembler();

// Example of use:

source.output.on("data", function(chunk){
  assembler[chunk.name] && assembler[chunk.name](chunk.value);
});
source.output.on("end", function(){
  // here is our fully assembled object:
  console.log(assembler.current);
});

fs.createReadStream(fname).pipe(source.input);
```

`Assembler` is a simple state machine with an explicit stack. It exposes three properties:

* `current` &mdash; an object we are working with at the moment. It can be either an object or an array.
  * Initial value is `null`.
  * If top-level object is a primitive value (`null`, `true`, `false`, a number, or a string), it will be placed in `current` too.
* `key` &mdash; is a key value (a string) for a currently processed value, or `null`, if not expected.
  * If `current` is an object, a primitive value will be added directly to it using a current value of `key`.
    * After use `key` is assigned `null` to prevent memory leaks.
  * If `current` is an array, a primitive value will be added directly to it by `push()`.
* `stack` &mdash; an array of parent objects.
  * `stack` always grows/shrinks by two items: a value of `current` and a value of `key`.
  * When an object or an array is closed, it is added to its parent, which is removed from the stack to become a current object again.
  * While adding to a parent a saved key is used if needed. Otherwise the second value is ignored.
  * When an object or an array is started, the `current` object and `key` are saved to `stack`.

Obviously `Assembler` should be used only when you are sure that the result will fit into memory. It automatically means that all primitive values (strings or numbers) are small enough to fit in memory too. As such `Assembler` is meant to be used after `Packer`, which reconstructs keys, strings, and numbers from possible chunks.

On the other hand, we use `stream-json` when JSON streams are big, and `JSON.parse()` is not an option. But we use `Assembler` to assemble sub-objects. One way to do it is to start directing calls to `Assembler` when we already selected a sub-object with `Filter`. Another way is shown in `StreamArray`.

The test file for `Assembler`: `tests/test_assembler.js`.

### utils/Stringer

This stream component converts an event stream (described in this document) back to a JSON text stream. The common use is to filter/transform an input stream, then pipe it back to the original text form.

Its `Writeable` part operates in an [objectMode](http://nodejs.org/api/stream.html#stream_object_mode), while its `Readable` part operates in a buffer mode.

```js
var makeSource = require("stream-json");
var Filter     = require("stream-json/Filter");
var Stringer   = require("stream-json/utils/Stringer");

var source    = makeSource(sourceOptions),
    filter    = new Filter(filterOptions),
    stringer  = new Stringer();

// Example of use:
source.output.pipe(filter).pipe(stringer).pipe(fs.createWriteStream(oname));
fs.createReadStream(fname).pipe(source.input);
```

The test file for `Stringer`: `tests/test_stringer.js`.

### utils/StreamArray

This utility deals with a frequent use case: our JSON is an array of various sub-objects. The assumption is that while individual array items fit in memory, the array itself does not. Such files are frequently produced by various database dump utilities, e.g., [Django](https://www.djangoproject.com/)'s [dumpdata](https://docs.djangoproject.com/en/1.8/ref/django-admin/#dumpdata-app-label-app-label-app-label-model).

It is a [Transform](https://nodejs.org/api/stream.html#stream_class_stream_transform) stream, which operates in an [objectMode](http://nodejs.org/api/stream.html#stream_object_mode).

`StreamArray` produces a stream of objects in following format:

```js
{index, value}
```

Where `index` is a numeric index in the array starting from 0, and `value` is a corresponding value. All objects are produced strictly sequentially.

```js
var StreamArray = require("stream-json/utils/StreamArray");
var stream = StreamArray.make();

// Example of use:

stream.output.on("data", function(object){
  console.log(object.index, object.value);
});
stream.output.on("end", function(){
  console.log("done");
});

fs.createReadStream(fname).pipe(stream.input);
```

`StreamArray` is a constructor, which optionally takes one object: `options`. `options` can contain some technical parameters, and it is rarely needs to be specified. You can find it thoroughly documented in [node.js' Stream documentation](http://nodejs.org/api/stream.html).

Directly on `StreamArray` there is a class-level helper function `make()`, which helps to construct a proper pipeline. It is similar to `makeSource()` and takes the same argument `options`. Internally it creates and connects `Combo` and `StreamArray`, and returns an object with three properties:

* `streams` &mdash; an array of streams so you can inspect them individually, if needed. They are connected sequentially in the array order.
* `input` &mdash; the beginning of a pipeline, which should be used as an input for a JSON stream.
* `output` &mdash; the end of a pipeline, which can be used for events, or to pipe the resulting stream of objects for further processing.

The test file for `StreamArray`: `tests/test_array.js`.

### utils/StreamObject

Similar to `StreamArray`, except that instead of breaking an array into its elements it breaks an object into key/value pairs. Each pair has two properties: `key` and `value`.

Like `StreamArray`, `StreamObject` is both a constructor and has a static `make()` function for common use cases.

```js
var StreamObject = require("stream-json/utils/StreamObject");
var stream = StreamObject.make();

// Example of use:

stream.output.on("data", function(object){
  console.log(object.key, object.value);
});
stream.output.on("end", function(){
  console.log("done");
});

fs.createReadStream(fname).pipe(stream.input);
```

See the `StreamArray` documentation for more information.

### utils/StreamFilteredArray

This utility handles the same use case as `StreamArray`, but in addition it allows to check the objects as they are being built to reject, or accept them. Rejected objects are not assembled, and filtered out.

It is a [Transform](https://nodejs.org/api/stream.html#stream_class_stream_transform) stream, which operates in an [objectMode](http://nodejs.org/api/stream.html#stream_object_mode).

Just like `StreamArray`, `StreamFilteredArray` produces a stream of objects in following format:

```js
{index, value}
```

Where `index` is a numeric index in the array starting from 0, and `value` is a corresponding value. All objects are produced strictly sequentially.

```js
var StreamFilteredArray = require("stream-json/utils/StreamFilteredArray");

function f(assembler){
  // test only top-level objects in the array:
  if(assembler.stack.length == 2 && assembler.key === null){
    // make a decision depending on a boolean property "active":
    if(assembler.current.hasOwnProperty("active")){
      // "true" to accept, "false" to reject
      return assembler.current.active;
    }
  }
  // return undefined to indicate our uncertainty at this moment
}

var stream = StreamFilteredArray.make({objectFilter: f});

// Example of use:

stream.output.on("data", function(object){
  console.log(object.index, object.value);
});
stream.output.on("end", function(){
  console.log("done");
});

fs.createReadStream(fname).pipe(stream.input);
```

`StreamFilteredArray` is a constructor, which optionally takes one object: `options`. `options` can contain some technical parameters, which are rarely needs to be specified. You can find it thoroughly documented in [node.js' Stream documentation](http://nodejs.org/api/stream.html). But additionally it recognizes the following property:

* `objectFilter` is a function, which takes an `Assembler` instance as its only argument, and may return following values to indicate its decision:
  * any truthy value indicates that we are interested in this object. `StreamFilteredArray` will stop polling our filter function and will assemble the object for future use.
  * `false` (the exact value) indicates that we should skip this object. `StreamFilteredArray` will stop polling our filter function, and will stop assembling the object, discarding it completely.
  * any other falsy value indicates that we have not enough information (most likely because the object was not assembled yet to make a decision). `StreamFilteredArray` will poll our filter function next time the object changes.

The default for `objectFilter` allows passing all objects.

In general `objectFilter` is called on incomplete objects. It means that if a decision is based on a value of a certain properties, those properties could be unprocessed at that moment. In such case it is reasonable to delay a decision by returning a falsy (but not `false`) value, like `undefined`.

Complete objects are not submitted to a filter function and accepted automatically. It means that all primitive values: booleans, numbers, strings, `null` objects are streamed, and not consulted with `objectFilter`.

If you want to filter out complete objects, including primitive values, use `FilterObjects`.

`StreamFilteredArray` instances expose one property:

* `objectFilter` is a function, which us called for every top-level streamable object. It can be replaced with another function at any time. Usually it is replaced between objects after an accept/reject decision is made.

Directly on `StreamFilteredArray` there is a class-level helper function `make()`, which is an exact clone of `StreamArray.make()`.

The test file for `StreamFilteredArray`: `tests/test_filtered_array.js`.

### utils/StreamJsonObjects

This utility deals with [JSON Streaming](https://en.wikipedia.org/wiki/JSON_Streaming) -- "Concatenated JSON", when values are sent separated syntactically (e.g., `"{}[]"`) or with whitespaces (e.g., `"true 1 null"`), and "Line delimited JSON". The assumption is that while individual values fit in memory, the stream itself does not.

This helper is modeled after `utils/StreamArray`.

It is a [Transform](https://nodejs.org/api/stream.html#stream_class_stream_transform) stream, which operates in [objectMode](http://nodejs.org/api/stream.html#stream_object_mode).

`StreamJsonObjects` produces a stream of objects in following format:

```js
{index, value}
```

Where `index` is a numeric (artificial) index in the stream starting from 0, and `value` is a corresponding value. All objects are produced strictly sequentially.

```js
var StreamJsonObjects = require("stream-json/utils/StreamJsonObjects");
var stream = StreamJsonObjects.make();

// Example of use:

stream.output.on("data", function(object){
  console.log(object.index, object.value);
});
stream.output.on("end", function(){
  console.log("done");
});

fs.createReadStream(fname).pipe(stream.input);
```

`StreamJsonObjects` is a constructor, which optionally takes one object: `options`. `options` can contain some technical parameters, and it is rarely needs to be specified. You can find it thoroughly documented in [node.js' Stream documentation](http://nodejs.org/api/stream.html).

Directly on `StreamJsonObjects` there is a class-level helper function `make()`, which helps to construct a proper pipeline. It is similar to `makeSource()` and takes the same argument `options`. Internally it creates and connects `Combo` and `StreamArray`, and returns an object with three properties:

* `streams` &mdash; an array of streams so you can inspect them individually, if needed. They are connected sequentially in the array order.
* `input` &mdash; the beginning of a pipeline, which should be used as an input for a JSON stream.
* `output` &mdash; the end of a pipeline, which can be used for events, or to pipe the resulting stream of objects for further processing.

The test file for `StreamJsonObjects`: `tests/test_json_stream.js`.

### utils/FilterObjects

This utility filters out complete objects (and primitive values) working with a stream in the same format as `StreamArray` and `StreamFilteredArray`:

```js
{index, value}
```

Where `index` is a numeric index in the array starting from 0, and `value` is a corresponding value. All objects are produced strictly sequentially.

It is a [Transform](https://nodejs.org/api/stream.html#stream_class_stream_transform) stream, which operates in an [objectMode](http://nodejs.org/api/stream.html#stream_object_mode).

```js
var StreamArray   = require("stream-json/utils/StreamArray");
var FilterObjects = require("stream-json/utils/FilterObjects");

function f(item){
  // accept all odd-indexed items, which are:
  // true objects, but not arrays, or nulls
  if(item.index % 2 && item.value &&
      typeof item.value == "object" &&
      !(item.value instanceof Array)){
    return true;
  }
  return false;
}

var stream = StreamArray.make(),
    filter = new FilterObjects({itemFilter: f});

// Example of use:

filter.on("data", function(object){
  console.log(object.index, object.value);
});
filter.on("end", function(){
  console.log("done");
});

fs.createReadStream(fname).pipe(stream.input).pipe(filter);
```

`FilterObjects` is a constructor, which optionally takes one object: `options`. `options` can contain some technical parameters, which are rarely needs to be specified. You can find it thoroughly documented in [node.js' Stream documentation](http://nodejs.org/api/stream.html). But additionally it recognizes the following property:

* `itemFilter` is a function, which takes a `{index, value}` object as its only argument, and may return following values to indicate its decision:
  * any truthy value to accept the object.
  * any falsy value to reject the object.

The default for `itemFilter` accepts all objects.

`FilterObjects` instances expose one property:

* `itemFilter` is a function, which us called for every top-level streamable object. It can be replaced with another function at any time.

The test file for `FilterObjects`: `tests/test_filter_objects.js`.

## Advanced use

The whole library is organized as a set of small components, which can be combined to produce the most effective pipeline. All components are based on node.js [streams](http://nodejs.org/api/stream.html), and [events](http://nodejs.org/api/events.html). They implement all required standard APIs. It is easy to add your own components to solve your unique tasks.

The code of all components are compact and simple. Please take a look at their source code to see how things are implemented, so you can produce your own components in no time.

Obviously, if a bug is found, or a way to simplify existing components, or new generic components are created, which can be reused in a variety of projects, don't hesitate to open a ticket, and/or create a pull request.

## FAQ

### What if my utf-8 data is decoded incorrectly?

`stream-json` does not decode utf-8 relying on Node to do it correctly. Apparently in some cases Node can fail to decode multi-byte characters correctly, when they are split between different buffers. If you encounter that problem (I did not see it in the wild yet), you can solve it by piping an input stream through a sanitizer before sending it to `stream-json` parser. These two packages look promising, and appear to be doing the right thing:
* https://www.npmjs.com/package/utf8-stream
* https://www.npmjs.com/package/utf8-align-stream

## Credits

The test file `tests/sample.json.gz` is a combination of several publicly available datasets merged and compressed with gzip:

* a snapshot of publicly available [Japanese statistics on birth and marriage in JSON](http://dataforjapan.org/dataset/birth-stat/resource/42799d3c-ecee-4b35-9f5a-7fec30596aa2).
* a snapshot of publicly available [US Department of Housing and Urban Development - HUD's published metadata catalog (Schema Version 1.1)](https://catalog.data.gov/dataset/data-catalog).
* a small fake sample made up by me featuring non-ASCII keys, non-ASCII strings, and primitive data missing in other two samples.

## Apendix A: tokens

`Parser`, `AltParser`, and `ClassicParser` produce a stream of tokens cortesy of [parser-toolkit](http://github.com/uhop/parser-toolkit). While normally user should use `Streamer` to convert them to a much simpler JSON-aware event stream, or use `Combo` directly, in some cases it can be advantageous to deal with raw tokens.

Each token is an object with following properties:

* `id` is a string, which uniquely identifies a token.
* `value` is a string, which corresponds to this token, and was actually matched.
* `line` is a line number, where this token was found. All lines are counted from 1.
* `pos` is a position number inside a line (in characters, so `\t` is one character). Position is counted from 1.

Warning: `Parser` does not incliude `line` and `pos` in its tokens.

JSON grammar is defined in `Grammar.js`. It is taken almost verbatim from [JSON.org](http://json.org/).

Following tokens are produced (listed by `id`):

* `ws`: white spaces, usually ignored. (Not produced by `Parser`.)
* `-`: a unary negation used in a negative number either to start a number, or as an exponent sign.
* `+`: used as an exponent sign.
* `0`: zero, as is - '0'.
* `nonZero`: non-zero digit - `/[1-9]/`.
* `.`: a decimal point used in a number.
* `exponent`: 'e' or 'E' as an exponent symbol in a number written in scientific notation.
* `numericChunk`: a string of digits.
* `"`: a double quote, used to open and close a string.
* `plainChunk`: a string of non-escaped characters, used inside a string.
* `escapedChars`: an escaped character, used inside a string.
* `true`: represents a literal `true`.
* `false`: represents a literal `false`.
* `null`: represents a literal `null`.
* `{`: starts an object literal.
* `}`: closes an object literal.
* `[`: starts an array literal.
* `]`: closes an array literal.
* `,`: separates components of an array, or an object.
* `:`: separates a key and its value in an object literal.

## Release History

- 0.6.1 *the technical release.*
- 0.6.0 *added Stringer to convert event streams back to JSON.*
- 0.5.3 *bug fix to allow empty JSON Streaming.*
- 0.5.2 *bug fixes in `Filter`.*
- 0.5.1 *corrected README.*
- 0.5.0 *added support for [JSON Streaming](https://en.wikipedia.org/wiki/JSON_Streaming).*
- 0.4.2 *refreshed dependencies.*
- 0.4.1 *added `StreamObject` by [Sam Noedel](https://github.com/delta62).*
- 0.4.0 *new high-performant Combo component, switched to the previous parser.*
- 0.3.0 *new even faster parser, bug fixes.*
- 0.2.2 *refreshed dependencies.*
- 0.2.1 *added utilities to filter objects on the fly.*
- 0.2.0 *new faster parser, formal unit tests, added utilities to assemble objects on the fly.*
- 0.1.0 *bug fixes, more documentation.*
- 0.0.5 *bug fixes.*
- 0.0.4 *improved grammar.*
- 0.0.3 *the technical release.*
- 0.0.2 *bug fixes.*
- 0.0.1 *the initial release.*

[npm-image]:      https://img.shields.io/npm/v/stream-json.svg
[npm-url]:        https://npmjs.org/package/stream-json
[deps-image]:     https://img.shields.io/david/uhop/stream-json.svg
[deps-url]:       https://david-dm.org/uhop/stream-json
[dev-deps-image]: https://img.shields.io/david/dev/uhop/stream-json.svg
[dev-deps-url]:   https://david-dm.org/uhop/stream-json?type=dev
[travis-image]:   https://img.shields.io/travis/uhop/stream-json.svg
[travis-url]:     https://travis-ci.org/uhop/stream-json

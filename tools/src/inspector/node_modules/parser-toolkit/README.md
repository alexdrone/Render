# parser-toolkit

[![Build status][travis-image]][travis-url]
[![Dependencies][deps-image]][deps-url]
[![devDependencies][dev-deps-image]][dev-deps-url]
[![NPM version][npm-image]][npm-url]


parser-toolkit is a collection of scanner and parser components, which allows fast creation of efficient parser for custom languages. The main point of a toolkit is to support streamable chunked input.

A standard-compiant implementation of JSON is included as a test. This is how JSON is defined:

```js
var ws           = {id: "ws",           pattern: /\s{1,256}/},
    // numeric tokens
    nonZero      = {id: "nonZero",      pattern: /[1-9]/},
    exponent     = {id: "exponent",     pattern: /[eE]/},
    numericChunk = {id: "numericChunk", pattern: /\d{1,256}/},
    // string tokens
    plainChunk   = {id: "plainChunk",   pattern: /[^\"\\]{1,256}/},
    escapedChars = {id: "escapedChars",
        pattern: /\\(?:[bfnrt\"\\\/]|u[0-9a-fA-F]{4})/};

var json = new Grammar({
    main:   [rule("ws"), rule("value")],
    ws:     repeat(ws),
    value:  [
        any(rule("object"), rule("array"), rule("string"),
            rule("number"), ["-", rule("number")],
            "true", "false", "null"),
        rule("ws")
    ],
    object: [
        "{",
            rule("ws"),
            maybe(rule("pair"),
                repeat(",", rule("ws"), rule("pair"))),
        "}"
    ],
    pair:   [
        rule("string"), rule("ws"), ":", rule("ws"), rule("value")
    ],
    array:  [
        "[",
            rule("ws"),
            maybe(rule("value"),
                repeat(",", rule("ws"), rule("value"))),
        "]"
    ],
    string: ["\"", repeat(any(plainChunk, escapedChars)), "\""],
    number: [
        any("0", [nonZero, repeat(numericChunk)]),
        maybe(".", repeat(numericChunk)),
        maybe(exponent, maybe(any("-", "+")),
            numericChunk, repeat(numericChunk))
    ]
});
```

The whole definition is taken verbatim from [JSON.org](http://json.org/).

The test file `sample.json` is copied as is from an open source project [json-simple](https://code.google.com/p/json-simple/) under Apache License 2.0.

[npm-image]:      https://img.shields.io/npm/v/parser-toolkit.svg
[npm-url]:        https://npmjs.org/package/parser-toolkit
[deps-image]:     https://img.shields.io/david/uhop/parser-toolkit.svg
[deps-url]:       https://david-dm.org/uhop/parser-toolkit
[dev-deps-image]: https://img.shields.io/david/dev/uhop/parser-toolkit.svg
[dev-deps-url]:   https://david-dm.org/uhop/parser-toolkit#info=devDependencies
[travis-image]:   https://img.shields.io/travis/uhop/parser-toolkit.svg
[travis-url]:     https://travis-ci.org/uhop/parser-toolkit

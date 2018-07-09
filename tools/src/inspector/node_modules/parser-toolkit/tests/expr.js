/* UMD.define */ (typeof define=="function"&&define||function(d,f,m){m={module:module,require:require};module.exports=f.apply(null,d.map(function(n){return m[n]||require(n)}))})
(["../bottomUp/Grammar"], function(Grammar){
	"use strict";

	var expr = new Grammar({
			operand: {
				// values
				id: {
					pattern: /[A-Za-z_\$]\w*/,
					left:    12000,
					right:   12000,
					next:    "operator"
				},
				num: {
					pattern: /(?:0|[1-9]\d*)(?:\.\d*)?(?:[eE][+-]?\d+)?|\.\d+(?:[eE][+-]?\d+)?/,
					left:    12000,
					right:   12000,
					next:    "operator"
				},
				// unary prefix operators
				"pre++": {
					pattern: "++",
					left:    12000,
					right:    8001,
					next:    "operand"
				},
				"pre--": {
					pattern: "--",
					left:    12000,
					right:    8001,
					next:    "operand"
				},
				"pre+": {
					pattern: "+",
					left:    12000,
					right:    7001,
					next:    "operand"
				},
				"pre-": {
					pattern: "-",
					left:    12000,
					right:    7001,
					next:    "operand"
				},
				// parentheses
				"(": {
					left:  12000,
					right:     0,
					next:  "operand"
				},
				"[": {
					left:  12000,
					right:     0,
					next:  "operand"
				},
				// technical
				ws: {
					pattern: /[\u0009\u000B\u000C\u0020\u00A0\uFEFF]+/,
					left:    12000,
					right:   12000,
					ignore:  true
				},
				crlf: {
					pattern: /[\u000A\u2028\u2029]|\u000D\u000A|\u000D/,
					left:    12000,
					right:   12000,
					ignore:  true
				}
			},
			operator: {
				// unary postfix operators
				"post++": {
					pattern: "++",
					left:     8002,
					right:   12000,
					next:    "operator"
				},
				"post--": {
					pattern: "--",
					left:     8002,
					right:   12000,
					next:    "operator"
				},
				// parentheses
				sub: {
					pattern: "[",
					left:     9998,
					right:       0,
					next:    "operand"
				},
				"]": {
					left:        0,
					right:   10000,
					next:    "operator"
				},
				call: {
					pattern: "(",
					left:     8998,
					right:       0,
					next:    "operand"
				},
				")": {
					left:        0,
					right:    9000,
					next:    "operator"
				},
				// binary operators
				"*": {
					left:     8000,
					right:    8001,
					next:    "operand"
				},
				"/": {
					left:     8000,
					right:    8001,
					next:    "operand"
				},
				"+": {
					left:     7000,
					right:    7001,
					next:    "operand"
				},
				"-": {
					left:     7000,
					right:    7001,
					next:    "operand"
				},
				// technical
				ws: {
					pattern: /[\u0009\u000B\u000C\u0020\u00A0\uFEFF]+/,
					left:    12000,
					right:   12000,
					ignore:  true
				},
				crlf: {
					pattern: /[\u000A\u2028\u2029]|\u000D\u000A|\u000D/,
					left:    12000,
					right:   12000,
					ignore:  true
				}
			},
			brackets: {"(": ")", "[": "]"}
		});

	return expr;
});

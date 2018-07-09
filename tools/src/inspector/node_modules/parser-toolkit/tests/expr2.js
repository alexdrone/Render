/* UMD.define */ (typeof define=="function"&&define||function(d,f,m){m={module:module,require:require};module.exports=f.apply(null,d.map(function(n){return m[n]||require(n)}))})
(["../bottomUp/Grammar"], function(Grammar){
	"use strict";

	function operand(pattern){
		return {
			pattern: pattern,
			left:    0,
			right:   0,
			next:    "operator"
		};
	}

	function prefix(priority, pattern){
		return {
			pattern: pattern,
			left:    priority || 70,
			right:   0,
			next:    "operator"
		};
	}

	function infix(priority, pattern){
		return {
			pattern: pattern,
			left:    priority,
			right:   priority,
			next:    "operand"
		};
	}

	function infixr(priority, pattern){
		return {
			pattern: pattern,
			left:    priority,
			right:   priority - 1,
			next:    "operand"
		};
	}

	function pattern(priority, rule, next){
		return {
			pattern: rule[0],
			left:    priority,
			right:   0,
			rule:    rule,
			next:    next || "operator"
		};
	}

	function maybe(){
		var rule = Array.prototype.slice.call(arguments, 0);
		rule.optional = true;
		return rule;
	}

	function repeat(){
		var rule = Array.prototype.slice.call(arguments, 0);
		rule.optional = true;
		rule.repeatable = true;
		return rule;
	}

	var expr = new Grammar({
			operand: {
				// values
				id:     operand(/[A-Za-z_\$]\w*/),
				num:    operand(/(?:0|[1-9]\d*)(?:\.\d*)?(?:[eE][+-]?\d+)?|\.\d+(?:[eE][+-]?\d+)?/),
				// unary prefix operators
				"pre+": operand("+"),
				"pre-": operand("-"),
				// parentheses
				"(":    operand(),
				"[":    operand(),
				// technical
				ws: {
					pattern: /[\u0009\u000B\u000C\u0020\u00A0\uFEFF]+/,
					ignore:  true
				},
				crlf: {
					pattern: /[\u000A\u2028\u2029]|\u000D\u000A|\u000D/,
					ignore:  true
				}
			},
			operator: {
				// the ternary operator
				"?": pattern(20, ["?", 0, ":", 0]),
				// binary operators
				"*": infix(60),
				"/": infix(60),
				"+": infix(50),
				"-": infix(50),
				// parentheses
				sub:  pattern(80, ["[", 0, "]"]),
				call: pattern(80, ["(", maybe(0, repeat(",", 0)), ")"]),
				// technical
				ws: {
					pattern: /[\u0009\u000B\u000C\u0020\u00A0\uFEFF]+/,
					ignore:  true
				},
				crlf: {
					pattern: /[\u000A\u2028\u2029]|\u000D\u000A|\u000D/,
					ignore:  true
				}
			}
		});

	return expr;
});

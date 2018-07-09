/* UMD.define */ (typeof define=="function"&&define||function(d,f,m){m={module:module,require:require};module.exports=f.apply(null,d.map(function(n){return m[n]||require(n)}))})
([], function(){
	"use strict";

	// Based on the classic stream-based operator precedence parser by Max Motovilov.
	// (c) 2000-2013 Max Motovilov, Eugene Lazutkin, used here under the BSD license.

/*
	Grammar is implemented by a naked object:

	{
		operator: {    // expected state before
			"+": {       // token name
				left:    7000,       // input priority
				right:   7001,       // output priority
				pattern: "+",        // token's pattern
				next:    "operand"   // state after or falsy if the same as before
			}
			// ...
		},
		operand: {
			// ...
		},
		brackets: {    // a reserved name for a bag of brackets
			"(": ")",
			"[": "]"
			// ...
		}
	}

	Priority:

	left == 0       -- end of statement
	left < right    -- left associated operator
	left > right    -- right associated operator

	A left bracket has the same left priority as its corresponding right bracket's right priority.

	State:

	before == "operand"  && after == "operand"    -- unary prefix operator
	before == "operator" && after == "operator"   -- unary postfix operator
	before == "operator" && after == "operand"    -- binary infix operator
	before == "operand"  && after == "operator"   -- operand
*/

	function Grammar(grammar){
		var keys = Object.keys(grammar).filter(function(name){ return name !== "brackets"; });
		// convert and copy states
		this.brackets = grammar.brackets || {};
		keys.forEach(function(name){
			this[name] = convertState(grammar[name]);
		}, this);
	}

	// utilities

	function convertState(state){
		var tokens = Object.keys(state).map(function(name){
				var token = Object.create(state[name]);
				token.id = name;
				if(!token.pattern){
					token.pattern = name;
				}
				sanitizeToken(token);
				return token;
			});
		tokens.sort(tokenComparator);
		// create a state pattern
		var patterns = tokens.map(function(token){
				var pattern = token.pattern.source;
				return pattern.substring(4, pattern.length - 1);
			});
		return {
			tokens:  tokens,
			pattern: new RegExp(patterns.length == 1 ?
				"^(" + patterns[0] + ")" : "^(?:(" + patterns.join(")|(") + "))")
		};
	}

	function toRegExpSource(s){
		return /^[a-zA-Z]\w*$/.test(s) ? s + "\\b" :
			s.replace(/[#-.]|[[-^]|[?|{}]/g, "\\$&");
	}

	function sanitizeToken(token){
		token.literal = typeof token.pattern == "string";
		token.pattern = new RegExp("^(?:" + (token.literal ?
			toRegExpSource(token.pattern) : token.pattern.source) + ")");
	}

	function tokenComparator(a, b){
		if(a.literal ^ b.literal){
			return a.literal ? -1 : 1;
		}
		var ap = a.pattern.source, bp = b.pattern.source;
		if(ap.length != bp.length){
			return ap.length < bp.length ? 1 : -1;
		}
		return ap < bp ? -1 : (ap > bp ? 1 : 0);
	}

	// export

	return Grammar;
});

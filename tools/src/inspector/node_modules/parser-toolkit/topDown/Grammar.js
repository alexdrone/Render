/* UMD.define */ (typeof define=="function"&&define||function(d,f,m){m={module:module,require:require};module.exports=f.apply(null,d.map(function(n){return m[n]||require(n)}))})
([], function(){
	"use strict";

	function Grammar(grammar){
		var keys = Object.keys(grammar);
		// convert and copy rules
		keys.forEach(function(name){
			var rule = grammar[name];
			rule = this[name] = rule instanceof Array ? rule : [rule];
			rule.name = name;
		}, this);
		// expand internal references and prepare states
		var walk = makeWalk(this);
		keys.forEach(function(name){
			this[name] = walk(this[name]);
		}, this);
		// operate on all rules
		keys = Object.keys(this);
		// make states
		keys.forEach(function(name){
			makeState(this[name]);
		}, this);
		// inline states
		keys.forEach(function(name){
			this[name].forEach(function(item, index, rule){
				if(item instanceof Array){
					rule[index] = item.state;
				}
			});
		}, this);
	}

	// helpers

	function rule(name){
		return function(grammar){
			return grammar[name];
		};
	}

	function any(){
		var rule = Array.prototype.slice.call(arguments, 0);
		rule.any = rule.length > 1;
		return rule;
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

	// utilities

	var emptyArray = [];

	function makeWalk(grammar){
		var counter = 0;
		return function walk(item){
			for(; typeof item == "function"; item = item(grammar));
			if(item instanceof Array && !item.touched){
				item.touched = true;
				if(!item.length){
					throw Error("Empty rule: " + (item.name || "internal"));
				}
				item.forEach(function(value, index){
					item[index] = walk(value);
				});
			}
			// post-process
			var conv;
			if(typeof item == "string"){
				conv = makeTokenFromString;
			}else if(item instanceof RegExp){
				conv = makeTokenFromRegExp;
			}else if(item.pattern){
				conv = sanitizeToken;
			}else{
				if(item instanceof Array && !item.name){
					item.name = "_R" + (counter++);
					grammar[item.name] = item;
				}
				return item;
			}
			var token = conv(item);
			token.nextArray = emptyArray;
			token.nextIndex = emptyArray;
			return {tokens: [token], pattern: new RegExp("^(" + token.pattern.source.substring(4))};
		};
	}

	function makeTokenFromString(literal){
		return {
			id:      literal,
			literal: true,
			pattern: new RegExp("^(?:" + toRegExpSource(literal) + ")")
		};
	}

	function makeTokenFromRegExp(literal){
		return {
			id:      literal.source,
			literal: false,
			pattern: new RegExp("^(?:" + literal.source + ")")
		};
	}

	function sanitizeToken(token){
		var p = (typeof token.pattern == "string" ?
				makeTokenFromString : makeTokenFromRegExp)(token.pattern),
			t = Object.create(token);
		t.literal = p.literal;
		t.pattern = p.pattern;
		return t;
	}

	function toRegExpSource(s){
		return /^[a-zA-Z]\w*$/.test(s) ? s + "\\b" :
			s.replace(/[#-.]|[[-^]|[?|{}]/g, "\\$&");
	}

	function getState(rule, index, naked){
		var item = rule[index];
		if(item instanceof Array){
			makeState(item);
			item = item.state;
		}
		if(!naked && typeof item == "object"){
			var newIndex = index + 1;
			if(newIndex === rule.length && rule.repeatable){
				newIndex = 0;
			}
			if(newIndex < rule.length){
				item = Object.create(item);
				item.tokens = item.tokens.map(function(token){
					var t = Object.create(token);
					t.nextArray = [rule].concat(token.nextArray);
					t.nextIndex = [newIndex].concat(token.nextIndex);
					return t;
				});
			}
		}
		return item;
	}

	function makeState(rule){
		if(!rule.state){
			if(rule.any){
				var tokens = [];
				rule.forEach(function(_, index){
					tokens.push.apply(tokens, getState(rule, index, true).tokens);
				});
				rule.state = {tokens: tokens};
			}else{
				if(rule.optional){
					rule.state = {tokens: getState(rule, 0).tokens, optional: true};
				}else{
					var tokens = [],
						optional = rule.every(function(_, index){
							var state = getState(rule, index);
							tokens.push.apply(tokens, state.tokens);
							return state.optional;
						});
					rule.state = {tokens: tokens, optional: optional};
				}
			}
			var patterns = rule.state.tokens.map(function(token){
					var pattern = token.pattern.source;
					return pattern.substring(4, pattern.length - 1);
				});
			rule.state.pattern = new RegExp(patterns.length == 1 ?
				"^(" + patterns[0] + ")" : "^(?:(" + patterns.join(")|(") + "))");
		}
	}

	// export

	Grammar.rule   = rule;
	Grammar.any    = any;
	Grammar.maybe  = maybe;
	Grammar.repeat = repeat;

	return Grammar;
});

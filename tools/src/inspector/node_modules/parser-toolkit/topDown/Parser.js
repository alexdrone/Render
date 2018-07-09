/* UMD.define */ (typeof define=="function"&&define||function(d,f,m){m={module:module,require:require};module.exports=f.apply(null,d.map(function(n){return m[n]||require(n)}))})
([], function(){
	"use strict";

	function Parser(grammar, name, index){
		this.reset(grammar, name, index);
	}

	Parser.prototype = {
		reset: function(grammar, name, index){
			this.expected = null;
			this.triedTokens = [];
			this.arrayStack = [grammar[name || "main"]];
			this.indexStack = [index || 0];
		},
		getExpectedState: function(){
			while(this.arrayStack.length){
				var a = this.arrayStack.pop(),
					i = this.indexStack.pop();
				if(i < a.length){
					var value = a[i++];
					this.arrayStack.push(a);
					this.indexStack.push(i);
					return this.expected = value;
				}
				if(a.repeatable){
					this.arrayStack.push(a);
					this.indexStack.push(0);
				}
			}
			return null;
		},
		putToken: function(token, scanner){
			if(token){
				this.arrayStack.push.apply(this.arrayStack, token.nextArray);
				this.indexStack.push.apply(this.indexStack, token.nextIndex);
				if(this.triedTokens.length){
					this.triedTokens = [];
				}
				this.onToken(token);
			}else{
				// no match: save failed tokens
				this.triedTokens.push.apply(this.triedTokens, this.expected.tokens);
				// check optional items
				if(this.expected.optional){
					return;
				}
				var a = this.arrayStack.pop(),
					i = this.indexStack.pop();
				if(a.optional && i === 1){
					return;
				}
				var buffer = scanner.buffer;
				throw Error("Can't find a legal token" +
						(scanner ? " at (" + scanner.line + ", " + scanner.pos + ") in: " +
							(buffer.length > 16 ?
								(Buffer.isBuffer(buffer) ? buffer.toString("utf8", 0, 16) :
									buffer.substring(0, 16)) + "..." :
								buffer.toString()) + "\n" : ".\n") +
						"Tried: " +
						this.triedTokens.map(function(token){
							return "'" + token.id + "'";
						}).join(", ") + ".");
			}
		},
		onToken: function(token){
			//console.log(token.id + " (" + token.line + ", " + token.pos + "): " + token.value);
		}
	};

	return Parser;
});

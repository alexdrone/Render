/* UMD.define */ (typeof define=="function"&&define||function(d,f,m){m={module:module,require:require};module.exports=f.apply(null,d.map(function(n){return m[n]||require(n)}))})
([], function(){
	"use strict";

	var consumeReadyState = {consume: 1, eos: 1},
		eoi = {id: "End of Input", left: -1, right: -1};

	function Parser2(grammar, name, priority){
		this.reset(grammar, name, priority);
	}

	Parser2.prototype = {
		reset: function(grammar, name, priority){
			this.stack    = [];
			this.state    = "supply";
			this.grammar  = grammar;
			this.expected = name || "main";
			this.priority = priority || 0;
		},
		_consume: function(){
			if(this.state == "eos"){
				this.state = "done";
				return this.token;
			}
			//assert((this.state in consumeReadyState) && this.stack.length);
			var token = this.stack.pop();
			this._decide();
			return token;
		},
		_decide: function(token){
			if(token){
				//assert(this.state == "supply");
				this.token = token;
			}

			var left  = this.token.left,
				right = this.stack.length ? this.stack[this.stack.length - 1].right : this.priority;

			if(right < left){
				this.expected = this.token.next;
				this.stack.push(this.token);
				this.state = "supply";
			}else{
				this.state = this.stack.length ? "consume" : "eos";
			}
		},
		getExpectedState: function(){
			return this.state == "done" ? null : this.grammar[this.expected];
		},
		putToken: function(token, scanner){
			if(token){
				if(!token.ignore){
					//assert(this.state == "supply");
					this._decide(token);
					while(this.state in consumeReadyState){
						token = this._consume();
						if(token !== eoi){
							this.onToken(token);
						}
					}
				}
			}else{
				this.putToken(eoi, scanner);
				if(this.state != "done"){
					throw Error("Can't find a legal token" +
						(scanner ? " at (" + scanner.line + ", " + scanner.pos + ") in: " +
							(scanner.buffer.length > 16 ? scanner.buffer.substring(0, 16) + "..." :
								scanner.buffer) + "\n" : ".\n") +
						"Tried '" + this.expected + "': " +
						this.grammar[this.expected].tokens.map(function(token){
							return "'" + token.id + "'";
						}).join(", ") + ".");
				}
			}
		},
		onToken: function(token){
			console.log(token.id + " (" + token.line + ", " + token.pos + "): " + token.value);
		}
	};

	return Parser2;
});

/* UMD.define */ (typeof define=="function"&&define||function(d,f,m){m={module:module,require:require};module.exports=f.apply(null,d.map(function(n){return m[n]||require(n)}))})
([], function(){
	"use strict";

	function Scanner(){
		this.reset();
	}

	Scanner.prototype = {

		// public interface

		reset: function(){
			this.buffer = "";
			this.line   = this.pos = 1;
			this.noMore = false;
		},

		addBuffer: function(buffer, noMore){
			this.buffer += Buffer.isBuffer(buffer) ? buffer.toString() : buffer;
			this.noMore = noMore;
		},

		isFinished: function(){
			return this.noMore && !this.buffer.length;
		},

		padding: 16,

		// private workings

		newLinePattern: null, // /[\u000A\u2028\u2029]|\u000D\u000A|\u000D/g,

		getToken: function(state, peek){
			var buffer = this.buffer;
			if(!buffer){
				// no input data: true/false for more data
				return !this.noMore;
			}
			var m = state.pattern.exec(buffer);
			if(!m){
				return null;
			}
			if(!this.noMore && m[0].length >= buffer.length - this.padding){
				// need more information
				return true;
			}
			var matched = m[0], index = 0;
			if(state.tokens.length > 1){
				for(index = 1; !m[index]; ++index);
				--index;
			}
			// prepare the found token
			var token   = Object.create(state.tokens[index]);
			token.value = matched;
			token.line  = this.line;
			token.pos   = this.pos;
			// update line and position, if it was not a peek
			if(!peek){
				var rest = matched.length;
				if(this.newLinePattern){
					var self = this;
					matched.replace(this.newLinePattern, function(match, offset){
						rest = matched.length - match.length - offset;
						++self.line;
						self.pos = 1;
						return "";
					});
				}else{
					for(var i = 0, n = rest; i < n; ++i){
						switch(matched.charCodeAt(i)){
							case 0x0A:
							case 0x2028:
							case 0x2029:
								rest = 0;
								break;
							case 0x0D:
								rest = i + 1 < n && matched.charCodeAt(i + 1) === 0x0A ? -1 : 0;
								break;
							default:
								continue;
						}
						rest += n - i - 1;
						++this.line;
						this.pos = 1;
					}
				}
				this.pos += rest;
				this.buffer = buffer.substring(matched.length);
			}
			// done
			return token;
		}
	};

	return Scanner;
});

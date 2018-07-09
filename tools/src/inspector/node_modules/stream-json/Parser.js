"use strict";


var util = require("util");
var Transform = require("stream").Transform;


function Parser(options){
	Transform.call(this, options);
	this._writableState.objectMode = false;
	this._readableState.objectMode = true;

	this._buffer = "";
	this._done   = false;
	this._stack  = [];
	this._parent = "";
	this._jsonStreaming = options && options.jsonStreaming;
	this._expect = this._jsonStreaming ? "done" : "value";
}
util.inherits(Parser, Transform);

Parser.prototype._transform = function transform(chunk, encoding, callback){
	this._buffer += chunk.toString();
	this._processInput(callback);
};

Parser.prototype._flush = function flush(callback){
	this._done = true;
	this._processInput(callback);
};

var value1  = /^(?:[\"\{\[\]\-\d]|true\b|false\b|null\b|\s{1,256})/,
	string  = /^(?:[^\"\\]{1,256}|\\[bfnrt\"\\\/]|\\u[\da-fA-F]{4}|\")/,
	key1    = /^(?:[\"\}]|\s{1,256})/,
	colon   = /^(?:\:|\s{1,256})/,
	comma   = /^(?:[\,\]\}]|\s{1,256})/,
	ws      = /^\s{1,256}/,
	numberStart     = /^\d/,
	numberDigit     = /^\d{0,256}/,
	numberFraction  = /^[\.eE]/,
	numberFracStart = numberStart,
	numberFracDigit = numberDigit,
	numberExponent  = /^[eE]/,
	numberExpSign   = /^[-+]/,
	numberExpStart  = numberStart,
	numberExpDigit  = numberDigit;

Parser.prototype._processInput = function(callback){
	var match, value;
	main: for(;;){
		switch(this._expect){
			case "value1":
			case "value":
				match = value1.exec(this._buffer);
				if(!match){
					if(this._buffer){
						if(this._done){
							return callback(new Error("Parser cannot parse input: expected a value"));
						}
					}
					if(this._done){
						return callback(new Error("Parser has expected a value"));
					}
					// wait for more input
					break main;
				}
				value = match[0];
				switch(value){
					case "\"":
						this.push({id: value, value: value});
						this._expect = "string";
						break;
					case "{":
						this.push({id: value, value: value});
						this._stack.push(this._parent);
						this._parent = "object";
						this._expect = "key1";
						break;
					case "[":
						this.push({id: value, value: value});
						this._stack.push(this._parent);
						this._parent = "array";
						this._expect = "value1";
						break;
					case "]":
						if(this._expect !== "value1"){
							return callback(new Error("Parser cannot parse input: unexpected token ']'"));
						}
						this.push({id: value, value: value});
						this._parent = this._stack.pop();
						if(this._parent){
							this._expect = this._parent === "object" ? "objectStop" : "arrayStop";
						}else{
							this._expect = "done";
						}
						break;
					case "-":
						this.push({id: value, value: value});
						this._expect = "numberStart";
						break;
					case "0":
						this.push({id: value, value: value});
						this._expect = "numberFraction";
						break;
					case "1":
					case "2":
					case "3":
					case "4":
					case "5":
					case "6":
					case "7":
					case "8":
					case "9":
						this.push({id: "nonZero", value: value});
						this._expect = "numberDigit";
						break;
					case "true":
					case "false":
					case "null":
						if(this._buffer.length === value.length && !this._done){
							// wait for more input
							break main;
						}
						this.push({id: value, value: value});
						if(this._parent){
							this._expect = this._parent === "object" ? "objectStop" : "arrayStop";
						}else{
							this._expect = "done";
						}
						break;
					// default: // ws
				}
				this._buffer = this._buffer.substring(value.length);
				break;
			case "keyVal":
			case "string":
				match = string.exec(this._buffer);
				if(!match){
					if(this._buffer){
						if(this._done || this._buffer.length >= 6){
							return callback(new Error("Parser cannot parse input: escaped characters"));
						}
					}
					if(this._done){
						return callback(new Error("Parser has expected a string value"));
					}
					// wait for more input
					break main;
				}
				value = match[0];
				if(value === "\""){
					this.push({id: value, value: value});
					if(this._expect === "keyVal"){
						this._expect = "colon";
					}else{
						if(this._parent){
							this._expect = this._parent === "object" ? "objectStop" : "arrayStop";
						}else{
							this._expect = "done";
						}
					}
				}else if(value.length > 1 && value.charAt(0) === "\\"){
					this.push({id: "escapedChars", value: value});
				}else{
					this.push({id: "plainChunk", value: value});
				}
				this._buffer = this._buffer.substring(value.length);
				break;
			case "key1":
			case "key":
				match = key1.exec(this._buffer);
				if(!match){
					if(this._buffer || this._done){
						return callback(new Error("Parser cannot parse input: expected an object key"));
					}
					// wait for more input
					break main;
				}
				value = match[0];
				if(value === "\""){
					this.push({id: value, value: value});
					this._expect = "keyVal";
				}else if(value === "}"){
					if(this._expect !== "key1"){
						return callback(new Error("Parser cannot parse input: unexpected token '}'"));
					}
					this.push({id: value, value: value});
					this._parent = this._stack.pop();
					if(this._parent){
						this._expect = this._parent === "object" ? "objectStop" : "arrayStop";
					}else{
						this._expect = "done";
					}
				}
				this._buffer = this._buffer.substring(value.length);
				break;
			case "colon":
				match = colon.exec(this._buffer);
				if(!match){
					if(this._buffer || this._done){
						return callback(new Error("Parser cannot parse input: expected ':'"));
					}
					// wait for more input
					break main;
				}
				value = match[0];
				if(value === ":"){
					this.push({id: value, value: value});
					this._expect = "value";
				}
				this._buffer = this._buffer.substring(value.length);
				break;
			case "arrayStop":
			case "objectStop":
				match = comma.exec(this._buffer);
				if(!match){
					if(this._buffer || this._done){
						return callback(new Error("Parser cannot parse input: expected ','"));
					}
					// wait for more input
					break main;
				}
				value = match[0];
				if(value === ","){
					this.push({id: value, value: value});
					this._expect = this._expect === "arrayStop" ? "value" : "key";
				}else if(value === "}" || value === "]"){
					this.push({id: value, value: value});
					this._parent = this._stack.pop();
					if(this._parent){
						this._expect = this._parent === "object" ? "objectStop" : "arrayStop";
					}else{
						this._expect = "done";
					}
				}
				this._buffer = this._buffer.substring(value.length);
				break;
			// number chunks
			case "numberStart": // [0-9]
				match = numberStart.exec(this._buffer);
				if(!match){
					if(this._buffer || this._done){
						return callback(new Error("Parser cannot parse input: expected a digit"));
					}
					// wait for more input
					break main;
				}
				value = match[0];
				if(value === "0"){
					this.push({id: value, value: value});
					this._expect = "numberFraction";
				}else{
					this.push({id: "nonZero", value: value});
					this._expect = "numberDigit";
				}
				this._buffer = this._buffer.substring(value.length);
				break;
			case "numberDigit": // [0-9]*
				match = numberDigit.exec(this._buffer);
				value = match[0];
				if(value){
					this.push({id: "numericChunk", value: value});
					this._buffer = this._buffer.substring(value.length);
				}else{
					if(this._buffer){
						this._expect = "numberFraction";
						break;
					}
					if(this._done){
						if(this._parent){
							this._expect = this._parent === "object" ? "objectStop" : "arrayStop";
						}else{
							this._expect = "done";
						}
						break;
					}
					// wait for more input
					break main;
				}
				break;
			case "numberFraction": // [\.eE]?
				match = numberFraction.exec(this._buffer);
				if(!match){
					if(this._buffer || this._done){
						if(this._parent){
							this._expect = this._parent === "object" ? "objectStop" : "arrayStop";
						}else{
							this._expect = "done";
						}
						break;
					}
					// wait for more input
					break main;
				}
				value = match[0];
				if(value === "."){
					this.push({id: value, value: value});
					this._expect = "numberFracStart";
				}else{
					this.push({id: "exponent", value: value});
					this._expect = "numberExpSign";
				}
				this._buffer = this._buffer.substring(value.length);
				break;
			case "numberFracStart": // [0-9]
				match = numberFracStart.exec(this._buffer);
				if(!match){
					if(this._buffer || this._done){
						return callback(new Error("Parser cannot parse input: expected a fractional part of a number"));
					}
					// wait for more input
					break main;
				}
				value = match[0];
				this.push({id: "numericChunk", value: value});
				this._expect = "numberFracDigit";
				this._buffer = this._buffer.substring(value.length);
				break;
			case "numberFracDigit": // [0-9]*
				match = numberFracDigit.exec(this._buffer);
				value = match[0];
				if(value){
					this.push({id: "numericChunk", value: value});
					this._buffer = this._buffer.substring(value.length);
				}else{
					if(this._buffer){
						this._expect = "numberExponent";
						break;
					}
					if(this._done){
						if(this._parent){
							this._expect = this._parent === "object" ? "objectStop" : "arrayStop";
						}else{
							this._expect = "done";
						}
						break;
					}
					// wait for more input
					break main;
				}
				break;
			case "numberExponent": // [eE]?
				match = numberExponent.exec(this._buffer);
				if(!match){
					if(this._buffer){
						if(this._parent){
							this._expect = this._parent === "object" ? "objectStop" : "arrayStop";
						}else{
							this._expect = "done";
						}
						break;
					}
					if(this._done){
						this._expect = "done";
						break;
					}
					// wait for more input
					break main;
				}
				value = match[0];
				this.push({id: "exponent", value: value});
				this._expect = "numberExpSign";
				this._buffer = this._buffer.substring(value.length);
				break;
			case "numberExpSign": // [-+]?
				match = numberExpSign.exec(this._buffer);
				if(!match){
					if(this._buffer){
						this._expect = "numberExpStart";
						break;
					}
					if(this._done){
						return callback(new Error("Parser has expected an exponent value of a number"));
					}
					// wait for more input
					break main;
				}
				value = match[0];
				this.push({id: value, value: value});
				this._expect = "numberExpStart";
				this._buffer = this._buffer.substring(value.length);
				break;
			case "numberExpStart": // [0-9]
				match = numberExpStart.exec(this._buffer);
				if(!match){
					if(this._buffer || this._done){
						return callback(new Error("Parser cannot parse input: expected an exponent part of a number"));
					}
					// wait for more input
					break main;
				}
				value = match[0];
				this.push({id: "numericChunk", value: value});
				this._expect = "numberExpDigit";
				this._buffer = this._buffer.substring(value.length);
				break;
			case "numberExpDigit": // [0-9]*
				match = numberExpDigit.exec(this._buffer);
				value = match[0];
				if(value){
					this.push({id: "numericChunk", value: value});
					this._buffer = this._buffer.substring(value.length);
				}else{
					if(this._buffer || this._done){
						if(this._parent){
							this._expect = this._parent === "object" ? "objectStop" : "arrayStop";
						}else{
							this._expect = "done";
						}
						break;
					}
					// wait for more input
					break main;
				}
				break;
			case "done":
				match = ws.exec(this._buffer);
				if(!match){
					if(this._buffer){
						if(this._jsonStreaming){
							this._expect = "value";
							break;
						}
						return callback(new Error("Parser cannot parse input: unexpected characters"));
					}
					// wait for more input
					break main;
				}
				this._buffer = this._buffer.substring(match[0].length);
				break;
		}
	}
	callback();
}

module.exports = Parser;

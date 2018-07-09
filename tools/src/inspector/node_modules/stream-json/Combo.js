"use strict";


var util = require("util");
var Transform = require("stream").Transform;


function Parser(options){
	Transform.call(this, options);
	this._writableState.objectMode = false;
	this._readableState.objectMode = true;

	if(options){
		this._packKeys      = options.packKeys;
		this._packStrings   = options.packStrings;
		this._packNumbers   = options.packNumbers;
		this._jsonStreaming = options.jsonStreaming;
	}

	this._buffer = "";
	this._done   = false;
	this._expect = this._jsonStreaming ? "done" : "value";
	this._stack  = [];
	this._parent = "";
	this._open_number = false;
	this._accumulator = "";
}
util.inherits(Parser, Transform);

Parser.prototype._transform = function transform(chunk, encoding, callback){
	this._buffer += chunk.toString();
	this._processInput(callback);
};

Parser.prototype._flush = function flush(callback){
	this._done = true;
	this._processInput(function(err){
		if(err){
			callback(err);
		}else{
			if(this._open_number){
				this.push({name: "endNumber"});
				this._open_number = false;
				if(this._packNumbers){
					this.push({name: "numberValue", value: this._accumulator});
					this._accumulator = "";
				}
			}
			callback();
		}
	}.bind(this));
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

var values   = {"true": true, "false": false, "null": null},
	expected = {object: "objectStop", array: "arrayStop", "": "done"};

// long hexadecimal codes: \uXXXX
function fromHex(s){ return String.fromCharCode(parseInt(s.slice(2), 16)); }

// short codes: \b \f \n \r \t \" \\ \/
var codes = {b: "\b", f: "\f", n: "\n", r: "\r", t: "\t", '"': '"', "\\": "\\", "/": "/"};

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
						this.push({name: "startString"});
						this._expect = "string";
						break;
					case "{":
						this.push({name: "startObject"});
						this._stack.push(this._parent);
						this._parent = "object";
						this._expect = "key1";
						break;
					case "[":
						this.push({name: "startArray"});
						this._stack.push(this._parent);
						this._parent = "array";
						this._expect = "value1";
						break;
					case "]":
						if(this._expect !== "value1"){
							return callback(new Error("Parser cannot parse input: unexpected token ']'"));
						}
						if(this._open_number){
							this.push({name: "endNumber"});
							this._open_number = false;
							if(this._packNumbers){
								this.push({name: "numberValue", value: this._accumulator});
								this._accumulator = "";
							}
						}
						this.push({name: "endArray"});
						this._parent = this._stack.pop();
						this._expect = expected[this._parent];
						break;
					case "-":
						this._open_number = true;
						this.push({name: "startNumber"});
						this.push({name: "numberChunk", value: "-"});
						if(this._packNumbers){
							this._accumulator = "-";
						}
						this._expect = "numberStart";
						break;
					case "0":
						this._open_number = true;
						this.push({name: "startNumber"});
						this.push({name: "numberChunk", value: "0"});
						if(this._packNumbers){
							this._accumulator = "0";
						}
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
						this._open_number = true;
						this.push({name: "startNumber"});
						this.push({name: "numberChunk", value: value});
						if(this._packNumbers){
							this._accumulator = value;
						}
						this._expect = "numberDigit";
						break;
					case "true":
					case "false":
					case "null":
						if(this._buffer.length === value.length && !this._done){
							// wait for more input
							break main;
						}
						this.push({name: value + "Value", value: values[value]});
						this._expect = expected[this._parent];
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
					if(this._expect === "keyVal"){
						this.push({name: "endKey"});
						if(this._packKeys){
							this.push({name: "keyValue", value: this._accumulator});
							this._accumulator = "";
						}
						this._expect = "colon";
					}else{
						this.push({name: "endString"});
						if(this._packStrings){
							this.push({name: "stringValue", value: this._accumulator});
							this._accumulator = "";
						}
						this._expect = expected[this._parent];
					}
				}else if(value.length > 1 && value.charAt(0) === "\\"){
					var t = value.length == 2 ? codes[value.charAt(1)] : fromHex(value);
					this.push({name: "stringChunk", value: t});
					if(this._expect === "keyVal" ? this._packKeys : this._packStrings){
						this._accumulator += t;
					}
				}else{
					this.push({name: "stringChunk", value: value});
					if(this._expect === "keyVal" ? this._packKeys : this._packStrings){
						this._accumulator += value;
					}
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
					this.push({name: "startKey"});
					this._expect = "keyVal";
				}else if(value === "}"){
					if(this._expect !== "key1"){
						return callback(new Error("Parser cannot parse input: unexpected token '}'"));
					}
					this.push({name: "endObject"});
					this._parent = this._stack.pop();
					this._expect = expected[this._parent];
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
				if(this._open_number){
					this.push({name: "endNumber"});
					this._open_number = false;
					if(this._packNumbers){
						this.push({name: "numberValue", value: this._accumulator});
						this._accumulator = "";
					}
				}
				value = match[0];
				if(value === ","){
					this._expect = this._expect === "arrayStop" ? "value" : "key";
				}else if(value === "}" || value === "]"){
					this.push({name: value === "}" ? "endObject" : "endArray"});
					this._parent = this._stack.pop();
					this._expect = expected[this._parent];
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
				this.push({name: "numberChunk", value: value});
				if(this._packNumbers){
					this._accumulator += value;
				}
				this._expect = value === "0" ? "numberFraction" : "numberDigit";
				this._buffer = this._buffer.substring(value.length);
				break;
			case "numberDigit": // [0-9]*
				match = numberDigit.exec(this._buffer);
				value = match[0];
				if(value){
					this.push({name: "numberChunk", value: value});
					if(this._packNumbers){
						this._accumulator += value;
					}
					this._buffer = this._buffer.substring(value.length);
				}else{
					if(this._buffer){
						this._expect = "numberFraction";
						break;
					}
					if(this._done){
						this._expect = expected[this._parent];
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
						this._expect = expected[this._parent];
						break;
					}
					// wait for more input
					break main;
				}
				value = match[0];
				this.push({name: "numberChunk", value: value});
				if(this._packNumbers){
					this._accumulator += value;
				}
				this._expect = value === "." ? "numberFracStart" : "numberExpSign";
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
				this.push({name: "numberChunk", value: value});
				if(this._packNumbers){
					this._accumulator += value;
				}
				this._expect = "numberFracDigit";
				this._buffer = this._buffer.substring(value.length);
				break;
			case "numberFracDigit": // [0-9]*
				match = numberFracDigit.exec(this._buffer);
				value = match[0];
				if(value){
					this.push({name: "numberChunk", value: value});
					if(this._packNumbers){
						this._accumulator += value;
					}
					this._buffer = this._buffer.substring(value.length);
				}else{
					if(this._buffer){
						this._expect = "numberExponent";
						break;
					}
					if(this._done){
						this._expect = expected[this._parent];
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
						this._expect = expected[this._parent];
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
				this.push({name: "numberChunk", value: value});
				if(this._packNumbers){
					this._accumulator += value;
				}
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
				this.push({name: "numberChunk", value: value});
				if(this._packNumbers){
					this._accumulator += value;
				}
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
				this.push({name: "numberChunk", value: value});
				if(this._packNumbers){
					this._accumulator += value;
				}
				this._expect = "numberExpDigit";
				this._buffer = this._buffer.substring(value.length);
				break;
			case "numberExpDigit": // [0-9]*
				match = numberExpDigit.exec(this._buffer);
				value = match[0];
				if(value){
					this.push({name: "numberChunk", value: value});
					if(this._packNumbers){
						this._accumulator += value;
					}
					this._buffer = this._buffer.substring(value.length);
				}else{
					if(this._buffer || this._done){
						this._expect = expected[this._parent];
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
				if(this._open_number){
					this.push({name: "endNumber"});
					this._open_number = false;
					if(this._packNumbers){
						this.push({name: "numberValue", value: this._accumulator});
						this._accumulator = "";
					}
				}
				this._buffer = this._buffer.substring(match[0].length);
				break;
		}
	}
	callback();
}

module.exports = Parser;

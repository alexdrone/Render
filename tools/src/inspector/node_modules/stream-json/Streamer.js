"use strict";


var util = require("util");
var Transform = require("stream").Transform;


// utilities

// long hexadecimal codes: \uXXXX
function fromHex(s){
	return String.fromCharCode(parseInt(s.slice(2), 16));
}

// short codes: \b \f \n \r \t \" \\ \/
var codes = {b: "\b", f: "\f", n: "\n", r: "\r", t: "\t", '"': '"', "\\": "\\", "/": "/"};


// Streamer

function Streamer(options){
	Transform.call(this, options);
	this._writableState.objectMode = true;
	this._readableState.objectMode = true;

	this._stack = [];
	this._state = "";
	this._counter = 0;
}
util.inherits(Streamer, Transform);

Streamer.prototype._transform = function transform(chunk, encoding, callback){
	switch(chunk.id){
		case "{": // object starts
			this.push({name: "startObject"});
			this._pushState("object");
			break;
		case "}": // object ends
			if(this._state === "number"){
				this.push({name: "endNumber"});
				this._popState();
			}
			this.push({name: "endObject"});
			this._popState();
			break;
		case "[": // array starts
			this.push({name: "startArray"});
			this._pushState("array");
			break;
		case "]": // array ends
			if(this._state === "number"){
				this.push({name: "endNumber"});
				this._popState();
			}
			this.push({name: "endArray"});
			this._popState();
			break;
		case "\"": // string starts/ends
			if(this._state === "string"){
				this._popState();
				this.push({name: this._state === "object" &&
					this._counter % 2 ? "endKey" : "endString"});
			}else{
				this.push({name: this._state === "object" &&
					!(this._counter % 2) ? "startKey" : "startString"});
				this._pushState("string");
			}
			break;
		case "null": // null
			this.push({name: "nullValue", value: null});
			++this._counter;
			break;
		case "true": // true
			this.push({name: "trueValue", value: true});
			++this._counter;
			break;
		case "false": // false
			this.push({name: "falseValue", value: false});
			++this._counter;
			break;
		case "0": // number and its fragments
		case "+":
		case "-":
		case ".":
		case "nonZero":
		case "numericChunk":
		case "exponent":
			if(this._state !== "number"){
				this.push({name: "startNumber"});
				this._pushState("number");
			}
			this.push({name: "numberChunk", value: chunk.value});
			break;
		case "plainChunk": // string fragments
			this.push({name: "stringChunk", value: chunk.value});
			break;
		case "escapedChars":
			this.push({name: "stringChunk", value:
				chunk.value.length == 2 ? codes[chunk.value.charAt(1)] : fromHex(chunk.value)});
			break;
		default: // white space, punctuations
			if(this._state === "number"){
				this.push({name: "endNumber"});
				this._popState();
			}
			break;
	}
	callback();
};

Streamer.prototype._flush = function flush(callback){
	if(this._state === "number"){
		this.push({name: "endNumber"});
	}
	callback();
};

Streamer.prototype._pushState = function pushState(state){
	this._stack.push({state: this._state, counter: this._counter});
	this._state   = state;
	this._counter = 0;
};

Streamer.prototype._popState = function popState(){
	var frame     = this._stack.pop();
	this._state   = frame.state;
	this._counter = frame.counter + 1;
};


module.exports = Streamer;

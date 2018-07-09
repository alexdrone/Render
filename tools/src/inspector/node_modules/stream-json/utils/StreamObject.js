"use strict";

var util = require("util");
var Transform = require("stream").Transform;

var Assembler = require("./Assembler");

var Combo = require("../Combo");


function StreamObject(options){
	Transform.call(this, options);
	this._writableState.objectMode = true;
	this._readableState.objectMode = true;

	this._assembler = null;
	this._lastKey = null;
}
util.inherits(StreamObject, Transform);

StreamObject.prototype._transform = function transform(chunk, encoding, callback){
	if(!this._assembler){
		// first chunk should open an object
		if(chunk.name !== "startObject"){
			callback(new Error("Top-level construct should be an object."));
			return;
		}
		this._assembler = new Assembler();
	}

	this._assembler[chunk.name] && this._assembler[chunk.name](chunk.value);

	if(!this._assembler.stack.length){
		if(this._assembler.key === null){
			if(this._lastKey !== null){
				this.push({key: this._lastKey, value: this._assembler.current[this._lastKey]});
				delete this._assembler.current[this._lastKey];
				this._lastKey = null;
			}
		}else{
			this._lastKey = this._assembler.key;
		}
	}

	callback();
};

StreamObject.make = function make(options){
	var o = options ? Object.create(options) : {};
	o.packKeys = o.packStrings = o.packNumbers = true;

	var streams = [new Combo(o), new StreamObject(options)];

	// connect pipes
	var input = streams[0], output = input;
	streams.forEach(function(stream, index){
		if(index){
			output = output.pipe(stream);
		}
	});

	return {streams: streams, input: input, output: output};
};

module.exports = StreamObject;

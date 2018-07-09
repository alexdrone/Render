"use strict";


var util = require("util");
var Transform = require("stream").Transform;

var Assembler = require("./Assembler");

var Combo = require("../Combo");


function StreamArray(options){
	Transform.call(this, options);
	this._writableState.objectMode = true;
	this._readableState.objectMode = true;

	this._assembler = null;
	this._counter = 0;
}
util.inherits(StreamArray, Transform);

StreamArray.prototype._transform = function transform(chunk, encoding, callback){
	if(!this._assembler){
		// first chunk should open an array
		if(chunk.name !== "startArray"){
			callback(new Error("Top-level object should be an array."));
			return;
		}
		this._assembler = new Assembler();
	}

	this._assembler[chunk.name] && this._assembler[chunk.name](chunk.value);

	if(!this._assembler.stack.length && this._assembler.current.length){
		this.push({index: this._counter++, value: this._assembler.current.pop()});
	}

	callback();
};

StreamArray.make = function make(options){
	var o = options ? Object.create(options) : {};
	o.packKeys = o.packStrings = o.packNumbers = true;

	var streams = [new Combo(o), new StreamArray(options)];

	// connect pipes
	var input = streams[0], output = input;
	streams.forEach(function(stream, index){
		if(index){
			output = output.pipe(stream);
		}
	});

	return {streams: streams, input: input, output: output};
};

module.exports = StreamArray;

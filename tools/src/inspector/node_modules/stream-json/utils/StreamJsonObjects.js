"use strict";


var util = require("util");
var Transform = require("stream").Transform;

var Assembler = require("./Assembler");

var Combo = require("../Combo");


function StreamJsonObjects(options){
	Transform.call(this, options);
	this._writableState.objectMode = true;
	this._readableState.objectMode = true;

	this._assembler = null;
	this._counter = this._depth = 0;
}
util.inherits(StreamJsonObjects, Transform);

StreamJsonObjects.prototype._transform = function transform(chunk, encoding, callback){
	if(!this._assembler){
		this._assembler = new Assembler();
	}

	if(this._assembler[chunk.name]){
		this._assembler[chunk.name](chunk.value);

		switch(chunk.name){
			case "startObject":
			case "startArray":
				++this._depth;
				break;
			case "endObject":
			case "endArray":
				--this._depth;
				break;
		}

		if(!this._depth){
			this.push({index: this._counter++, value: this._assembler.current});
			this._assembler.current = this._assembler.key = null;
		}
	}

	callback();
};

StreamJsonObjects.make = function make(options){
	var o = options ? Object.create(options) : {};
	o.packKeys = o.packStrings = o.packNumbers = o.jsonStreaming = true;

	var streams = [new Combo(o), new StreamJsonObjects(options)];

	// connect pipes
	var input = streams[0], output = input;
	streams.forEach(function(stream, index){
		if(index){
			output = output.pipe(stream);
		}
	});

	return {streams: streams, input: input, output: output};
};

module.exports = StreamJsonObjects;

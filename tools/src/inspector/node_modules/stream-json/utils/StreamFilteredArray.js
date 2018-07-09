"use strict";


var util = require("util");
var Transform = require("stream").Transform;

var Assembler = require("./Assembler");

var Combo = require("../Combo");


function defaultObjectFilter () { return true; }


function StreamFilteredArray(options){
	Transform.call(this, options);
	this._writableState.objectMode = true;
	this._readableState.objectMode = true;

	this.objectFilter = options && options.objectFilter;
	if(typeof this.objectFilter != "function"){
		this.objectFilter = defaultObjectFilter;
	}

	this._processChunk = this._doCheck;
	this._subObjectCounter = 0;

	this._assembler = null;
	this._counter = 0;
}
util.inherits(StreamFilteredArray, Transform);

StreamFilteredArray.prototype._transform = function transform(chunk, encoding, callback){
	if(this._assembler){
		this._processChunk(chunk);
	}else{
		// first chunk should open an array
		if(chunk.name !== "startArray"){
			callback(new Error("Top-level object should be an array."));
			return;
		}
		this._assembler = new Assembler();
		this._assembler[chunk.name] && this._assembler[chunk.name](chunk.value);
	}
	callback();
};

StreamFilteredArray.prototype._doCheck = function doCheck(chunk){
	if(!this._assembler[chunk.name]){
		return;
	}

	this._assembler[chunk.name](chunk.value);

	if(!this._assembler.stack.length){
		if(this._assembler.current.length){
			this.push({index: this._counter++, value: this._assembler.current.pop()});
		}
		return;
	}

	if(this._assembler.key === null && this._assembler.stack.length){
		var result = this.objectFilter(this._assembler);
		if(result){
			this._processChunk = this._skipCheck;
		}else if(result === false){
			this._processChunk = this._skipObject;
		}
	}
};

StreamFilteredArray.prototype._skipCheck = function skipCheck(chunk){
	if(!this._assembler[chunk.name]){
		return;
	}

	this._assembler[chunk.name](chunk.value);

	if(!this._assembler.stack.length && this._assembler.current.length){
		this.push({index: this._counter++, value: this._assembler.current.pop()});
		this._processChunk = this._doCheck;
	}
};

StreamFilteredArray.prototype._skipObject = function skipObject(chunk){
	switch(chunk.name){
		case "startArray":
		case "startObject":
			++this._subObjectCounter;
			return;
		case "endArray":
		case "endObject":
			break;
		default:
			return;
	}
	if(this._subObjectCounter){
		--this._subObjectCounter;
		return;
	}

	this._assembler[chunk.name] && this._assembler[chunk.name](chunk.value);

	if(!this._assembler.stack.length && this._assembler.current.length){
		++this._counter;
		this._assembler.current.pop();
		this._processChunk = this._doCheck;
	}
};

StreamFilteredArray.make = function make(options){
	var o = options ? Object.create(options) : {};
	o.packKeys = o.packStrings = o.packNumbers = true;

	var streams = [new Combo(o), new StreamFilteredArray(options)];

	// connect pipes
	var input = streams[0], output = input;
	streams.forEach(function(stream, index){
		if(index){
			output = output.pipe(stream);
		}
	});

	return {streams: streams, input: input, output: output};
};

module.exports = StreamFilteredArray;

"use strict";


var util = require("util");
var Writable = require("stream").Writable;


function Emitter(options){
	Writable.call(this, options);
	this._writableState.objectMode = true;
}
util.inherits(Emitter, Writable);

Emitter.prototype._write = function write(chunk, encoding, callback){
	this.emit(chunk.name, chunk.value);
	callback();
};


module.exports = Emitter;

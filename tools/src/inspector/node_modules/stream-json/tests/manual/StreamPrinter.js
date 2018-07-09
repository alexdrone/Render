var util = require("util");
var Writable = require("stream").Writable;


function StreamPrinter(options){
	Writable.call(this, options);
	this._writableState.objectMode = true;
}
util.inherits(StreamPrinter, Writable);

StreamPrinter.prototype._write = function write(chunk, encoding, callback){
	if(typeof chunk.value == "undefined"){
		console.log(chunk.name);
	}else{
		console.log(chunk.name + ": " + chunk.value);
	}
	callback();
};


module.exports = StreamPrinter;

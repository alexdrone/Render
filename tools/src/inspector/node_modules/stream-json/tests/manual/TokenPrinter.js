var util = require("util");
var Writable = require("stream").Writable;


function TokenPrinter(options){
	Writable.call(this, options);
	this._writableState.objectMode = true;
}
util.inherits(TokenPrinter, Writable);

TokenPrinter.prototype._write = function write(chunk, encoding, callback){
	console.log(chunk.id + " (" + chunk.line + ", " + chunk.pos + "): " + chunk.value);
	callback();
};


module.exports = TokenPrinter;

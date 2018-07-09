var util = require("util");
var Readable = require("stream").Readable;


function ReadString(string, quant, options){
	Readable.call(this, options);
	this._string = string;
	this._quant  = quant;
}
util.inherits(ReadString, Readable);

ReadString.prototype._read = function read(size){
	if(isNaN(this._quant)){
		this.push(this._string, "utf8");
	}else{
		for(var i = 0; i < this._string.length; i += this._quant){
			this.push(this._string.substr(i, this._quant), "utf8");
		}
	}
	this.push(null);
};


module.exports = ReadString;

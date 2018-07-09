"use strict";


var util = require("util");
var Transform = require("stream").Transform;


function Packer(options){
	Transform.call(this, options);
	this._writableState.objectMode = true;
	this._readableState.objectMode = true;

	this._eventMap = {};
	this._buffer   = "";

	if(options.packKeys){
		this._eventMap.startKey    = "_collectString";
		this._eventMap.endKey      = "_sendKey";
	}
	if(options.packStrings){
		this._eventMap.startString = "_collectString";
		this._eventMap.endString   = "_sendString";
	}
	if(options.packNumbers){
		this._eventMap.startNumber = "_collectNumber";
		this._eventMap.endNumber   = "_sendNumber";
	}
}
util.inherits(Packer, Transform);

Packer.prototype._transform = function transform(chunk, encoding, callback){
	this.push(chunk);
	if(this._eventMap[chunk.name]){
		this[this._eventMap[chunk.name]](chunk);
	}
	callback();
};

Packer.prototype._addToBuffer = function addToBuffer(chunk){
	this._buffer += chunk.value;
};

Packer.prototype._collectString = function collectString(){
	this._eventMap.stringChunk = "_addToBuffer";
};

Packer.prototype._collectNumber = function collectNumber(){
	this._eventMap.numberChunk = "_addToBuffer";
};

Packer.prototype._sendKey = function sendKey(){
	this.push({name: "keyValue", value: this._buffer});
	this._buffer = "";
	this._eventMap.stringChunk = null;
};

Packer.prototype._sendString = function sendString(){
	this.push({name: "stringValue", value: this._buffer});
	this._buffer = "";
	this._eventMap.stringChunk = null;
};

Packer.prototype._sendNumber = function sendNumber(){
	this.push({name: "numberValue", value: this._buffer});
	this._buffer = "";
	this._eventMap.numberChunk = null;
};


module.exports = Packer;

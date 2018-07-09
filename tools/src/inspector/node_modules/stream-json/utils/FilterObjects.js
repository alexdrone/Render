"use strict";


var util = require("util");
var Transform = require("stream").Transform;


function defaultItemFilter () { return true; }


function FilterObjects(options){
	Transform.call(this, options);
	this._writableState.objectMode = true;
	this._readableState.objectMode = true;

	this.itemFilter = options && options.itemFilter;
	if(typeof this.itemFilter != "function"){
		this.itemFilter = defaultItemFilter;
	}
}
util.inherits(FilterObjects, Transform);

FilterObjects.prototype.setFilter = function setFilter(newItemFilter){
	if(typeof newItemFilter != "function"){
		newItemFilter = defaultItemFilter;
	}
	this.itemFilter = newItemFilter;
};

FilterObjects.prototype._transform = function transform(chunk, encoding, callback){
	if(this.itemFilter(chunk)){
		this.push(chunk);
	}
	callback();
};


module.exports = FilterObjects;

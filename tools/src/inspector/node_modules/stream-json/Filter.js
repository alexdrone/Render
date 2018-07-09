"use strict";


var util = require("util");
var Transform = require("stream").Transform;


function Filter(options){
	Transform.call(this, options);
	this._writableState.objectMode = true;
	this._readableState.objectMode = true;

	var f = options.filter;
	if(typeof f == "function"){
		this._func = f;
	}else if(f instanceof RegExp){
		this._regexp = f;
		this._func = this._pattern;
	}else{
		this._func = this._allowAll;
	}
	this._separator = options.separator || ".";
	this._defaultValue = options.defaultValue || [{name: "nullValue", value: null}];

	this._previous = [];
	this._stack = [];
	this._collectKey = false;
	this._key = "";
}
util.inherits(Filter, Transform);

Filter.prototype._transform = function transform(chunk, encoding, callback){
	// skip keys
	if(this._collectKey){
		if(chunk.name === "endKey"){
			this._collectKey = false;
			this._stack.pop();
			this._stack.push(this._key);
			this._key = "";
		}else{
			this._key += chunk.value;
		}
		callback();
		return;
	}

	switch(chunk.name){
		case "startKey":
			this._collectKey = true;
			// intentional fall down
		case "keyValue":
			callback();
			return;
		case "startObject":
		case "startArray":
		case "startString":
		case "startNumber":
		case "nullValue":
		case "trueValue":
		case "falseValue":
			// update array's index
			if(this._stack.length){
				var top = this._stack[this._stack.length - 1];
				if(top === false){
					this._stack[this._stack.length - 1] = 0;
				}else if(typeof top == "number"){
					this._stack[this._stack.length - 1] = top + 1;
				}
			}
			break;
	}

	switch(chunk.name){
		case "startObject":
			this._stack.push(true);
			break;
		case "startArray":
			this._stack.push(false);
			break;
		case "endObject":
		case "endArray":
			this._stack.pop();
			break;
	}

	// check if the chunk should be outputted
	if(this._func(this._stack, chunk)){
		switch(chunk.name){
			case "startObject":
			case "startArray":
			case "endObject":
			case "endArray":
				this._sync();
				break;
			default:
				this._sync();
				this.push(chunk);
				break;
		}
	}

	callback();
};

Filter.prototype._flush = function flush(callback){
	this._stack = [];
	this._sync();
	callback();
}

Filter.prototype._sync = function sync(){
	var p = this._previous, pl = p.length,
		s = this._stack, sl = s.length,
		n = Math.min(pl, sl), i, j, k, value;
	for(i = 0; i < n && p[i] === s[i]; ++i);
	if(pl === sl && i >= n){
		return;
	}
	for(j = pl - 1, k = n && i < n ? i : i - 1; j > k; --j){
		value = p[j];
		if(value === true){
			this.push({name: "startObject"});
			this.push({name: "endObject"});
		}else if(value === false){
			this.push({name: "startArray"});
			this.push({name: "endArray"});
		}else{
			this.push({name: typeof value == "number" ? "endArray" : "endObject"});
		}
	}
	if(n && i < n){
		if(p[i] === true || typeof p[i] == "string"){
			if(p[i] === true){
				this.push({name: "startObject"});
			}
			value = s[i];
			this.push({name: "startKey"});
			this.push({name: "stringChunk", value: value});
			this.push({name: "endKey"});
			this.push({name: "keyValue", value: value});
		}else if(p[i] === false || typeof p[i] == "number"){
			if(p[i] === false){
				this.push({name: "startArray"});
			}
			if(this._defaultValue.length){
				value = s[i] || 0;
				for(j = (p[i] || 0) + 1; j < value; ++j) {
					this._defaultValue.forEach(function(chunk){
						this.push(chunk);
					}, this);
				}
			}
		}
	}
	for(j = n && i < n ? i + 1 : i; j < sl; ++j){
		value = s[j];
		switch(typeof value){
			case "string":
				this.push({name: "startObject"});
				this.push({name: "startKey"});
				this.push({name: "stringChunk", value: value});
				this.push({name: "endKey"});
				this.push({name: "keyValue", value: value});
				break;
			case "number":
				this.push({name: "startArray"});
				if(this._defaultValue.length){
					for(k = 0; k < value; ++k){
						this._defaultValue.forEach(function(chunk){
							this.push(chunk);
						}, this);
					}
				}
				break;
		}
	}
	this._previous = s.slice(0);
};

Filter.prototype._pattern = function pattern(stack){
	var path = stack.filter(function(value){ return typeof value != "boolean"; }).join(this._separator);
	return this._regexp.test(path);
};

Filter.prototype._allowAll = function allowAll(){
	return true;
};


module.exports = Filter;

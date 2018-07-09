"use strict";


function Assembler(){
	this.stack = [];
	this.current = this.key = null;
}

Assembler.prototype = {
	startArray:  startObject(Array),
	endArray:    endObject,

	startObject: startObject(Object),
	endObject:   endObject,

	keyValue:    function keyValue(value){ this.key = value; },

	//stringValue: stringValue, // aliased below as _saveValue
	numberValue: function(value){ this._saveValue(parseFloat(value)); },
	nullValue:   function(){ this._saveValue(null); },
	trueValue:   function(){ this._saveValue(true); },
	falseValue:  function(){ this._saveValue(false); },

	_saveValue: function(value){
		if(this.current){
			if(this.current instanceof Array){
				this.current.push(value);
			}else{
				this.current[this.key] = value;
				this.key = null;
			}
		}else{
			this.current = value;
		}
	}
};
Assembler.prototype.stringValue = Assembler.prototype._saveValue;

function startObject(Ctr){
	return function(){
		if(this.current){
			this.stack.push(this.current, this.key);
		}
		this.current = new Ctr();
		this.key = null;
	}
}

function endObject(){
	if(this.stack.length){
		var value = this.current;
		this.key = this.stack.pop();
		this.current = this.stack.pop();
		this._saveValue(value);
	}
}

module.exports = Assembler;

"use strict";


function Counter(){
	this.objects = 0;
	this.keys    = 0;
	this.arrays  = 0;
	this.nulls   = 0;
	this.trues   = 0;
	this.falses  = 0;
	this.numbers = 0;
	this.strings = 0;
}

Counter.walk = function walk(o, counter){
	switch(typeof o){
		case "string":
			++counter.strings;
			return;
		case "number":
			++counter.numbers;
			return;
		case "boolean":
			if(o){
				++counter.trues;
			}else{
				++counter.falses;
			}
			return;
	}
	if(o === null){
		++counter.nulls;
		return;
	}
	if(o instanceof Array){
		++counter.arrays;
		o.forEach(function(o){ walk(o, counter); });
		return;
	}
	++counter.objects;
	for(var key in o){
		if(o.hasOwnProperty(key)){
			++counter.keys;
			walk(o[key], counter);
		}
	}
};

module.exports = Counter;

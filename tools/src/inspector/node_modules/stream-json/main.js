"use strict";


var Combo  = require("./Combo");
var Source = require("./Source");


function makeSource(options){
	if(!options || !("packKeys" in options || "packStrings" in options || "packNumbers" in options)){
		options = options ? Object.create(options) : {};
		options.packKeys = options.packStrings = options.packNumbers = true;
	}
	return new Source([new Combo(options)]);
}


module.exports = makeSource;

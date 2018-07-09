var ReadString = require("../ReadString");
var Parser = require("../../Parser");
var Streamer = require("../../Streamer");
var Packer = require("../../Packer");
var StreamPrinter = require("./StreamPrinter");

var Source   = require("../../Source");


var object = {
			stringWithTabsAndNewlines: "Did it work?\nNo...\t\tI don't think so...",
			anArray: [1, 2, true, "tabs?\t\t\t\u0001\u0002\u0003", false]
		};
var input = JSON.stringify(object);


var stream   = new ReadString(input);
var parser   = new Parser();
var streamer = new Streamer();
var packer   = new Packer({packKeys: true, packStrings: true, packNumbers: true});
var printer  = new StreamPrinter();

var source = new Source([parser, streamer, packer/*, printer*/]);


// reconstruct an object

var current, key, stack = [];

function startObject(newValue){
	if(current !== undefined){
		stack.push(current, key);
		key = undefined;
	}
	current = newValue;
	console.log("new object: ", JSON.stringify(current));
	console.log("stack: ", JSON.stringify(stack));
}

function endObject(){
	if(stack.length){
		var value = current;
		key = stack.pop();
		current = stack.pop();
		addValue(value);
	}
	console.log("old object: ", JSON.stringify(current));
	console.log("stack: ", JSON.stringify(stack));
}

function addValue(value){
	if(current instanceof Array){
		current.push(value);
	}else{
		current[key] = value;
		key = undefined;
	}
	console.log("updated object: ", JSON.stringify(current));
}

source.on("startObject", function(){ startObject({}); });
source.on("startArray",  function(){ startObject([]); });

source.on("endObject", endObject);
source.on("endArray",  endObject);

source.on("keyValue",    function(value){ key = value; });
source.on("stringValue", addValue);
source.on("numberValue", function(value){ addValue(+value); });
source.on("nullValue",   function(){ addValue(null); });
source.on("trueValue",   function(){ addValue(true); });
source.on("falseValue",  function(){ addValue(false); });

source.on("end", function(){
	console.log("in:  ", input);
	console.log("out: ", JSON.stringify(current));
});


console.log(input);
stream.pipe(source.input);

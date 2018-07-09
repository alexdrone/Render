var Source   = require("../../Source");
var Parser   = require("../../Parser");
var Streamer = require("../../Streamer");

var fs = require("fs"), path = require("path"), zlib = require("zlib");


var source = new Source([new Parser(), new Streamer()]);

var objectCounter = 0, arrayCounter = 0, stringCounter = 0, numberCounter = 0,
	nullCounter = 0, trueCounter = 0, falseCounter = 0, keyCounter = 0;

source.on("startObject", function(){ ++objectCounter; });
source.on("startArray",  function(){ ++arrayCounter; });
source.on("startKey",    function(){ ++keyCounter; });
source.on("startString", function(){ ++stringCounter; });
source.on("startNumber", function(){ ++numberCounter; });
source.on("nullValue",   function(){ ++nullCounter; });
source.on("trueValue",   function(){ ++trueCounter; });
source.on("falseValue",  function(){ ++falseCounter; });

source.on("end", function(){
	console.log("objects:", objectCounter);
	console.log("arrays:",  arrayCounter);
	console.log("keys:",    keyCounter);
	console.log("strings:", stringCounter);
	console.log("numbers:", numberCounter);
	console.log("nulls:",   nullCounter);
	console.log("trues:",   trueCounter);
	console.log("falses:",  falseCounter);
});

fs.createReadStream(path.resolve(__dirname, "../sample.json.gz")).
	pipe(zlib.createGunzip()).pipe(source.input);

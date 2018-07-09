var makeSource = require("../../main");

var fs = require("fs"), path = require("path"), zlib = require("zlib");


var source = makeSource();

var objectCounter = 0, arrayCounter = 0, stringCounter = 0, numberCounter = 0,
	nullCounter = 0, trueCounter = 0, falseCounter = 0, keyCounter = 0;

source.on("startObject", function(){ ++objectCounter; });
source.on("startArray",  function(){ ++arrayCounter; });
source.on("keyValue",    function(){ ++keyCounter; });
source.on("stringValue", function(){ ++stringCounter; });
source.on("numberValue", function(){ ++numberCounter; });
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

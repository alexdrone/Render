var fs = require("fs"), path = require("path"), zlib = require("zlib");


var objectCounter = 0, arrayCounter = 0, stringCounter = 0, numberCounter = 0,
	nullCounter = 0, trueCounter = 0, falseCounter = 0, keyCounter = 0;

fs.readFile(path.resolve(__dirname, "../sample.json.gz"), function(err, data){
	if(err){
		throw err;
	}
	zlib.gunzip(data, function(err, data){
		if(err){
			throw err;
		}

		var o = JSON.parse(data);

		walk(o);

		console.log("objects:", objectCounter);
		console.log("arrays:",  arrayCounter);
		console.log("keys:",    keyCounter);
		console.log("strings:", stringCounter);
		console.log("numbers:", numberCounter);
		console.log("nulls:",   nullCounter);
		console.log("trues:",   trueCounter);
		console.log("falses:",  falseCounter);
	});
});

function walk(o){
	switch(typeof o){
		case "string":
			++stringCounter;
			return;
		case "number":
			++numberCounter;
			return;
		case "boolean":
			if(o){
				++trueCounter;
			}else{
				++falseCounter;
			}
			return;
	}
	if(o === null){
		++nullCounter;
		return;
	}
	if(o instanceof Array){
		++arrayCounter;
		o.forEach(walk);
		return;
	}
	++objectCounter;
	for(var key in o){
		if(o.hasOwnProperty(key)){
			++keyCounter;
			walk(o[key]);
		}
	}
}

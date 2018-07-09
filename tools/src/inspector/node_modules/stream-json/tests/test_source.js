"use strict";


var unit = require("heya-unit");

var fs = require("fs"), path = require("path"), zlib = require("zlib");

var makeSource = require("../main");
var Counter    = require("./Counter");


unit.add(module, [
	function test_source(t){
		var async = t.startAsync("test_source");

		var plainCounter  = new Counter(),
			streamCounter = new Counter(),
			source = makeSource();

		source.on("startObject", function(){ ++streamCounter.objects; });
		source.on("keyValue",    function(){ ++streamCounter.keys; });
		source.on("startArray",  function(){ ++streamCounter.arrays; });
		source.on("nullValue",   function(){ ++streamCounter.nulls; });
		source.on("trueValue",   function(){ ++streamCounter.trues; });
		source.on("falseValue",  function(){ ++streamCounter.falses; });
		source.on("numberValue", function(){ ++streamCounter.numbers; });
		source.on("stringValue", function(){ ++streamCounter.strings; });

		source.on("end", function(){
			eval(t.TEST("t.unify(plainCounter, streamCounter)"));
			async.done();
		});

		fs.readFile(path.resolve(__dirname, "./sample.json.gz"), function(err, data){
			if(err){ throw err; }
			zlib.gunzip(data, function(err, data){
				if(err){ throw err; }

				var o = JSON.parse(data);
				Counter.walk(o, plainCounter);

				fs.createReadStream(path.resolve(__dirname, "./sample.json.gz")).
					pipe(zlib.createGunzip()).pipe(source.input);
			});
		});
	}
]);

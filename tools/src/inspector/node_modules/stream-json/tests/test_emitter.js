"use strict";


var unit = require("heya-unit");

var fs = require("fs"), path = require("path"), zlib = require("zlib");

var Parser   = require("../Parser");
var Streamer = require("../Streamer");
var Packer   = require("../Packer");
var Emitter  = require("../Emitter");
var Counter  = require("./Counter");


unit.add(module, [
	function test_emitter(t){
		var async = t.startAsync("test_emitter");

		var plainCounter   = new Counter(),
			emitterCounter = new Counter(),
			parser   = new Parser(),
			streamer = new Streamer(),
			packer   = new Packer({packKeys: true, packStrings: true, packNumbers: true}),
			emitter  = new Emitter();

		parser.pipe(streamer).pipe(packer).pipe(emitter);

		emitter.on("startObject", function(){ ++emitterCounter.objects; });
		emitter.on("keyValue",    function(){ ++emitterCounter.keys; });
		emitter.on("startArray",  function(){ ++emitterCounter.arrays; });
		emitter.on("nullValue",   function(){ ++emitterCounter.nulls; });
		emitter.on("trueValue",   function(){ ++emitterCounter.trues; });
		emitter.on("falseValue",  function(){ ++emitterCounter.falses; });
		emitter.on("numberValue", function(){ ++emitterCounter.numbers; });
		emitter.on("stringValue", function(){ ++emitterCounter.strings; });

		emitter.on("finish", function(){
			eval(t.TEST("t.unify(plainCounter, emitterCounter)"));
			async.done();
		});

		fs.readFile(path.resolve(__dirname, "./sample.json.gz"), function(err, data){
			if(err){ throw err; }
			zlib.gunzip(data, function(err, data){
				if(err){ throw err; }

				var o = JSON.parse(data);
				Counter.walk(o, plainCounter);

				fs.createReadStream(path.resolve(__dirname, "./sample.json.gz")).
					pipe(zlib.createGunzip()).pipe(parser);
			});
		});
	}
]);

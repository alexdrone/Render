"use strict";


var unit = require("heya-unit");

var fs = require("fs"), path = require("path"), zlib = require("zlib");

var makeSource = require("../main");
var Assembler  = require("../utils/Assembler");


unit.add(module, [
	function test_escaped(t){
		var async = t.startAsync("test_escaped");

		var source = makeSource(),
			assembler = new Assembler(),
			object = null;

		source.output.on("data", function(chunk){
			assembler[chunk.name] && assembler[chunk.name](chunk.value);
		});
		source.output.on("end", function(){
			eval(t.TEST("t.unify(assembler.current, object)"));
			async.done();
		});


		fs.readFile(path.resolve(__dirname, "./sample.json.gz"), function(err, data){
			if(err){ throw err; }
			zlib.gunzip(data, function(err, data){
				if(err){ throw err; }

				object = JSON.parse(data.toString());

				fs.createReadStream(path.resolve(__dirname, "./sample.json.gz")).
					pipe(zlib.createGunzip()).pipe(source.input);
			});
		});
	}
]);

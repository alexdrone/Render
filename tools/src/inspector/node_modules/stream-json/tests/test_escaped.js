"use strict";


var unit = require("heya-unit");

var Assembler = require("../utils/Assembler");

var Parser   = require("../Parser");
var Streamer = require("../Streamer");
var Packer   = require("../Packer");

var ReadString = require("./ReadString");


unit.add(module, [
	function test_escaped(t){
		var async = t.startAsync("test_escaped");

		var object = {
				stringWithTabsAndNewlines: "Did it work?\nNo...\t\tI don't think so...",
				anArray: [1, 2, true, "tabs?\t\t\t\u0001\u0002\u0003", false]
			},
			input = JSON.stringify(object),
			pipeline = new ReadString(input).pipe(new Parser()).pipe(new Streamer()).
				pipe(new Packer({packKeys: true, packStrings: true, packNumbers: true})),
			assembler = new Assembler();

		pipeline.on("data", function(chunk){
			assembler[chunk.name] && assembler[chunk.name](chunk.value);
		});
		pipeline.on("end", function(){
			eval(t.TEST("t.unify(assembler.current, object)"));
			async.done();
		});
	}
]);

"use strict";


var unit = require("heya-unit");

var ReadString  = require("./ReadString");
var StreamJsonObjects = require("../utils/StreamJsonObjects");


unit.add(module, [
	function test_json_objects(t){
		var async = t.startAsync("test_json_objects");

		var stream  = StreamJsonObjects.make(),
			pattern = [
				1, 2, 3,
				true, false,
				"", "Abc",
				[], [1], [1, []],
				{}, {a: 1}, {b: {}, c: [{}]}
			],
			result = [];

		stream.output.on("data", function(data){
			result[data.index] = data.value;
		});
		stream.output.on("end", function(){
			eval(t.TEST("t.unify(pattern, result)"));
			async.done();
		});

		new ReadString(pattern.map(function (value) {
			return JSON.stringify(value);
		}).join(" ")).pipe(stream.input);
	},
	function test_no_json_objects (t) {
		var async = t.startAsync("test_no_json_objects");

		var stream  = StreamJsonObjects.make(),
			result  = [];

		stream.output.on("data", function(data){
			result[data.index] = data.value;
		});
		stream.output.on("end", function(){
			eval(t.TEST("!result.length"));
			async.done();
		});

		new ReadString("").pipe(stream.input);
	}
]);

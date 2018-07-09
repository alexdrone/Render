"use strict";


var unit = require("heya-unit");

var ReadString  = require("./ReadString");
var StreamArray = require("../utils/StreamArray");


unit.add(module, [
	function test_array_fail(t){
		var async = t.startAsync("test_array_fail");

		var stream = StreamArray.make();

		stream.output.on("data", function(value){
			eval(t.TEST("!'We shouldn\'t be here.'"));
		});
		stream.output.on("error", function(err){
			eval(t.TEST("err"));
			async.done();
		});
		stream.output.on("end", function(value){
			eval(t.TEST("!'We shouldn\'t be here.'"));
			async.done();
		});

		new ReadString(" true ").pipe(stream.input);
	},
	function test_array(t){
		var async = t.startAsync("test_array");

		var stream  = StreamArray.make(),
			pattern = [0, 1, true, false, null, {}, [], {a: "b"}, ["c"]],
			result  = [];

		stream.output.on("data", function(object){
			result[object.index] = object.value;
		});
		stream.output.on("end", function(){
			eval(t.TEST("t.unify(pattern, result)"));
			async.done();
		});

		new ReadString(JSON.stringify(pattern)).pipe(stream.input);
	}
]);

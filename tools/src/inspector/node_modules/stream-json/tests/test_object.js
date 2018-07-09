"use strict";


var unit = require("heya-unit");

var ReadString  = require("./ReadString");
var StreamObject = require("../utils/StreamObject");


unit.add(module, [
	function test_object_fail(t){
		var async = t.startAsync("test_object_fail");

		var stream = StreamObject.make();

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
	function test_object(t){
		var async = t.startAsync("test_object");

		var stream  = StreamObject.make(),
			pattern = {
				str: "bar",
				baz: null,
				t: true,
				f: false,
				zero: 0,
				one: 1,
				obj: {},
				arr: [],
				deepObj: {a: "b"},
				deepArr: ["c"],
				"": "" // tricky, yet legal
			},
			result = {};

		stream.output.on("data", function(data){
			result[data.key] = data.value;
		});
		stream.output.on("end", function(){
			eval(t.TEST("t.unify(pattern, result)"));
			async.done();
		});

		new ReadString(JSON.stringify(pattern)).pipe(stream.input);
	}
]);

"use strict";


var unit = require("heya-unit");

var ReadString = require("./ReadString");
var StreamFilteredArray = require("../utils/StreamFilteredArray");


unit.add(module, [
	function test_filtered_array_fail(t){
		var async = t.startAsync("test_filtered_array_fail");

		var stream = StreamFilteredArray.make();

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
	function test_filtered_array(t){
		var async = t.startAsync("test_filtered_array");

		var stream  = StreamFilteredArray.make(),
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
	},
	function test_filtered_array_default(t){
		var async = t.startAsync("test_filtered_array_default");

		var stream = StreamFilteredArray.make(),
			input  = [
				0, 1, true, false, null, {}, [],
				{a: "reject", b: [[[]]]}, ["c"],
				{a: "accept"},
				{a: "neutral"},
				{x: true, a: "reject"},
				{y: null, a: "accept"},
				{z: 1234, a: "neutral"},
				{w: "12", a: "neutral"}
			],
			result  = [];

		stream.output.on("data", function(object){
			result.push(object.value);
		});
		stream.output.on("end", function(){
			eval(t.TEST("t.unify(input, result)"));
			async.done();
		});

		new ReadString(JSON.stringify(input)).pipe(stream.input);
	},
	function test_filtered_array_filter(t){
		var async = t.startAsync("test_filtered_array_filter");

		function f(assembler){
			if(assembler.stack.length == 2 && assembler.key === null && assembler.current){
				if(assembler.current instanceof Array){
					return false;
				}
				switch(assembler.current.a){
					case "accept": return true;
					case "reject": return false;
				}
			}
		}

		var stream = StreamFilteredArray.make({objectFilter: f}),
			input  = [
				0, 1, true, false, null, {}, [],
				{a: "reject", b: [[[]]]}, ["c"],
				{a: "accept"},
				{a: "neutral"},
				{x: true, a: "reject"},
				{y: null, a: "accept"},
				{z: 1234, a: "neutral"},
				{w: "12", a: "neutral"}
			],
			result  = [];

		stream.output.on("data", function(object){
			result.push(object.value);
		});
		stream.output.on("end", function(){
			result.forEach(function(o){
				if(typeof o == "object" && o){
					eval(t.TEST("!(o instanceof Array)"));
					eval(t.TEST("o.a !== 'reject'"));
				}else{
					eval(t.TEST("o === null || typeof o != 'object'"));
				}
			});
			async.done();
		});

		new ReadString(JSON.stringify(input)).pipe(stream.input);
	}
]);

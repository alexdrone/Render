"use strict";


var unit = require("heya-unit");

var ReadString  = require("./ReadString");
var StreamArray = require("../utils/StreamArray");
var FilterObjects = require("../utils/FilterObjects");


unit.add(module, [
	function test_filter_objects_default(t){
		var async = t.startAsync("test_filter_objects_default");

		var stream = StreamArray.make(),
			filter = new FilterObjects(),
			input  = [0, 1, true, false, null, {}, [], {a: "b"}, ["c"]],
			result = [];

		stream.output.pipe(filter);

		filter.on("data", function(object){
			result[object.index] = object.value;
		});
		filter.on("end", function(){
			eval(t.TEST("t.unify(input, result)"));
			async.done();
		});

		new ReadString(JSON.stringify(input)).pipe(stream.input);
	},
	function test_filtered_array_filter(t){
		var async = t.startAsync("test_filtered_array_filter");

		function f(item){
			if(typeof item.value != "object")	return false;	// reject primitives
			if(!item.value)						return false;	// reject nulls
			if(item.value instanceof Array)		return false;	// reject arrays
			return item.value.a !== "reject";
		}

		var stream = StreamArray.make(),
			filter = new FilterObjects({itemFilter: f}),
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

		stream.output.pipe(filter);

		filter.on("data", function(object){
			result.push(object.value);
		});
		filter.on("end", function(){
			result.forEach(function(o){
				eval(t.TEST("typeof o == 'object' && o"));
				eval(t.TEST("!(o instanceof Array)"));
				eval(t.TEST("o.a !== 'reject'"));
			});
			async.done();
		});

		new ReadString(JSON.stringify(input)).pipe(stream.input);
	}
]);

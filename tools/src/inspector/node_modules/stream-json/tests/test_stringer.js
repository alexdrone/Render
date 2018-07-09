"use strict";


var unit = require("heya-unit");

var ReadString = require("./ReadString");
var makeSource = require("../main");
var Stringer   = require("../utils/Stringer");


unit.add(module, [
	function test_stringer (t) {
		var async = t.startAsync("test_stringer");

		var source   = makeSource(),
			stringer = new Stringer(),
			pattern  = {
				a: [[[]]],
				b: {a: 1},
				c: {a: 1, b: 2},
				d: [true, 1, "'x\"y'", null, false, true, {}, [], ""],
				e: 1,
				f: "",
				g: true,
				h: false,
				i: null,
				j: [],
				k: {}
			},
			string = JSON.stringify(pattern),
			buffer = '';

		source.output.pipe(stringer);

		stringer.on("data", function(data) {
			buffer += data;
		});
		stringer.on("end", function() {
			eval(t.TEST('string === buffer'));
			async.done();
		});

		new ReadString(string).pipe(source.input);
	},
	function test_stringer_json_stream (t) {
		var async = t.startAsync("test_stringer_json_stream");

		var source   = makeSource({jsonStreaming: true}),
			stringer = new Stringer(),
			pattern  = {
				a: [[[]]],
				b: {a: 1},
				c: {a: 1, b: 2},
				d: [true, 1, "'x\"y'", null, false, true, {}, [], ""],
				e: 1,
				f: "",
				g: true,
				h: false,
				i: null,
				j: [],
				k: {}
			},
			string = JSON.stringify(pattern),
			buffer = '';
		string += string;

		source.output.pipe(stringer);

		stringer.on("data", function(data) {
			buffer += data;
		});
		stringer.on("end", function() {
			eval(t.TEST('string === buffer'));
			async.done();
		});

		new ReadString(string).pipe(source.input);
	}
]);

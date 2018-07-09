"use strict";


var unit = require("heya-unit");

var Assembler = require("../utils/Assembler");

var Parser   = require("../Parser");
var Streamer = require("../Streamer");
var Packer   = require("../Packer");

var ReadString = require("./ReadString");


function survivesRoundtrip(t, object){
	var async = t.startAsync("survivesRoundtrip: " + object);

	var input = JSON.stringify(object),
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

unit.add(module, [
	function test_primitives_true(t){
		survivesRoundtrip(t, true);
	},
	function test_primitives_false(t){
		survivesRoundtrip(t, false);
	},
	function test_primitives_null(t){
		survivesRoundtrip(t, null);
	},
	function test_primitives_number1(t){
		survivesRoundtrip(t, 0);
	},
	function test_primitives_number2(t){
		survivesRoundtrip(t, -1);
	},
	function test_primitives_number3(t){
		survivesRoundtrip(t, 1.5);
	},
	function test_primitives_number4(t){
		survivesRoundtrip(t, 1.5e-12);
	},
	function test_primitives_number5(t){
		survivesRoundtrip(t, 1.5e+33);
	},
	function test_primitives_string(t){
		survivesRoundtrip(t, "string");
	},
	function test_primitives_empty_object(t){
		survivesRoundtrip(t, {});
	},
	function test_primitives_empty_array(t){
		survivesRoundtrip(t, []);
	}
]);

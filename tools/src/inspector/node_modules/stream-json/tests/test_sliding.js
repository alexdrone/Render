"use strict";


var unit = require("heya-unit");

var Assembler = require("../utils/Assembler");

var Parser   = require("../Parser");
var Streamer = require("../Streamer");
var Packer   = require("../Packer");

var ReadString = require("./ReadString");


function runSlidingWindowTest(t, quant){
	var async = t.startAsync("test_sliding: " + quant);

	var object = {
			stringWithTabsAndNewlines: "Did it work?\nNo...\t\tI don't think so...",
			anArray: [1, 2, true, "tabs?\t\t\t\u0001\u0002\u0003", false]
		},
		input = JSON.stringify(object),
		pipeline = new ReadString(input, quant).pipe(new Parser()).pipe(new Streamer()).
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
	function test_sliding_1(t){
		runSlidingWindowTest(t, 1);
	},
	function test_sliding_2(t){
		runSlidingWindowTest(t, 2);
	},
	function test_sliding_3(t){
		runSlidingWindowTest(t, 3);
	},
	function test_sliding_4(t){
		runSlidingWindowTest(t, 4);
	},
	function test_sliding_5(t){
		runSlidingWindowTest(t, 5);
	},
	function test_sliding_6(t){
		runSlidingWindowTest(t, 6);
	},
	function test_sliding_7(t){
		runSlidingWindowTest(t, 7);
	},
	function test_sliding_8(t){
		runSlidingWindowTest(t, 8);
	},
	function test_sliding_9(t){
		runSlidingWindowTest(t, 9);
	},
	function test_sliding_10(t){
		runSlidingWindowTest(t, 10);
	},
	function test_sliding_11(t){
		runSlidingWindowTest(t, 11);
	},
	function test_sliding_12(t){
		runSlidingWindowTest(t, 12);
	}
]);

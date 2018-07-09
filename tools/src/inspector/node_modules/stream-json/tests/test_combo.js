"use strict";


var unit = require("heya-unit");

var fs = require("fs"), path = require("path"), zlib = require("zlib");

var Combo   = require("../Combo");
var Emitter = require("../Emitter");
var Filter  = require("../Filter");

var Assembler  = require("../utils/Assembler");

var ReadString = require("./ReadString");
var Counter    = require("./Counter");


function survivesRoundtrip(t, object){
	var async = t.startAsync("survivesRoundtrip: " + object);

	var input = JSON.stringify(object),
		pipeline = new ReadString(input).
			pipe(new Combo({packKeys: true, packStrings: true, packNumbers: true})),
		assembler = new Assembler();

	pipeline.on("data", function(chunk){
		assembler[chunk.name] && assembler[chunk.name](chunk.value);
	});
	pipeline.on("end", function(){
		eval(t.TEST("t.unify(assembler.current, object)"));
		async.done();
	});
}


function runSlidingWindowTest(t, quant){
	var async = t.startAsync("test_sliding: " + quant);

	var object = {
			stringWithTabsAndNewlines: "Did it work?\nNo...\t\tI don't think so...",
			anArray: [1, 2, true, "tabs?\t\t\t\u0001\u0002\u0003", false]
		},
		input = JSON.stringify(object),
		pipeline = new ReadString(input, quant).
			pipe(new Combo({packKeys: true, packStrings: true, packNumbers: true})),
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
	function test_combo_streamer(t){
		var async = t.startAsync("test_streamer");

		var input = '{"a": 1, "b": true, "c": ["d"]}',
			pipeline = new ReadString(input).pipe(new Combo()),
			result = [];

		pipeline.on("data", function(chunk){
			result.push({name: chunk.name, val: chunk.value});
		});
		pipeline.on("end", function(){
			eval(t.ASSERT("result.length === 20"));
			eval(t.TEST("result[0].name === 'startObject'"));
			eval(t.TEST("result[1].name === 'startKey'"));
			eval(t.TEST("result[2].name === 'stringChunk' && result[2].val === 'a'"));
			eval(t.TEST("result[3].name === 'endKey'"));
			eval(t.TEST("result[4].name === 'startNumber'"));
			eval(t.TEST("result[5].name === 'numberChunk' && result[5].val === '1'"));
			eval(t.TEST("result[6].name === 'endNumber'"));
			eval(t.TEST("result[7].name === 'startKey'"));
			eval(t.TEST("result[8].name === 'stringChunk' && result[8].val === 'b'"));
			eval(t.TEST("result[9].name === 'endKey'"));
			eval(t.TEST("result[10].name === 'trueValue' && result[10].val === true"));
			eval(t.TEST("result[11].name === 'startKey'"));
			eval(t.TEST("result[12].name === 'stringChunk' && result[12].val === 'c'"));
			eval(t.TEST("result[13].name === 'endKey'"));
			eval(t.TEST("result[14].name === 'startArray'"));
			eval(t.TEST("result[15].name === 'startString'"));
			eval(t.TEST("result[16].name === 'stringChunk' && result[16].val === 'd'"));
			eval(t.TEST("result[17].name === 'endString'"));
			eval(t.TEST("result[18].name === 'endArray'"));
			eval(t.TEST("result[19].name === 'endObject'"));
			async.done();
		});
	},
	function test_combo_packer(t){
		var async = t.startAsync("test_packer");

		var input = '{"a": 1, "b": true, "c": ["d"]}',
			pipeline = new ReadString(input).
				pipe(new Combo({packKeys: true, packStrings: true, packNumbers: true})),
			result = [];

		pipeline.on("data", function(chunk){
			result.push({name: chunk.name, val: chunk.value});
		});
		pipeline.on("end", function(){
			eval(t.ASSERT("result.length === 25"));
			eval(t.TEST("result[0].name === 'startObject'"));
			eval(t.TEST("result[1].name === 'startKey'"));
			eval(t.TEST("result[2].name === 'stringChunk' && result[2].val === 'a'"));
			eval(t.TEST("result[3].name === 'endKey'"));
			eval(t.TEST("result[4].name === 'keyValue' && result[4].val === 'a'"));
			eval(t.TEST("result[5].name === 'startNumber'"));
			eval(t.TEST("result[6].name === 'numberChunk' && result[6].val === '1'"));
			eval(t.TEST("result[7].name === 'endNumber'"));
			eval(t.TEST("result[8].name === 'numberValue' && result[8].val === '1'"));
			eval(t.TEST("result[9].name === 'startKey'"));
			eval(t.TEST("result[10].name === 'stringChunk' && result[10].val === 'b'"));
			eval(t.TEST("result[11].name === 'endKey'"));
			eval(t.TEST("result[12].name === 'keyValue' && result[12].val === 'b'"));
			eval(t.TEST("result[13].name === 'trueValue' && result[13].val === true"));
			eval(t.TEST("result[14].name === 'startKey'"));
			eval(t.TEST("result[15].name === 'stringChunk' && result[15].val === 'c'"));
			eval(t.TEST("result[16].name === 'endKey'"));
			eval(t.TEST("result[17].name === 'keyValue' && result[17].val === 'c'"));
			eval(t.TEST("result[18].name === 'startArray'"));
			eval(t.TEST("result[19].name === 'startString'"));
			eval(t.TEST("result[20].name === 'stringChunk' && result[20].val === 'd'"));
			eval(t.TEST("result[21].name === 'endString'"));
			eval(t.TEST("result[22].name === 'stringValue' && result[22].val === 'd'"));
			eval(t.TEST("result[23].name === 'endArray'"));
			eval(t.TEST("result[24].name === 'endObject'"));
			async.done();
		});
	},
	function test_combo_emitter(t){
		var async = t.startAsync("test_emitter");

		var plainCounter   = new Counter(),
			emitterCounter = new Counter(),
			combo    = new Combo({packKeys: true, packStrings: true, packNumbers: true}),
			emitter  = new Emitter();

		combo.pipe(emitter);

		emitter.on("startObject", function(){ ++emitterCounter.objects; });
		emitter.on("keyValue",    function(){ ++emitterCounter.keys; });
		emitter.on("startArray",  function(){ ++emitterCounter.arrays; });
		emitter.on("nullValue",   function(){ ++emitterCounter.nulls; });
		emitter.on("trueValue",   function(){ ++emitterCounter.trues; });
		emitter.on("falseValue",  function(){ ++emitterCounter.falses; });
		emitter.on("numberValue", function(){ ++emitterCounter.numbers; });
		emitter.on("stringValue", function(){ ++emitterCounter.strings; });

		emitter.on("finish", function(){
			eval(t.TEST("t.unify(plainCounter, emitterCounter)"));
			async.done();
		});

		fs.readFile(path.resolve(__dirname, "./sample.json.gz"), function(err, data){
			if(err){ throw err; }
			zlib.gunzip(data, function(err, data){
				if(err){ throw err; }

				var o = JSON.parse(data);
				Counter.walk(o, plainCounter);

				fs.createReadStream(path.resolve(__dirname, "./sample.json.gz")).
					pipe(zlib.createGunzip()).pipe(combo);
			});
		});
	},
	function test_combo_escaped(t){
		var async = t.startAsync("test_escaped");

		var object = {
				stringWithTabsAndNewlines: "Did it work?\nNo...\t\tI don't think so...",
				anArray: [1, 2, true, "tabs?\t\t\t\u0001\u0002\u0003", false]
			},
			input = JSON.stringify(object),
			pipeline = new ReadString(input).
				pipe(new Combo({packKeys: true, packStrings: true, packNumbers: true})),
			assembler = new Assembler();

		pipeline.on("data", function(chunk){
			assembler[chunk.name] && assembler[chunk.name](chunk.value);
		});
		pipeline.on("end", function(){
			eval(t.TEST("t.unify(assembler.current, object)"));
			async.done();
		});
	},
	function test_combo_filter(t){
		var async = t.startAsync("test_filter");

		var input = '{"a": 1, "b": true, "c": ["d"]}',
			pipeline = new ReadString(input).pipe(new Combo()).
				pipe(new Filter({filter: /^(|a|c)$/})),
			result = [];

		pipeline.on("data", function(chunk){
			result.push({name: chunk.name, val: chunk.value});
		});
		pipeline.on("end", function(){
			eval(t.ASSERT("result.length === 15"));
			eval(t.TEST("result[0].name === 'startObject'"));
			eval(t.TEST("result[1].name === 'startKey'"));
			eval(t.TEST("result[2].name === 'stringChunk' && result[2].val === 'a'"));
			eval(t.TEST("result[3].name === 'endKey'"));
			eval(t.TEST("result[4].name === 'keyValue' && result[4].val === 'a'"));
			eval(t.TEST("result[5].name === 'startNumber'"));
			eval(t.TEST("result[6].name === 'numberChunk' && result[6].val === '1'"));
			eval(t.TEST("result[7].name === 'endNumber'"));
			eval(t.TEST("result[8].name === 'startKey'"));
			eval(t.TEST("result[9].name === 'stringChunk' && result[9].val === 'c'"));
			eval(t.TEST("result[10].name === 'endKey'"));
			eval(t.TEST("result[11].name === 'keyValue' && result[11].val === 'c'"));
			eval(t.TEST("result[12].name === 'startArray'"));
			eval(t.TEST("result[13].name === 'endArray'"));
			eval(t.TEST("result[14].name === 'endObject'"));
			async.done();
		});
	},
	function test_combo_primitives_true(t){
		survivesRoundtrip(t, true);
	},
	function test_combo_primitives_false(t){
		survivesRoundtrip(t, false);
	},
	function test_combo_primitives_null(t){
		survivesRoundtrip(t, null);
	},
	function test_combo_primitives_number1(t){
		survivesRoundtrip(t, 0);
	},
	function test_combo_primitives_number2(t){
		survivesRoundtrip(t, -1);
	},
	function test_combo_primitives_number3(t){
		survivesRoundtrip(t, 1.5);
	},
	function test_combo_primitives_number4(t){
		survivesRoundtrip(t, 1.5e-12);
	},
	function test_combo_primitives_number5(t){
		survivesRoundtrip(t, 1.5e+33);
	},
	function test_combo_primitives_string(t){
		survivesRoundtrip(t, "string");
	},
	function test_combo_primitives_empty_object(t){
		survivesRoundtrip(t, {});
	},
	function test_combo_primitives_empty_array(t){
		survivesRoundtrip(t, []);
	},
	function test_combo_sliding_1(t){
		runSlidingWindowTest(t, 1);
	},
	function test_combo_sliding_2(t){
		runSlidingWindowTest(t, 2);
	},
	function test_combo_sliding_3(t){
		runSlidingWindowTest(t, 3);
	},
	function test_combo_sliding_4(t){
		runSlidingWindowTest(t, 4);
	},
	function test_combo_sliding_5(t){
		runSlidingWindowTest(t, 5);
	},
	function test_combo_sliding_6(t){
		runSlidingWindowTest(t, 6);
	},
	function test_combo_sliding_7(t){
		runSlidingWindowTest(t, 7);
	},
	function test_combo_sliding_8(t){
		runSlidingWindowTest(t, 8);
	},
	function test_combo_sliding_9(t){
		runSlidingWindowTest(t, 9);
	},
	function test_combo_sliding_10(t){
		runSlidingWindowTest(t, 10);
	},
	function test_combo_sliding_11(t){
		runSlidingWindowTest(t, 11);
	},
	function test_combo_sliding_12(t){
		runSlidingWindowTest(t, 12);
	},
	function test_combo_fail (t) {
		var async = t.startAsync("test_combo_fail");

		var stream = new Combo({packKeys: true, packStrings: true, packNumbers: true});

		stream.on("error", function (err) {
			eval(t.TEST("err"));
			async.done();
		});
		stream.on("end", function (value) {
			eval(t.TEST("!'We shouldn\'t be here.'"));
			async.done();
		});

		new ReadString("{").pipe(stream);
	}
]);

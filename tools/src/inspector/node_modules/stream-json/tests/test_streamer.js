"use strict";


var unit = require("heya-unit");

var ReadString = require("./ReadString");
var Parser = require("../Parser");
var Streamer = require("../Streamer");


unit.add(module, [
	function test_streamer(t){
		var async = t.startAsync("test_streamer");

		var input = '{"a": 1, "b": true, "c": ["d"]}',
			pipeline = new ReadString(input).pipe(new Parser()).pipe(new Streamer()),
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
	}
]);

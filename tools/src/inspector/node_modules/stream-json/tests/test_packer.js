"use strict";


var unit = require("heya-unit");

var ReadString = require("./ReadString");
var Parser = require("../Parser");
var Streamer = require("../Streamer");
var Packer = require("../Packer");


unit.add(module, [
	function test_packer(t){
		var async = t.startAsync("test_packer");

		var input = '{"a": 1, "b": true, "c": ["d"]}',
			pipeline = new ReadString(input).pipe(new Parser()).pipe(new Streamer()).
				pipe(new Packer({packKeys: true, packStrings: true, packNumbers: true})),
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
	}
]);

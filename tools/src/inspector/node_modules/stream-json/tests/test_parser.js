"use strict";


var unit = require("heya-unit");

var ReadString = require("./ReadString");
var Parser = require("../Parser");


unit.add(module, [
	function test_parser (t) {
		var async = t.startAsync("test_parser");

		var input = '{"a": 1, "b": true, "c": ["d"]}',
			pipeline = new ReadString(input).pipe(new Parser()),
			result = [];

		pipeline.on("data", function(chunk){
			result.push({id: chunk.id, val: chunk.value});
		});
		pipeline.on("end", function(){
			eval(t.ASSERT("result.length === 23"));
			eval(t.TEST("result[0].id === '{' && result[0].val === '{'"));
			eval(t.TEST("result[1].id === '\"' && result[1].val === '\"'"));
			eval(t.TEST("result[2].id === 'plainChunk' && result[2].val === 'a'"));
			eval(t.TEST("result[3].id === '\"' && result[3].val === '\"'"));
			eval(t.TEST("result[4].id === ':' && result[4].val === ':'"));
			eval(t.TEST("result[5].id === 'nonZero' && result[5].val === '1'"));
			eval(t.TEST("result[6].id === ',' && result[6].val === ','"));
			eval(t.TEST("result[7].id === '\"' && result[7].val === '\"'"));
			eval(t.TEST("result[8].id === 'plainChunk' && result[8].val === 'b'"));
			eval(t.TEST("result[9].id === '\"' && result[9].val === '\"'"));
			eval(t.TEST("result[10].id === ':' && result[10].val === ':'"));
			eval(t.TEST("result[11].id === 'true' && result[11].val === 'true'"));
			eval(t.TEST("result[12].id === ',' && result[12].val === ','"));
			eval(t.TEST("result[13].id === '\"' && result[13].val === '\"'"));
			eval(t.TEST("result[14].id === 'plainChunk' && result[14].val === 'c'"));
			eval(t.TEST("result[15].id === '\"' && result[15].val === '\"'"));
			eval(t.TEST("result[16].id === ':' && result[16].val === ':'"));
			eval(t.TEST("result[17].id === '[' && result[17].val === '['"));
			eval(t.TEST("result[18].id === '\"' && result[18].val === '\"'"));
			eval(t.TEST("result[19].id === 'plainChunk' && result[19].val === 'd'"));
			eval(t.TEST("result[20].id === '\"' && result[20].val === '\"'"));
			eval(t.TEST("result[21].id === ']' && result[21].val === ']'"));
			eval(t.TEST("result[22].id === '}' && result[22].val === '}'"));
			async.done();
		});
	},
	function test_parser_fail (t) {
		var async = t.startAsync("test_parser_fail");

		var stream = new Parser();

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

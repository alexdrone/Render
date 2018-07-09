var ReadString = require("../ReadString");
var Parser = require("../../Parser");
var Streamer = require("../../Streamer");
var Filter = require("../../Filter");
var StreamPrinter = require("./StreamPrinter")


var input = '{"a": 1, "b": true, "c": ["d"]}';


var stream   = new ReadString(input);
var parser   = new Parser();
var streamer = new Streamer();
var filter   = new Filter({filter: /^(|a|c)$/});
var printer  = new StreamPrinter();

console.log(input);
stream.pipe(parser).pipe(streamer).pipe(filter).pipe(printer);

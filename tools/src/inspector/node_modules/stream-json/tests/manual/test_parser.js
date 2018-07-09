var ReadString = require("../ReadString");
var Parser = require("../../Parser");
var TokenPrinter = require("./TokenPrinter")


var input = '{"a": 1, "b": true, "c": ["d"]}';


var stream = new ReadString(input);
var parser = new Parser();
var tokens = new TokenPrinter();

console.log(input);
stream.pipe(parser).pipe(tokens);

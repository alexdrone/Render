var Scanner  = require("../Scanner");
var Parser   = require("../bottomUp/Parser");

var expr = require("./expr");


var scanner = new Scanner();

//scanner.addBuffer("(1 + 2) * 3[4]", true);
scanner.addBuffer("[a[b]]", true);


console.log("Buffer: " + scanner.buffer);

var parser = new Parser(expr, "operand");

for(;;){
	var expected = parser.getExpectedState();
	if(!expected){
		// we are done
		break;
	}
	var token = scanner.getToken(expected);
	if(token === true){
		throw Error("Scanner requests more data, which is impossible.");
	}
	parser.putToken(token, scanner);
}

if(!scanner.isFinished()){
	throw Error("Unprocessed symbols: " +
		(scanner.buffer.length > 16 ? scanner.buffer.substring(0, 16) + "..." : scanner.buffer));
}

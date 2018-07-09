var Scanner  = require("../Scanner");
var Parser   = require("../topDown/Parser");

var json = require("./json");

// var printGrammar = require("./printGrammar");
// printGrammar(json);


var scanner = new Scanner();

scanner.addBuffer("[0, 1, 0.2, 1e2, 1.2E3, 1.2e-3, 1.2e+34, " +
	"[], [-0, -1, -0.2, -1e2, -1.2E3, -1.2e-3, -1.2e+34], " +
	"true, false, null, \"I say: \\\"Hey!\\\"\", " +
	"{}, {\"a\": 2}, {\"b\": true, \"c\": {}}]", true);

// scanner.addBuffer("1e2", true);
// scanner.addBuffer("[[], [true], true]", true);
// scanner.addBuffer("[[[]]]", true);

console.log("Buffer: " + scanner.buffer);

var parser = new Parser(json);

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

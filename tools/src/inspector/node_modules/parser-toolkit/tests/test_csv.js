var Scanner  = require("../Scanner");
var Parser   = require("../topDown/Parser");

var csv = require("./csv");

// var printGrammar = require("./printGrammar");
// printGrammar(csv);


var scanner = new Scanner();

scanner.addBuffer("\"1\r\"\"\n2\"", true);

var parser = new Parser(csv);

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
	throw Error("Error: scanner has some unprocessed symbols.");
}

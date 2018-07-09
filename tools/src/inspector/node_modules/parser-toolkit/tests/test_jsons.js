var Scanner = require("../Scanner");
var Parser  = require("../topDown/Parser");

var json = require("./json");

var fs = require("fs"), path = require("path"), zlib = require("zlib");


var scanner = new Scanner(),
	parser = new Parser(json);

fs.readFile(path.resolve(__dirname, "sample.json.gz"), function(err, data){
	if(err){
		throw err;
	}
	zlib.gunzip(data, function(err, data){
		if(err){
			throw err;
		}

		// let's process the whole file
		scanner.addBuffer(data, true);

		// now let's loop over tokens
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
	});
});

"use strict";


var Scanner    = require("parser-toolkit/Scanner");
var JsonParser = require("parser-toolkit/topDown/Parser");

var json = require("./Grammar");

var util = require("util");
var Transform = require("stream").Transform;


function Parser(options){
	Transform.call(this, options);
	this._writableState.objectMode = false;
	this._readableState.objectMode = true;

	this._scanner = new Scanner();
	this._parser  = new JsonParser(json);

	var self = this;
	this._parser.onToken = function onToken(token){
		self.push(token);
	};
}
util.inherits(Parser, Transform);

Parser.prototype._transform = function transform(chunk, encoding, callback){
	this._scanner.addBuffer(chunk.toString());
	this._processInput(callback);
};

Parser.prototype._flush = function flush(callback){
	this._scanner.addBuffer("", true);
	this._processInput(callback);
};

Parser.prototype._processInput = function processInput(callback){
	try{
		if(this._expected === null){
			throw Error("Unexpected input after parser has finished.");
		}
		if(typeof this._expected == "undefined"){
			this._expected = this._parser.getExpectedState();
		}
		if(this._expected){
			for(;;){
				var token = this._scanner.getToken(this._expected);
				if(token === true){
					// need more input
					break;
				}
				this._parser.putToken(token, this._scanner);
				this._expected = this._parser.getExpectedState();
				if(!this._expected){
					// we are done
					break;
				}
			}
		}
		if(this._expected === null && !this._scanner.isFinished()){
			throw Error("Scanner has unprocessed symbols.");
		}
	}catch(err){
		callback(err);
		return;
	}
	callback();
};


module.exports = Parser;

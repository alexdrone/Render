"use strict";


var util = require("util");
var Transform = require("stream").Transform;


var EXPECTING_NOTHING      = 0,
	EXPECTING_VALUE        = 1,
	// object
	EXPECTING_KEY_FIRST    = 2,
	EXPECTING_KEY          = 3,
	EXPECTING_KEY_COLON    = 4,
	EXPECTING_OBJECT_STOP  = 5,
	// array
	EXPECTING_ARRAY_FIRST  = 6,
	EXPECTING_ARRAY_STOP   = 7,
	// key
	EXPECTING_KEY_VALUE    = 8,
	// string
	EXPECTING_STRING_VALUE = 9,
	// numbers
	EXPECTING_NUMBER_START = 10,
	EXPECTING_NUMBER_DIGIT = 11,
	EXPECTING_FRACTION     = 12,
	EXPECTING_FRAC_START   = 13,
	EXPECTING_FRAC_DIGIT   = 14,
	EXPECTING_EXP_SIGN     = 15,
	EXPECTING_EXP_START    = 16,
	EXPECTING_EXP_DIGIT    = 17;

var PARSING_NOTHING = 0,
	PARSING_OBJECT  = 1,
	PARSING_ARRAY   = 2;

var LITERALS = {t: "true", f: "false", n: "null"},
	ESCAPED_CHAR = "e", HEXADECIMALS = "h";

var hex = {
			"0": 1, "1": 1, "2": 1, "3": 1, "4": 1, "5": 1, "6": 1, "7": 1, "8": 1, "9": 1,
			"a": 1, "b": 1, "c": 1, "d": 1, "e": 1, "f": 1,
			"A": 1, "B": 1, "C": 1, "D": 1, "E": 1, "F": 1
		};


function Parser(options){
	Transform.call(this, options);
	this._writableState.objectMode = false;
	this._readableState.objectMode = true;

	this._state  = EXPECTING_VALUE;
	this._parent = PARSING_NOTHING;
	this._stack  = [];

	this._literal = null;
	this._literalFrom = 0;

	this._stash = "";
	this._chunk = null;

	this._line = this._pos = 1;
	this._lastChar = "";
}
util.inherits(Parser, Transform);


Parser.prototype._transform = function transform(chunk, encoding, callback){
	var s = chunk.toString(), i = 0, j, k, n = s.length;

	main: do{
		if(this._literal){
			switch(this._literal){
				case ESCAPED_CHAR:
					switch(s[0]){
						case "\"": case "/": case "b": case "f":
						case "\\": case "n": case "r": case "t":
							this.push({id: "escapedChars", value: "\\" + s[0], line: this._line, pos: this._pos});
							++i;
							++this._pos;
							break;
						case "u":
							k = Math.min(5, n);
							for(j = 1, ++i; i < k; ++j, ++i){
								if(!hex[s[i]]) {
									return callback(new Error("While matching hexadecimals encountered '" + s[i] + "'"));
								}
								this._stash += s[i];
							}
							if(j < 5){
								this._literal = HEXADECIMALS;
								this._literalFrom = j;
								break main;
							}
							this.push({id: "escapedChars", value: "\\u" + this._stash, line: this._line, pos: this._pos});
							this._stash = "";
							this._pos += 5;
							break;
						default:
							return callback(new Error("Wrong escaped symbol '" + c + "'"));
					}
					break;
				case HEXADECIMALS:
					k = Math.min(5 - this._literalFrom, n);
					for(j = this._literalFrom; i < k; ++j, ++i){
						if(!hex[s[i]]) {
							return callback(new Error("While matching hexadecimals encountered '" + s[i] + "'"));
						}
						this._stash += s[i];
					}
					if(j < 5){
						this._literalFrom = j;
						break main;
					}
					this.push({id: "escapedChars", value: "\\u" + this._stash, line: this._line, pos: this._pos});
					this._stash = "";
					this._pos += 5;
					break;
				default:
					k = Math.min(this._literal.length - this._literalFrom, n);
					for(j = this._literalFrom; i < k; ++j, ++i){
						if(this._literal[j] !== s[i]) {
							return callback(new Error("While matching '" + this._literal + "' encountered '" + s[j] + "' instead of '" + LITERAL_TRUE[j - i] + "'"));
						}
					}
					if(j < this._literal.length){
						this._literalFrom = j;
						break main;
					}
					this.push({id: this._literal, value: this._literal, line: this._line, pos: this._pos});
					this._pos += this._literal.length;
					// end of value
					switch(this._parent){
						case PARSING_OBJECT:
							this._state = EXPECTING_OBJECT_STOP;
							break;
						case PARSING_ARRAY:
							this._state = EXPECTING_ARRAY_STOP;
							break;
						default:
							this._state = EXPECTING_NOTHING;
							break;
					}
					break;
			}
			this._literal = null;
		}

		for(; i < n; ++i, ++this._pos){
			var c = s[i];
			// calculate (line, pos)
			switch(c){
				case "\r":
					++this._line;
					this._pos = 1;
					break;
				case "\n":
					if(this._lastChar !== "\r"){
						++this._line;
					}
					this._pos = 1;
					break;
			}
			this._lastChar = c;
			// process a character
			switch(this._state){
				case EXPECTING_NOTHING:
					switch(c){
						case " ": case "\t": case "\r": case "\n": // ws
							if(this._chunk && this._chunk.id !== "ws"){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							if(!this._chunk){
								this._chunk = {id: "ws", value: i, line: this._line, pos: this._pos};
							}
							continue;
						default:
							return callback(new Error("Expected whitespace"));
					}
					break;
				case EXPECTING_VALUE:
				case EXPECTING_ARRAY_FIRST:
					switch(c){
						case "{": // object
							if(this._chunk){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							this.push({id: c, value: c, line: this._line, pos: this._pos});
							this._state = EXPECTING_KEY_FIRST;
							this._stack.push(this._parent);
							this._parent = PARSING_OBJECT;
							continue;
						case "[": // array
							if(this._chunk){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							this.push({id: c, value: c, line: this._line, pos: this._pos});
							this._state = EXPECTING_ARRAY_FIRST;
							this._stack.push(this._parent);
							this._parent = PARSING_ARRAY;
							continue;
						case "\"": // string
							if(this._chunk){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							this.push({id: c, value: c, line: this._line, pos: this._pos});
							this._state = EXPECTING_STRING_VALUE;
							continue;
						case "-": // number
							if(this._chunk){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							this.push({id: c, value: c, line: this._line, pos: this._pos});
							this._state = EXPECTING_NUMBER_START;
							continue;
						case "0": // number
							if(this._chunk){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							this.push({id: c, value: c, line: this._line, pos: this._pos});
							this._state = EXPECTING_FRACTION;
							continue;
						case "1": case "2": case "3": case "4": case "5": case "6": case "7": case "8": case "9": // number
							if(this._chunk){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							this.push({id: "nonZero", value: c, line: this._line, pos: this._pos});
							this._state = EXPECTING_NUMBER_DIGIT;
							continue;
						case "t": // true
						case "f": // false
						case "n": // null
							if(this._chunk){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							this._literal = LITERALS[c];
							k = Math.min(this._literal.length + i, n);
							for(j = 1, ++i; i < k; ++j, ++i){
								if(this._literal[j] !== s[i]) {
									return callback(new Error("While matching '" + this._literal + "' encountered '" + s[i] + "' instead of '" + this._literal[j] + "'"));
								}
							}
							if(j < this._literal.length){
								this._literalFrom = j;
								break main;
							}
							this.push({id: this._literal, value: this._literal, line: this._line, pos: this._pos});
							--i;
							this._pos += this._literal.length - 1;
							this._literal = null;
							break;
						case " ": case "\t": case "\r": case "\n": // ws
							if(this._chunk && this._chunk.id !== "ws"){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							if(!this._chunk){
								this._chunk = {id: "ws", value: i, line: this._line, pos: this._pos};
							}
							continue;
						case "]":
							if(this._chunk){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							if(this._state !== EXPECTING_ARRAY_FIRST){
								return callback(new Error("Expected a value but got ']' instead"));
							}
							this.push({id: c, value: c, line: this._line, pos: this._pos});
							this._parent = this._stack.pop();
							break;
						default:
							return callback(new Error("Expected a value"));
					}
					break;
				case EXPECTING_KEY_FIRST:
				case EXPECTING_KEY:
					switch(c){
						case "}":
							if(this._chunk){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							if(this._state !== EXPECTING_KEY_FIRST){
								return callback(new Error("Expected a key value"));
							}
							this.push({id: c, value: c, line: this._line, pos: this._pos});
							this._parent = this._stack.pop();
							break;
						case "\"":
							if(this._chunk){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							this.push({id: c, value: c, line: this._line, pos: this._pos});
							this._state = EXPECTING_KEY_VALUE;
							continue;
						case " ": case "\t": case "\r": case "\n": // ws
							if(this._chunk && this._chunk.id !== "ws"){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							if(!this._chunk){
								this._chunk = {id: "ws", value: i, line: this._line, pos: this._pos};
							}
							continue;
						default:
							return callback(new Error("Expected a key"));
					}
					break;
				case EXPECTING_KEY_COLON:
					switch(c){
						case ":":
							if(this._chunk){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							this.push({id: c, value: c, line: this._line, pos: this._pos});
							this._state = EXPECTING_VALUE;
							continue;
						case " ": case "\t": case "\r": case "\n": // ws
							if(this._chunk && this._chunk.id !== "ws"){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							if(!this._chunk){
								this._chunk = {id: "ws", value: i, line: this._line, pos: this._pos};
							}
							continue;
						default:
							return callback(new Error("Expected ':'"));
					}
					break;
				case EXPECTING_OBJECT_STOP:
					switch(c){
						case "}":
							if(this._chunk){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							this.push({id: c, value: c, line: this._line, pos: this._pos});
							this._parent = this._stack.pop();
							break;
						case ",":
							if(this._chunk){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							this.push({id: c, value: c, line: this._line, pos: this._pos});
							this._state = EXPECTING_KEY;
							continue;
						case " ": case "\t": case "\r": case "\n": // ws
							if(this._chunk && this._chunk.id !== "ws"){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							if(!this._chunk){
								this._chunk = {id: "ws", value: i, line: this._line, pos: this._pos};
							}
							continue;
						default:
							return callback(new Error("Expected ','"));
					}
					break;
				case EXPECTING_ARRAY_STOP:
					switch(c){
						case "]":
							if(this._chunk){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							this.push({id: c, value: c, line: this._line, pos: this._pos});
							this._parent = this._stack.pop();
							break;
						case ",":
							if(this._chunk){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							this.push({id: c, value: c, line: this._line, pos: this._pos});
							this._state = EXPECTING_VALUE;
							continue;
						case " ": case "\t": case "\r": case "\n": // ws
							if(this._chunk && this._chunk.id !== "ws"){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							if(!this._chunk){
								this._chunk = {id: "ws", value: i, line: this._line, pos: this._pos};
							}
							continue;
						default:
							return callback(new Error("Expected ','"));
					}
					break;
				case EXPECTING_KEY_VALUE:
				case EXPECTING_STRING_VALUE:
					switch(c){
						case "\"":
							if(this._chunk){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							this.push({id: c, value: c, line: this._line, pos: this._pos});
							if(this._state === EXPECTING_KEY_VALUE){
								this._state = EXPECTING_KEY_COLON;
								continue;
							}
							break;
						case "\\":
							if(this._chunk){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							if(i + 1 < n){
								c = s[++i];
								switch(c){
									case "\"": case "/": case "b": case "f":
									case "\\": case "n": case "r": case "t":
										this.push({id: "escapedChars", value: "\\" + c, line: this._line, pos: this._pos});
										++this._pos;
										continue;
									case "u":
										k = Math.min(i + 5, n);
										for(j = 1, ++i; i < k; ++j, ++i){
											if(!hex[s[i]]) {
												return callback(new Error("While matching hexadecimals encountered '" + s[i] + "'"));
											}
										}
										if(j < 5){
											// emit this._literal
											this._literal = HEXADECIMALS;
											this._literalFrom = j;
											break main;
										}
										this.push({id: "escapedChars", value: "\\u" + s.substr(i - 4, 4),
											line: this._line, pos: this._pos});
										--i;
										this._pos += 5;
										continue;
									default:
										return callback(new Error("Wrong escaped symbol '" + c + "'"));
								}
							}
							this._literal = ESCAPED_CHAR;
							break main;
						default:
							if(this._chunk && this._chunk.id !== "plainChunk"){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							if(!this._chunk){
								this._chunk = {id: "plainChunk", value: i, line: this._line, pos: this._pos};
							}
							continue;
					}
					break;
				case EXPECTING_NUMBER_START:
					switch(c){
						case "0":
							if(this._chunk){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							this.push({id: c, value: c, line: this._line, pos: this._pos});
							this._state = EXPECTING_FRACTION;
							continue;
						case "1": case "2": case "3":
						case "4": case "5": case "6":
						case "7": case "8": case "9":
							if(this._chunk){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							this.push({id: "nonZero", value: c, line: this._line, pos: this._pos});
							this._state = EXPECTING_NUMBER_DIGIT;
							continue;
						default:
							return callback(new Error("Expected a digit"));
					}
					break;
				case EXPECTING_NUMBER_DIGIT:
				case EXPECTING_FRACTION:
				case EXPECTING_FRAC_DIGIT:
					switch(c){
						case "0": case "1": case "2": case "3": case "4":
						case "5": case "6": case "7": case "8": case "9":
							if(this._chunk && this._chunk.id !== "numericChunk"){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							if(this._state === EXPECTING_FRACTION){
								return callback(new Error("Expected '.' or 'e'"));
							}
							if(!this._chunk){
								this._chunk = {id: "numericChunk", value: i, line: this._line, pos: this._pos};
							}
							continue;
						case ".":
							if(this._chunk){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							if(this._state === EXPECTING_FRAC_DIGIT){
								return callback(new Error("Expected a digit"));
							}
							this.push({id: c, value: c, line: this._line, pos: this._pos});
							this._state = EXPECTING_FRAC_START;
							continue;
						case "e": case "E":
							if(this._chunk){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							this.push({id: "exponent", value: c, line: this._line, pos: this._pos});
							this._state = EXPECTING_EXP_SIGN;
							continue;
						default:
							if(this._chunk){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							--i;
							--this._pos;
							break;
					}
					break;
				case EXPECTING_FRAC_START:
					switch(c){
						case "0": case "1": case "2": case "3": case "4":
						case "5": case "6": case "7": case "8": case "9":
							if(this._chunk && this._chunk.id !== "numericChunk"){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							if(!this._chunk){
								this._chunk = {id: "numericChunk", value: i, line: this._line, pos: this._pos};
							}
							this._state = EXPECTING_FRAC_DIGIT;
							continue;
						default:
							return callback(new Error("Expected a digit"));
					}
					break;
				case EXPECTING_EXP_SIGN:
				case EXPECTING_EXP_START:
					switch(c){
						case "-": case "+":
							if(this._state === EXPECTING_EXP_START){
								return callback(new Error("Expected a digit"));
							}
							if(this._chunk){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							this.push({id: c, value: c, line: this._line, pos: this._pos});
							this._state = EXPECTING_EXP_START;
							continue;
						case "0": case "1": case "2": case "3": case "4":
						case "5": case "6": case "7": case "8": case "9":
							if(this._chunk && this._chunk.id !== "numericChunk"){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							if(!this._chunk){
								this._chunk = {id: "numericChunk", value: i, line: this._line, pos: this._pos};
							}
							this._state = EXPECTING_EXP_DIGIT;
							continue;
						default:
							return callback(new Error("Expected a digit"));
					}
					break;
				case EXPECTING_EXP_DIGIT:
					switch(c){
						case "0": case "1": case "2": case "3": case "4":
						case "5": case "6": case "7": case "8": case "9":
							if(this._chunk && this._chunk.id !== "numericChunk"){
								this._chunk.value = s.substring(this._chunk.value, i);
								this.push(this._chunk);
								this._chunk = null;
							}
							if(!this._chunk){
								this._chunk = {id: "numericChunk", value: i, line: this._line, pos: this._pos};
							}
							continue;
						default:
							--i;
							--this._pos;
							break;
					}
					break;
				default:
					return callback(new Error("Unexpected this._state: " + this._state));
			}
			// end of value
			switch(this._parent){
				case PARSING_OBJECT:
					this._state = EXPECTING_OBJECT_STOP;
					break;
				case PARSING_ARRAY:
					this._state = EXPECTING_ARRAY_STOP;
					break;
				default:
					this._state = EXPECTING_NOTHING;
					break;
			}
		}

		if(this._chunk){
			this._chunk.value = s.substring(this._chunk.value, i);
			this.push(this._chunk);
			this._chunk = null;
		}
	}while(false);

	callback();
};

Parser.prototype._flush = function flush(callback){
	switch(this._state){
		// normal end
		case EXPECTING_NOTHING:
		// optional number parts
		case EXPECTING_NUMBER_DIGIT:
		case EXPECTING_FRACTION:
		case EXPECTING_FRAC_DIGIT:
		case EXPECTING_EXP_DIGIT:
			callback();
			return;
	}
	callback(new Error("Parser didn't finish, yet the stream has ended."));
};

module.exports = Parser;

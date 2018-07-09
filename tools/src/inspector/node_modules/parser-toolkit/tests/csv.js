/* UMD.define */ (typeof define=="function"&&define||function(d,f,m){m={module:module,require:require};module.exports=f.apply(null,d.map(function(n){return m[n]||require(n)}))})
(["../topDown/Grammar"], function(Grammar){
	"use strict";

	var rule = Grammar.rule, any = Grammar.any, maybe = Grammar.maybe, repeat = Grammar.repeat;

	var crlf = {id: "crlf", pattern: /\u000A|\u000D\u000A|\u000D/},
		sep  = {id: "sep",  pattern: /\,/},
		text = {id: "text", pattern: /[^\"\,\u000A\u000D]{1,256}/};

	var csv = new Grammar({
			main:    [rule("record"), maybe(crlf, maybe(rule("main")))],
			record:  [rule("field"), repeat(sep, rule("field"))],
			field:   maybe(any(rule("escaped"), rule("value"))),
			escaped: ["\"", repeat(any(text, sep, crlf, "\"\"")), "\""],
			value:   [text, repeat(text)]
		});

	return csv;
});

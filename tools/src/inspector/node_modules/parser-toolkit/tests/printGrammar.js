function printGrammar(grammar){
	var registry = {};
	Object.keys(grammar).forEach(function(name){
		collectRules(grammar[name], registry);
	});
	console.log("Grammar: " + Object.keys(grammar).length);
	console.log("Registry: " + Object.keys(registry).length);
	Object.keys(registry).forEach(function(name){
		printRule(registry[name]);
	});
}

function collectRules(rule, registry){
	if(!rule.name){
		rule.name = "R" + Object.keys(registry).length;
	}
	if(registry[rule.name] !== rule){
		registry[rule.name] = rule;
		rule.forEach(function(item){
			if(!item.tokens){
				return;
			}
			item.tokens.forEach(function(token){
				token.nextArray.forEach(function(rule){
					collectRules(rule, registry);
				});
			});
		});
	}
}

function printRule(rule){
	var flags = collectFlags(rule);
	console.log(rule.name + ":" + (flags ? " " + flags : ""));
	printItem(rule.state);
	rule.forEach(printItem);
}

function collectFlags(item){
	var flags = [];
	if(item.any){
		flags.push("any");
	}
	if(item.optional){
		flags.push("optional");
	}
	if(item.repeatable){
		flags.push("repeatable");
	}
	return flags.join(" ");
}

function printItem(item, index){
	var flags = item ? collectFlags(item) : "NONE",
		name  = typeof index == "number" ? "item/" + index : "state";
	console.log("  " + name + ":" + (flags ? " " + flags : ""));
	if(item){
		console.log("    pattern: " + (item.pattern ? item.pattern.source : "NONE"));
		if(item.tokens){
			item.tokens.forEach(function(token){
				var path = token.nextArray.map(function(rule, index){
						return rule.name + "/" + token.nextIndex[index];
					}).join(" ");
				console.log("    token: " + token.id + " - " + path);
			});
		}else if(item instanceof Array){
			console.log("    rule: " + item.name);
		}else{
			console.log("    UNKNOWN: " + item);
		}
	}
}

module.exports = printGrammar;

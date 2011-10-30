import token;
import environment;
import errors;
import std.cstream;
import std.string;
import core.stdc.stdlib : exit;

void import_basics(ref Environment env) {
	// Basic constructs and functions
	mixin(AddFunc!("null"));
	mixin(AddFunc!("about"));
	mixin(AddFunc!("exit"));
	// Control structures
	mixin(AddFunc!("if"));
	mixin(AddFunc!("switch"));
	mixin(AddFunc!("while"));
	mixin(AddFunc!("for"));
	mixin(AddFunc!("foreach"));
	mixin(AddFunc!("break"));
}

Token bi_null(ref Token[] argv, ref Environment env) {
	Token ret;
	if(argv.length) {
		ret = argv[$-1];
		ret = env.eval(ret);
	} else {
		ret = Token("__return__").withType(Token.VarType.tVarname);
		ret = env.eval(ret);
	}
	return ret;
}

Token bi_exit(ref Token[] argv, ref Environment env) {
	exit(0);
	assert(0);
}

Token bi_about(ref Token[] argv, ref Environment env)
{
	string name = "Oratd";
	Token[] dev; {
		dev ~= Token("demosthenes2k8");
		dev ~= Token("bot190");
		dev ~= Token("dysxqer");
		dev ~= Token("cgcat93");
		dev ~= Token("asterios");
	}
	string or_version = "20111020-dev";
	
	Token ret;
	if(argv.length>1) {
		throw new OratrArgumentCountException(argv.length,"about","0-1");
	}
	if(argv.length==0) {
		dout.writef("\t\t+------------------+\n"~
					"\t\t|      ORATR       |\n"~
					"\t\t+------------------+\n");
		dout.writef("\thttp://oratr.googlecode.com\n"~
					"\thttp://demosthenes2k8.endoftheinternet.org/oratr/\n"~
					"Implementation:\n"~
					"\tName: " ~ name ~ "\n"~
					"\tVersion: " ~ or_version ~ "\n");
		static if(0) {
			dout.writef("Developers:\n");
			foreach(d;dev) {
				dout.writef("\t%s\n",d.str);
			}
		}
		ret = Token("");
	} else {
		string dat = argv[0].str;
		ret.type=Token.VarType.tString;
		switch(toLower(dat)) {
		case "name":
		case "oratr":
		case "implementation":
			ret = Token(name);
			break;
		case "dev":
		case "devs":
		case "developer":
		case "developers":
			ret.type = Token.VarType.tArray;
			ret.str = "";
			ret.arr = dev;
			break;
		case "version":
			ret = Token(or_version);
			break;
		default:
			throw new OratrInvalidArgumentException(dat,0);
		}
	}
	return ret;
}

bool checkBoolToken(Token tok, ref Environment env, uint pos)
{
	switch(tok.type) {
	case Token.VarType.tNumeric:
		return (tok.d != 0 && tok.str != "nan");
	case Token.VarType.tArray:
		return (tok.arr.length != 0);
	case Token.VarType.tString:
		return (tok.str != "");
	case Token.VarType.tCode:
		parse.parse(tok.arr, env);
		return checkBoolToken(*env.evalVarname("__return__"),env,pos);
	default:
		throw new OratrInvalidArgumentException(vartypeToStr(tok.type),pos);
	}
}

Token bi_if(ref Token[] argv, ref Environment env)
{
	Token ret;
	if(argv.length < 2) {
		throw new OratrArgumentCountExceptionControlStructure(
			argv.length,"if","2+ matching tokens and");
	}
	Token cond = argv[0];
	cond = env.eval(cond);
	Token code = argv[1];
	code = env.eval(code);
	if(code.type != Token.VarType.tCode) {
		throw new OratrInvalidCodeException();
	}
	bool runCode = false;
	runCode = checkBoolToken(cond,env,0);
	if(runCode) {
		parse.parse(code.arr,env);
	} else {
		if(argv.length != 2) {
			// There's no other clause
			if(argv.length >= 4 && argv[2].str == "else" && argv[2].type == Token.VarType.tVarname) {
				if(argv.length == 4) {
					code = argv[3];
					code = env.eval(code);
					if(code.type != Token.VarType.tCode) {
						throw new OratrInvalidCodeException();
					}
					parse.parse(code.arr,env);
				} else if(argv[3].str == "if" && argv[3].type == Token.VarType.tVarname) {
					Token[] newArgs = argv[4..$];
					bi_if(newArgs,env);
				} else {
					throw new OratrInvalidCodeException();
				}
			} else {
				throw new OratrArgumentCountExceptionControlStructure(
					argv.length,"if","2+ matching tokens and");
			}
		}
	}
	ret = *env.evalVarname("__return__");
	return ret;
}

Token bi_switch(ref Token[] argv, ref Environment env)
{
	Token ret;
	if(argv.length < 3) {
		throw new OratrArgumentCountExceptionControlStructure(
			argv.length,"switch","3+ matching tokens and");
	}
	Token baseValue = argv[0];
	baseValue = env.eval(baseValue);
	if(baseValue.type != Token.VarType.tNumeric &&
		baseValue.type != Token.VarType.tString &&
		baseValue.type != Token.VarType.tArray &&
		baseValue.type != Token.VarType.tTypeID) {
		throw new OratrInvalidArgumentException(vartypeToStr(baseValue.type),0);
	}
	execStatement:
	for(uint i=1;i<argv.length;i++) {
		Token val = argv[i];
		bool runCode = false;
		if(val.str == "default" && val.type == Token.VarType.tVarname) {
			runCode = true;
		} else {
			val = env.eval(val);
			switch(baseValue.type) {
			case Token.VarType.tNumeric:
				runCode = (baseValue.d == val.d);
				break;
			case Token.VarType.tString:
				runCode = (baseValue.str == val.str);
				break;
			case Token.VarType.tArray:
				runCode = (baseValue.arr == val.arr);
				break;
			case Token.VarType.tTypeID:
				runCode = (baseValue.str == val.str);
				break;
			default:
				break;
			}
		}
		if(runCode) {
			foreach(tok;argv[i+1..$]) {
				if(tok.type == Token.VarType.tCode) {
					parse.parse(tok.arr,env);
					ret = *env.evalVarname("__return__");
					// Stop checking the conditions
					break execStatement;
				}
			}
			// If it reached here, the condition was reached but no code was found
			throw new OratrInvalidCodeException();
		}
	}
	return ret;
}

Token bi_while(ref Token[] argv, ref Environment env)
{
	Token ret;
	if(argv.length != 2) {
		throw new OratrArgumentCountExceptionControlStructure(
			argv.length,"while","2");
	}
	Token cond = argv[0];
	Token code = argv[1];
	code = env.eval(code);
	if(code.type != Token.VarType.tCode) {
		throw new OratrInvalidCodeException();
	}
	bool runCode = true;
	while(runCode) {
		cond = argv[0];
		cond = env.eval(cond);
		runCode = checkBoolToken(cond,env,0);
		if(runCode) {
			parse.parse(code.arr,env);
		}
		if(env.flags & Environment.Flags.Break) {
			env.flags ^= Environment.Flags.Break;
			break;
		}
	}
	ret = *env.evalVarname("__return__");
	return ret;
}

Token bi_break(ref Token[] argv, ref Environment env)
{
	if(argv.length) throw new OratrArgumentCountException(argv.length,"break","0");
	env.flags |= Environment.Flags.Break;
	return *env.evalVarname("__return__");
}

Token bi_for(ref Token[] argv, ref Environment env)
{
	Token ret;
	if( (argv.length!=2) && (argv.length!=4) ) {
		throw new OratrArgumentCountExceptionControlStructure(
			argv.length,"for","2 or 4");
	}
	Token	cond, // Condition for continuing
			incr, // Incrementation section of loop
			init, // Initialization section of loop
			amount, // Amount of times to run
			code; // The actual code
	env.inscope();
	if(argv.length==2) {
		// Simplified loop
		code = argv[1];
		if(code.type != Token.VarType.tCode) {
			throw new OratrInvalidArgumentException(vartypeToStr(code.type),2);
		}
		amount = argv[0];
		env.eval(amount);
		if(amount.type != Token.VarType.tNumeric) {
			throw new OratrInvalidArgumentException(vartypeToStr(amount.type),1);
		}
		env.scopes[$-1]["__iterator__"] = Token();
		init.arr = [Token("__iterator__").withType(Token.VarType.tVarname),
					Token("=").withType(Token.VarType.tOpcode),
					Token("0").withType(Token.VarType.tNumeric)];
		init.type = Token.VarType.tCode;
		cond.arr = [Token("__iterator__").withType(Token.VarType.tVarname),
					Token("<").withType(Token.VarType.tOpcode),
					amount];
		cond.type = Token.VarType.tCode;
		incr.arr = [Token("__iterator__").withType(Token.VarType.tVarname),
					Token("+=").withType(Token.VarType.tOpcode),
					Token("1").withType(Token.VarType.tNumeric)];
		incr.type = Token.VarType.tCode;
	} else {
		// It has to be 4, because of the previous checks
		code = argv[3];
		if(code.type != Token.VarType.tCode) {
			throw new OratrInvalidArgumentException(vartypeToStr(code.type),3);
		}
		amount = Token(0);
		init = argv[0];
		init = env.eval(init);
		if(init.type != Token.VarType.tCode) {
			throw new OratrInvalidArgumentException(vartypeToStr(init.type),0);
		}
		cond = argv[1];
		cond = env.eval(cond);
		if(cond.type != Token.VarType.tCode) {
			throw new OratrInvalidArgumentException(vartypeToStr(cond.type),1);
		}
		incr = argv[2];
		incr = env.eval(incr);
		if(incr.type != Token.VarType.tCode) {
			throw new OratrInvalidArgumentException(vartypeToStr(incr.type),2);
		}
	}
	parse.parse(init.arr,env);
	bool runCode = checkBoolToken(cond,env,2);
	while(runCode) {
		parse.parse(code.arr,env);
		ret = *env.evalVarname("__return__");
		parse.parse(incr.arr,env);
		*env.evalVarname("__return__") = ret;
		if(env.flags & Environment.Flags.Break) {
			env.flags ^= Environment.Flags.Break;
			break;
		}
		runCode = checkBoolToken(cond,env,2);
	}
	env.outscope();
	return ret;
}

Token bi_foreach(ref Token[] argv, ref Environment env)
{
	Token ret;
	Token index, value, source, code;
	if(argv.length < 2 ||argv.length > 4) {
		throw new OratrArgumentCountExceptionControlStructure(
			argv.length,"foreach","2-4");
	}
	if(argv.length>3) {
		index = argv[$-4];
		if(index.type != Token.VarType.tVarname) {
			throw new OratrInvalidArgumentException(vartypeToStr(index.type),argv.length-4);
		}
	} else {
		index = Token("__index__").withType(Token.VarType.tVarname);
	}
	if(argv.length>2) {
		value = argv[$-3];
		if(value.type != Token.VarType.tVarname) {
			throw new OratrInvalidArgumentException(vartypeToStr(value.type),argv.length-3);
		}
	} else {
		value = Token("__iterator__").withType(Token.VarType.tVarname);
	}
	source = argv[$-2];
	source = env.eval(source);
	if(source.type == Token.VarType.tString) {
		source.arr = [];
		foreach(x;source.str) {
			source.arr ~= Token(x);
		}
	} else if(source.type != Token.VarType.tArray) {
		throw new OratrInvalidArgumentException(vartypeToStr(source.type),argv.length-2);
	}
	code = argv[$-1];
	if(code.type != Token.VarType.tCode) {
		throw new OratrInvalidArgumentException(vartypeToStr(code.type),argv.length-1);
	}
	env.inscope();
	env.scopes[$-1][index.str] = Token(0);
	env.scopes[$-1][value.str] = Token(0);
	foreach(uint i, ref Token e;source.arr) {
		env.evalVarname(index.str).d = i;
		*env.evalVarname(value.str) = e;
		parse.parse(code.arr,env);
		ret = *env.evalVarname("__return__");
		if(env.flags & Environment.Flags.Break) {
			env.flags ^= Environment.Flags.Break;
			break;
		}
	}
	env.outscope();
	return ret;
}
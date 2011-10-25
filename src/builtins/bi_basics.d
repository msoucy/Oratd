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
}

Token bi_null(ref Token[] argv, ref Environment env) {
	Token ret = "__return__";
	ret.type=Token.VarType.tVarname;
	ret = env.eval(ret);
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
	switch(cond.type) {
	case Token.VarType.tNumeric:
		runCode = cond.d != 0;
		break;
	case Token.VarType.tArray:
		runCode = (cond.arr.length != 0);
		break;
	case Token.VarType.tString:
		runCode = (cond.str != "");
		break;
	default:
		throw new OratrInvalidArgumentException(vartypeToStr(cond.type),0);
	}
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
				dout.writef("DEBUG\n");
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
		baseValue.type != Token.VarType.tArray) {
		throw new OratrInvalidArgumentException(vartypeToStr(baseValue.type),0);
	}
	execStatement:
	for(uint i=2;i<argv.length;i++) {
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
			default:
				break;
			}
		}
		if(runCode) {
			foreach(tok;argv[i+1..$]) {
				if(tok.type == Token.VarType.tCode) {
					parse.parse(tok.arr,env);
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

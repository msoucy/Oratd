import token;
import environment;
import errors;
import bi_math;
import bi_vars;
import bi_stdio;
import std.cstream;

bool isSettingOpcode(string s)
{
	return (
		(s=="=") ||
		(s=="~=") ||	
		(s=="+=") ||
		(s=="-=") ||
		(s=="*=") ||
		(s=="/=") ||
		(s=="%=") ||
		(s=="^=") ||
		(s=="|=") ||
		(s=="&=") ||
		(s=="**=") ||
		(s=="<?=") ||
		(s==">?=") ||
		(s=="<<=") ||
		(s==">>=") ||
		(s==">>>=")
	);
}

enum CondenserParam {
	ignoreCodeParts=0x1
};

Token[] condenseArguments(ref Token[] argv, ref Environment env, uint params=0) {
	// Concatenate VarNames with the extensions they need
	for(sizediff_t i = 0;i<argv.length;i++) {
		if(argv[i].type == Token.VarType.tVarname) {
			if(i+2<argv.length && (argv[i+1].type == Token.VarType.tVarOffsetSeperator ||
					argv[i+1].type == Token.VarType.tRecast)) {
				argv[i].str ~= argv[i+1].str ~ argv[i+2].str;
				argv = argv[0..i+1]~argv[i+3..$];
				i -= 1;
			}
		} else if(argv[i].type == Token.VarType.tRawArray) {
			Token[][] temps;
			temps.length = 1;
			foreach(ref tok;argv[i].arr) {
				if(tok.type == Token.VarType.tArrayElementSeperator) {
					temps.length += 1;
				} else {
					temps[$-1] ~= tok;
				}
			}
			argv[i].arr.length = 0;
			foreach(toks;temps) {
				toks = condenseArguments(toks,env);
				if(!toks.length) toks ~= Token(0);
				parse(toks,env);
				argv[i].arr ~= *env.evalVarname("__return__");
			}
			argv[i].type = Token.VarType.tArray;
		} else if(argv[i].type == Token.VarType.tCompoundStatement && !(params&CondenserParam.ignoreCodeParts)) {
			parse(argv[i].arr, env);
			argv[i] = *env.evalVarname("__return__");
		} else if(argv[i].type == Token.VarType.tArrayElementSeperator) {
			argv = argv[0..i]~argv[i+1..$];
			i -= 1;
		}
	}
	return argv;
}

ref Environment parse(ref Token[] argv, ref Environment env)
{
	Token[][] args;
	Token ret;
	args.length = 1;
	foreach(arg;argv) {
		if(arg.type == Token.VarType.tCommandSeperator) {
			args.length += 1;
		} else {
			args[$-1] ~= arg;
		}
	}
	foreach(arglist;args) {
		if(!arglist.length) {continue;}
		if(arglist[0].str == "if" && arglist[0].type == Token.VarType.tVarname) {
			// if gets hijacked here for a variety of reasons
			if(arglist.length < 3) {
				throw new OratrArgumentCountException(
					arglist.length,"\b\b\b\b\b\b\b\b\bcontrol structure if","3+ matching tokens and");
			}
			condenseArguments(arglist,env,CondenserParam.ignoreCodeParts);
			Token cond = arglist[1];
			cond = env.eval(cond);
			Token code = arglist[2];
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
				break;
			}
			if(runCode) {
				parse(code.arr,env);
			} else {
				if(arglist.length >= 5 && arglist[3].str == "else" && arglist[3].type == Token.VarType.tVarname) {
					if(arglist.length == 5) {
						code = arglist[4];
						code = env.eval(code);
						if(code.type != Token.VarType.tCode) {
							throw new OratrInvalidCodeException();
						}
						parse(code.arr,env);
					} else if(arglist[4].str == "if" && arglist[4].type == Token.VarType.tVarname) {
						Token[] newArgs = arglist[4..$];
						parse(newArgs,env);
					} else {
						throw new OratrInvalidCodeException();
					}
				} else {
					throw new OratrArgumentCountException(
						arglist.length,"\b\b\b\b\b\b\b\b\bcontrol structure if","3+ matching tokens and");
				}
			}
		} else if(arglist[0].str == "switch" && arglist[0].type == Token.VarType.tVarname) {
			// switch gets hijacked here for a variety of reasons
			if(arglist.length < 4) {
				throw new OratrArgumentCountException(
					arglist.length,"\b\b\b\b\b\b\b\b\bcontrol structure switch","4+ matching tokens and");
			}
			condenseArguments(arglist,env,CondenserParam.ignoreCodeParts);
			Token baseValue = arglist[1];
			baseValue = env.eval(baseValue);
			if(baseValue.type != Token.VarType.tNumeric && baseValue.type != Token.VarType.tString) {
				throw new OratrInvalidArgumentException(vartypeToStr(baseValue.type),1);
			}
			execStatement:
			for(uint i=2;i<arglist.length;i++) {
				Token val = arglist[i];
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
					foreach(tok;arglist[i+1..$]) {
						if(tok.type == Token.VarType.tCode) {
							parse(tok.arr,env);
							break execStatement;
						}
					}
				}
			}
		} else {
			condenseArguments(arglist,env);
			Token func = arglist[0];
			func = env.eval(func);
			if(func.type == Token.VarType.tBuiltin) {
				arglist = arglist[1..$];
				ret = func.func(arglist,env);
			} else if(func.type == Token.VarType.tFunction) {
				// Execute the new code
			} else {
				// Work out the whole math thing
				if(arglist.length > 2 && isSettingOpcode(arglist[1].str)) {
					ret = bi_set(arglist,env);
				} else {
					ret = bi_math.bi_math(arglist,env);
				}
			}
		}
	}
	*env.evalVarname("__return__") = ret;
	return env;
}
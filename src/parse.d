import token;
import environment;
import dictionary;
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

Token[] condenseArguments(ref Token[] argv, ref Environment env) {
	// Concatenate VarNames with the extensions they need
	for(sizediff_t i = 0;i<argv.length;i++) {
		if(argv[i].type == Token.VarType.tVarname) {
			if(i+2<argv.length && (argv[i+1].type == Token.VarType.tVarOffsetSeperator ||
					argv[i+1].type == Token.VarType.tRecast)) {
				if(argv[i+2].type == Token.VarType.tCompoundStatement) {
					argv[i+2] = env.eval(argv[i+2]);
				}
				argv[i].str ~= argv[i+1].str ~ argv[i+2].str;
				argv = argv[0..i+1]~argv[i+3..$];
				i -= 1;
			}
		} else if(argv[i].type == Token.VarType.tRawArray) {
			Token[][] temps;
			temps.length = 1;
			if(argv[i].arr.length == 0) {
				// It's just [], an empty array
				argv[i].type = Token.VarType.tArray;
				continue;
			}
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
				if(toks.length == 1 && toks[0].type == Token.VarType.tVarname) {
					argv[i].arr ~= env.eval(toks[0]);
				} else {
					parse(toks,env);
					argv[i].arr ~= *env.evalVarname("__return__");
				}
			}
			argv[i].type = Token.VarType.tArray;
			i -= 1;
		} else if(argv[i].type == Token.VarType.tRawDictionary) {
			Token[][] temps;
			temps.length = 1;
			if(argv[i].arr.length == 0) {
				// It's just [], an empty array
				argv[i].type = Token.VarType.tArray;
				continue;
			}
			foreach(ref tok;argv[i].arr) {
				if( tok.type == Token.VarType.tArrayElementSeperator ||
					tok.type == Token.VarType.tCommandSeperator) {
					temps.length += 1;
				} else {
					temps[$-1] ~= tok;
				}
			}
			argv[i].arr.length = 0;
			env.inscope();
			foreach(toks;temps) {
				toks = condenseArguments(toks,env);
				if(!toks.length) toks ~= Token(0);
				if(toks.length == 1 && toks[0].type == Token.VarType.tVarname) {
					argv[i].arr ~= env.eval(toks[0]);
				} else {
					parse(toks,env);
					argv[i].arr ~= *env.evalVarname("__return__");
				}
			}
			auto dict = Dictionary(argv[i]);
			foreach(key, ref tok;env.scopes[$-1]) {
				dict[key] = tok;
			}
			env.outscope();
			argv[i].type = Token.VarType.tDictionary;
			i -= 1;
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
		condenseArguments(arglist,env);
		Token func = env.eval(arglist[0]);
		if(arglist.length > 2 && isSettingOpcode(arglist[1].str)) {
			ret = bi_set(arglist,env);
		} else {
			if(func.type == Token.VarType.tBuiltin) {
				arglist = arglist[1..$];
				ret = func.func(arglist,env);
			} else if(func.type == Token.VarType.tFunction ||
					func.type == Token.VarType.tVariadicFunction) {
				// Execute the new code
				ret = bi_call(arglist,env);
			} else {
				// Work out the whole math thing
				ret = bi_math.bi_math(arglist,env);
			}
		}
	}
	*env.evalVarname("__return__") = ret;
	return env;
}
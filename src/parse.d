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

Token[] condenseArguments(ref Token[] argv, ref Environment env) {
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
		} else if(argv[i].type == Token.VarType.tCompoundStatement) {
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
	*env.evalVarname("__return__") = ret;
	return env;
}
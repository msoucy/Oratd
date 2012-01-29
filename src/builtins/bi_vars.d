import token;
import environment;
import errors;
import parse;
import bi_math;
import std.string;
import std.cstream;

void import_varops(ref Environment env)
{
	mixin(AddFunc!("set"));
	mixin(AddFunc!("typeid"));
	mixin(AddFunc!("function"));
	mixin(AddFunc!("tell"));
	mixin(AddFunc!("call"));
	mixin(AddFunc!("vcall"));
	mixin(AddFunc!("local"));
	env.scopes[0]["var"] = env.scopes[0]["local"];
	mixin(AddFunc!("delete"));
}

Token bi_set(ref Token[] argv, ref Environment env)
{
	Token ret;
	if(argv.length<3) {
		throw new OratrArgumentCountException(0,"set","at least 3");
	}
	if(argv[0].type != Token.VarType.tVarname) {
		throw new OratrInvalidArgumentException(vartypeToStr(argv[0].type),0);
	}
	if(argv[1].type != Token.VarType.tOpcode) {
		throw new OratrInvalidArgumentException(vartypeToStr(argv[1].type),1);
	}
	Token *orig = env.evalVarname(argv[0].str);
	if(argv.length == 3) {
		ret = env.eval(argv[2]);
	} else {
		parse.parse(argv[2..$], env);
		ret = *env.evalVarname("__return__");
	}
	if(argv[1].str == "=") {
		*orig = ret;
	} else {
		Token[] args;
		args ~= *orig;
		args ~= Token(argv[1].str[0..$-1]).withType(Token.VarType.tOpcode);
		args ~= ret;
		parse.parse(args, env);
		*orig = *env.evalVarname("__return__");
	}
	return ret;
}

Token bi_typeid(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"typeid","1");
	}
	Token ret = env.eval(argv[0]);
	ret.str = vartypeToStr(ret.type);
	ret.type = Token.VarType.tTypeID;
	return ret;
}

Token bi_tell(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) throw new OratrArgumentCountException(argv.length,"tell","1");
	Token ret = env.eval(argv[0]);
	if(ret.type == Token.VarType.tNumeric) {
		ret.str = format("`<%s>`:%s",ret.d,vartypeToStr(ret.type));
	} else if(ret.type == Token.VarType.tString) {
		ret.str = format("`%s`:%s",ret.str,vartypeToStr(ret.type));
	} else {
		ret.str = format("`<>`:%s",ret.str,vartypeToStr(ret.type));
	}
	ret.type = Token.VarType.tString;
	return ret;
}
Token bi_function(ref Token[] argv, ref Environment env)
{
	Token ret;
	if(!argv.length) throw new OratrArgumentCountException(argv.length,"function","1+");
	Token code = env.eval(argv[$-1]);
	if(code.type != Token.VarType.tCode) {
		throw new OratrInvalidArgumentException(vartypeToStr(code.type),argv.length-1);
	}
	ret.type = Token.VarType.tFunction;
	auto func = FunctionWrapper(ret);
	func.code = code;
	bool nextIsReference = false;
	for(uint i=0;i<argv.length-1;i++) {
		if(argv[i].type == Token.VarType.tVarname) {
			func.argv ~= argv[i];
			// We use recast to mean reference...
			if(nextIsReference) func.argv[$-1].type = Token.VarType.tRecast;
			nextIsReference = false;
		} else if(argv[i].type == Token.VarType.tOpcode && argv[i].str == "@") {
			if(i==argv.length-2) {
				ret.type = Token.VarType.tVariadicFunction;
			} else {
				nextIsReference = true;
			}
		} else {
			throw new OratrInvalidArgumentException(vartypeToStr(argv[i].type),i);
		}
	}
	return ret;
}

Token bi_vcall(ref Token[] argv, ref Environment env)
{
	// A "variadic" call - pass a function and a list, it calls bi_call using the list as argv 
	Token ret;
	if(argv.length != 2) throw new OratrArgumentCountException(argv.length,"vcall","2");
	Token args = env.eval(argv[1]);
	if(args.type == Token.VarType.tArray) {
		auto tokens = argv[0]~args.arr;
		return bi_call(tokens,env);
	} else if(args.type == Token.VarType.tDictionary) {
		// Do stuff here
		assert(0);
	} else {
		throw new OratrInvalidArgumentException(vartypeToStr(args.type),1);
	}
}

Token bi_call(ref Token[] argv, ref Environment env)
{
	Token ret;
	if(!argv.length) throw new OratrArgumentCountException(argv.length,"call","1+");
	Token func = env.eval(argv[0]);
	if(func.type != Token.VarType.tFunction && func.type != Token.VarType.tVariadicFunction) {
		throw new OratrInvalidArgumentException(vartypeToStr(func.type),0);
	}
	if(argv.length-1 < func.arr[0].arr.length ||
			(func.type == Token.VarType.tFunction && argv.length-1 > func.arr[0].arr.length)) {
		throw new OratrArgumentCountException(argv.length-1,"call",format("%d",func.arr[0].arr.length));
	}
	env.inscope();
	uint i=0;
	auto wrapper = FunctionWrapper(func);
	for(i=0;i<wrapper.argv.length;i++) {
		if(wrapper.argv[i].type == Token.VarType.tRecast) {
			if(argv[i+1].type != Token.VarType.tVarname) {
				throw new OratrInvalidArgumentException(vartypeToStr(argv[i+1].type),i+1);
			}
		}
		Token tmp = env.eval(argv[i+1]);
		env.scopes[$-1][func.arr[0].arr[i].str] = tmp;
	}
	if(func.type == Token.VarType.tVariadicFunction && argv.length-1 > wrapper.argv.length) {
		env.scopes[$-1]["__varargs__"] = Token().withType(Token.VarType.tArray);
		env.scopes[$-1]["__varargs__"].arr = argv[i+1..$];
	}
	env.scopes[$-1]["__func__"] = func;
	env.inscope();
	parse.parse(wrapper.code.arr,env);
	ret = *env.evalVarname("__return__");
	env.outscope();
	auto results = env.scopes[$-1];
	env.outscope();
	for(i=0;i<func.arr[0].arr.length;i++) {
		if(func.arr[0].arr[i].type == Token.VarType.tRecast) {
			*env.evalVarname(argv[i+1].str) = results[func.arr[0].arr[i].str];
		}
	}
	return ret;
}

Token bi_local(ref Token[] argv, ref Environment env)
{
	if(!argv.length) throw new OratrArgumentCountException(argv.length,"local","1+");
	// First loop: make sure the arguments are proper
	foreach(i, arg;argv) {
		if(arg.type != Token.VarType.tVarname) {
			throw new OratrInvalidArgumentException(vartypeToStr(arg.type),i);
		}
	}
	// Second loop: create the new variables in new scope
	foreach(i, arg;argv) {
		env.scopes[$-1][arg.str] = Token().withType(Token.VarType.tNone);
	}
	return *env.evalVarname("__return__");
}

Token bi_delete(ref Token[] argv, ref Environment env)
{
	if(!argv.length) throw new OratrArgumentCountException(argv.length,"delete","1");
	// First loop: make sure the arguments are proper
	foreach(i, arg;argv) {
		if(arg.type != Token.VarType.tVarname) {
			throw new OratrInvalidArgumentException(vartypeToStr(arg.type),i);
		}
	}
	// Second loop: delete each scoped value
	foreach(i, arg;argv) {
		foreach_reverse(ref s;env.scopes) {
			if(arg.str in s) {
				s.remove(arg.str);
				break;
			}
		}
	}
	return *env.evalVarname("__return__");
}

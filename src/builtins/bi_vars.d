import token;
import environment;
import errors;
import parse;
import bi_math;
import std.string;

void import_varops(ref Environment env)
{
	mixin(AddFunc!("set"));
	mixin(AddFunc!("typeid"));
	mixin(AddFunc!("function"));
	mixin(AddFunc!("tell"));
	mixin(AddFunc!("call"));
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
		ret = argv[2];
		ret = env.eval(ret);
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
	Token ret=argv[0];
	ret = env.eval(ret);
	ret.str = vartypeToStr(ret.type);
	ret.type = Token.VarType.tTypeID;
	return ret;
}

Token bi_tell(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) throw new OratrArgumentCountException(argv.length,"tell","1");
	Token ret = argv[0];
	ret = env.eval(ret);
	ret.str = format("`%s`:%s",ret.str,vartypeToStr(ret.type));
	ret.type = Token.VarType.tString;
	return ret;
}
Token bi_function(ref Token[] argv, ref Environment env)
{
	Token ret;
	if(!argv.length) throw new OratrArgumentCountException(argv.length,"function","1+");
	Token code = argv[$-1];
	code = env.eval(code);
	if(code.type != Token.VarType.tCode) {
		throw new OratrInvalidArgumentException(vartypeToStr(code.type),argv.length-1);
	}
	ret.type = Token.VarType.tFunction;
	ret.arr.length = 2;
	ret.arr[0].type = Token.VarType.tArray;
	ret.arr[1] = code;
	bool nextIsReference = false;
	for(uint i=0;i<argv.length-1;i++) {
		if(argv[i].type == Token.VarType.tVarname) {
			ret.arr[0].arr ~= argv[i];
			// We use recast to mean reference...
			if(nextIsReference) ret.arr[0].arr[$-1].type = Token.VarType.tRecast;
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

Token bi_call(ref Token[] argv, ref Environment env)
{
	Token ret;
	if(!argv.length) throw new OratrArgumentCountException(argv.length,"call","1+");
	Token func = argv[0];
	func = env.eval(func);
	if(func.type != Token.VarType.tFunction && func.type != Token.VarType.tVariadicFunction) {
		throw new OratrInvalidArgumentException(vartypeToStr(func.type),0);
	}
	if(argv.length-1 < func.arr[0].arr.length ||
			(func.type == Token.VarType.tFunction && argv.length-1 > func.arr[0].arr.length)) {
		throw new OratrArgumentCountException(argv.length-1,"call",format("%d",func.arr[0].arr.length));
	}
	env.inscope();
	uint i=0;
	for(i=0;i<func.arr[0].arr.length;i++) {
		if(func.arr[0].arr[i].type == Token.VarType.tRecast) {
			if(argv[i+1].type != Token.VarType.tVarname) {
				throw new OratrInvalidArgumentException(vartypeToStr(argv[i+1].type),i+1);
			}
		}
		Token tmp = argv[i+1];
		tmp = env.eval(tmp);
		env.scopes[$-1][func.arr[0].arr[i].str] = tmp;
	}
	if(func.type == Token.VarType.tVariadicFunction && argv.length-1 > func.arr[0].arr.length) {
		env.scopes[$-1]["__varargs__"] = Token().withType(Token.VarType.tArray);
		env.scopes[$-1]["__varargs__"].arr = argv[i+1..$];
	}
	env.scopes[$-1]["__func__"] = func;
	env.inscope();
	parse.parse(func.arr[1].arr,env);
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
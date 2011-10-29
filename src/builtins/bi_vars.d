import token;
import environment;
import errors;
import parse;
import bi_math;
import std.cstream;
import std.string;

void import_varops(ref Environment env)
{
	// Variables
	mixin(AddFunc!("set"));
	mixin(AddFunc!("typeid"));
	mixin(AddFunc!("function"));
	mixin(AddFunc!("tell"));
	mixin(AddFunc!("call"));
	// Operations
	mixin(AddFunc!("trim"));
	mixin(AddFunc!("slice"));
	mixin(AddFunc!("len"));
	mixin(AddFunc!("store"));
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

Token bi_slice(ref Token[] argv, ref  Environment env)
{
	Token ret;
	if(argv.length == 3) {
		// It's an array or a string
		ret = argv[0];
		ret = env.eval(ret);
		Token start = argv[1];
		start = env.eval(start);
		if(start.type != Token.VarType.tNumeric) {
			throw new OratrInvalidArgumentException(vartypeToStr(start.type),1);
		}
		Token stop = argv[2];
		stop = env.eval(stop);
		if(stop.type != Token.VarType.tNumeric) {
			throw new OratrInvalidArgumentException(vartypeToStr(stop.type),2);
		}
		if(start.d < 0) {
			throw new OratrOutOfRangeException("",cast(int)start.d);
		}
		start.d = cast(uint)start.d;
		stop.d = cast(uint)stop.d;
		if(ret.type == Token.VarType.tString) {
			if(stop.d >= ret.str.length) {
				throw new OratrOutOfRangeException("string", cast(int)stop.d);
			}
			if(stop.d >= start.d) {
				ret.str = ret.str[cast(uint)start.d .. cast(uint)stop.d];
			} else {
				ret.str = cast(string)(ret.str[cast(uint)stop.d .. cast(uint)start.d].dup.reverse);
			}
		} else if(ret.type == Token.VarType.tArray) {
			if(stop.d >= ret.arr.length) {
				throw new OratrOutOfRangeException("", cast(int)stop.d);
			}
			if(stop.d >= start.d) {
				ret.arr = ret.arr[cast(uint)start.d .. cast(uint)stop.d];
			} else {
				ret.arr = ret.arr[cast(uint)stop.d .. cast(uint)start.d].reverse;
			}
		} else {
			throw new OratrInvalidArgumentException(vartypeToStr(ret.type),0);
		}
	} else {
		throw new OratrArgumentCountException(argv.length,"slice","3-4");
	}
	return ret;
}

Token bi_trim(ref Token[] argv, ref  Environment env)
{
	// Trim a number to a precision, or a string's leading/trailing signs (default whitespace)
	Token ret;
	if(argv.length == 1) {
		ret = argv[0];
		ret = env.eval(ret);
		if(ret.type != Token.VarType.tString) {
			throw new OratrInvalidArgumentException(vartypeToStr(ret.type),0);
		}
		ret.str = strip(ret.str);
	} else if(argv.length == 2 ) { 
		ret = argv[0];
		ret = env.eval(ret);
		if(ret.type == Token.VarType.tNumeric) {
			// trim the decimals
			Token precision = argv[1];
			precision = env.eval(precision);
			if(precision.type != Token.VarType.tString) {
				throw new OratrInvalidArgumentException(vartypeToStr(precision.type),1);
			}
			ret.str = format(format("%%%sf",precision.str),ret.d);
		} else if(ret.type == Token.VarType.tString) {
			Token delims = argv[1];
			delims = env.eval(delims);
			if(delims.type != Token.VarType.tString) {
				throw new OratrInvalidArgumentException(vartypeToStr(delims.type),1);
			}
			munch(ret.str,delims.str);
			ret.str = cast(string)ret.str.dup.reverse;
			munch(ret.str,delims.str);
			ret.str = cast(string)ret.str.dup.reverse;
		} else {
			throw new OratrInvalidArgumentException(vartypeToStr(ret.type),0);
		}
	} else {
		throw new OratrArgumentCountException(argv.length,"trim","1-2");
	}
	return ret;
}

Token bi_len(ref Token[] argv, ref Environment env)
{
	Token ret;
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"len","1");
	}
	ret = argv[0];
	ret = env.eval(ret);
	if(ret.type == Token.VarType.tArray) {
		ret = Token(ret.arr.length);
	} else if(ret.type == Token.VarType.tString) {
		ret = Token(ret.str.length);
	} else {
		throw new OratrInvalidArgumentException(vartypeToStr(ret.type),0);
	}
	return ret;
}

Token bi_store(ref Token[] argv, ref Environment env)
{
	Token ret = argv[0];
	ret = env.eval(ret);
	if(ret.type != Token.VarType.tArray) {
		throw new OratrInvalidArgumentException(vartypeToStr(ret.type),0);
	}
	foreach(i,e;argv[1..$]) {
		if(e.type != Token.VarType.tVarname) {
			throw new OratrInvalidArgumentException(vartypeToStr(e.type),i+1);
		}
	}
	if(ret.arr.length < (argv.length-1)) {
		throw new OratrArgumentCountException(argv.length-1,"store",format("0-%s",ret.arr.length));
	}
	uint i;
	for(i=1;i<argv.length;i++) {
		Token val = ret.arr[i-1];
		val = env.eval(val);
		*env.evalVarname(argv[i].str) = val;
	}
	ret.arr = ret.arr[(i-1)..$];
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
			nextIsReference = true;
		} else {
			throw new OratrInvalidArgumentException(vartypeToStr(argv[i].type),i);
		}
	}
	ret.type = Token.VarType.tFunction;
	return ret;
}

Token bi_call(ref Token[] argv, ref Environment env)
{
	Token ret;
	if(!argv.length) throw new OratrArgumentCountException(argv.length,"call","1+");
	Token func = argv[0];
	func = env.eval(func);
	if(func.type != Token.VarType.tFunction) {
		throw new OratrInvalidArgumentException(vartypeToStr(func.type),0);
	}
	if(argv.length-1 != func.arr[0].arr.length) {
		throw new OratrArgumentCountException(argv.length,"call",format("%d",func.arr[0].arr.length));
	}
	env.inscope();
	for(uint i=0;i<func.arr[0].arr.length;i++) {
		if(func.arr[0].arr[i].type == Token.VarType.tRecast) {
			if(argv[i+1].type != Token.VarType.tVarname) {
				throw new OratrInvalidArgumentException(vartypeToStr(argv[i+1].type),i+1);
			}
		}
		Token tmp = argv[i+1];
		tmp = env.eval(tmp);
		env.scopes[$-1][func.arr[0].arr[i].str] = tmp;
	}
	env.inscope();
	parse.parse(func.arr[1].arr,env);
	ret = *env.evalVarname("__return__");
	env.outscope();
	auto results = env.scopes[$-1];
	env.outscope();
	for(uint i=0;i<func.arr[0].arr.length;i++) {
		if(func.arr[0].arr[i].type == Token.VarType.tRecast) {
			*env.evalVarname(argv[i+1].str) = results[func.arr[0].arr[i].str];
		}
	}
	return ret;
}
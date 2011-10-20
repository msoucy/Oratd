import token;
import environment;
import errors;
import parse;
import bi_math;
import std.cstream;
import std.string;

void import_varops(ref Environment env) {
	// Variables
	mixin(AddFunc!("set"));
	mixin(AddFunc!("typeid"));
	// Operations
	mixin(AddFunc!("trim"));
	mixin(AddFunc!("slice"));
	mixin(AddFunc!("len"));
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
	if(argv[1].str[0..$-1] == "") {
		*orig = ret;
	} else {
		Token[] args;
		args ~= *orig;
		args ~= Token(argv[1].str[0..$-1]);
		args[$-1].type = Token.VarType.tOpcode;
		args ~= ret;
		parse.parse(args, env);
		*orig = *env.evalVarname("__return__");
	}
	return ret;
}

Token bi_typeid(ref Token[] argv, ref Environment env) {
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"typeid","1");
	}
	Token ret;
	ret.type = Token.VarType.tTypeID;
	ret.str = vartypeToStr(argv[0].type);
	return ret;
}

Token bi_tell(ref Token[] argv, ref Environment env) {
	assert(0);
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
				ret.str = ret.str[cast(uint)stop.d .. cast(uint)start.d].reverse;
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
			ret.str = ret.str.reverse;
			munch(ret.str,delims.str);
			ret.str = ret.str.reverse;
		} else {
			throw new OratrInvalidArgumentException(vartypeToStr(ret.type),0);
		}
	} else {
		throw new OratrArgumentCountException(argv.length,"trim","1-2");
	}
	return ret;
}

Token bi_len(ref Token[] argv, ref Environment env) {
	Token ret;
	if(argv.length != 1) {
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
import token;
import environment;
import errors;
import bi_vars;
import std.string;

void import_manipulations(ref Environment env)
{
	mixin(AddFunc!"trim");
	mixin(AddFunc!"slice");
	mixin(AddFunc!"len");
	mixin(AddFunc!"store");
	mixin(AddFunc!"map2");
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
	if(!argv.length) throw new OratrArgumentCountException(0,"store","1+");
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

Token bi_map2(ref Token[] argv, ref Environment env)
{
	if(!argv.length) throw new OratrArgumentCountException(0,"map","2"); 
	Token func = argv[0];
	func = env.eval(func);
	if(func.type != Token.VarType.tFunction) {
		throw new OratrInvalidArgumentException(vartypeToStr(func.type),0);
	}
	Token arr = argv[1];
	arr = env.eval(arr);
	if(arr.type != Token.VarType.tArray) {
		throw new OratrInvalidArgumentException(vartypeToStr(arr.type),1);
	}
	Token ret;
	ret.type = Token.VarType.tArray;
	foreach(i,e;arr.arr) {
		auto args = [func,e];
		ret.arr ~= bi_call(args,env);
	}
	return ret;
}

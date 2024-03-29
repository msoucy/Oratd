import token;
import environment;
import errors;
import bi_vars;
import system;
import std.string;
import std.algorithm;
import std.range;

void import_manipulations(ref Environment env)
{
	mixin(AddFunc!"trim");
	mixin(AddFunc!"slice");
	mixin(AddFunc!"len");
	mixin(AddFunc!"store");
	mixin(AddFunc!"map2");
}

class OratrInvalidStrideException : OratrBaseException {
	this( int stride, string file = __FILE__, size_t line = __LINE__ )
    {
        super( format("Invalid array stride %s",stride), file, line );
    }
}

Token bi_slice(ref Token[] argv, ref  Environment env)
{
	Token ret;
	if(argv.length >= 3 && argv.length <= 4) {
		// It's an array or a string
		ret = env.eval(argv[0]);
		Token start = env.eval(argv[1]);
		if(start.type != Token.VarType.tNumeric) {
			throw new OratrInvalidArgumentException(vartypeToStr(start.type),1);
		}
		Token stop = env.eval(argv[2]);
		if(stop.type != Token.VarType.tNumeric) {
			if(stop.type == Token.VarType.tOpcode && stop.str == "@") {
				stop = Token(-1);
			} else {
				throw new OratrInvalidArgumentException(vartypeToStr(stop.type),2);
			}
		}
		if(start.d < 0) {
			throw new OratrOutOfRangeException("",cast(int)start.d);
		}
		int stride = 1;
		if(argv.length == 4) {
			Token strideTok = env.eval(argv[3]);
			if(strideTok.type != Token.VarType.tNumeric) {
				throw new OratrInvalidArgumentException(vartypeToStr(strideTok.type),3);
			}
			stride = cast(int)strideTok.d;
		}
		if(ret.type == Token.VarType.tString) {
			start.d = cast(uint)start.d;
			if(stop.d < 0) stop.d = ret.str.length - stop.d - 1;
			stop.d = cast(uint)stop.d;
			if(stop.d > ret.str.length) {
				throw new OratrOutOfRangeException("string", cast(int)stop.d);
			}
			if(stop.d >= start.d) {
				ret.str = ret.str[cast(uint)start.d .. cast(uint)stop.d];
			} else {
				ret.str = cast(string)(ret.str[cast(uint)stop.d .. cast(uint)start.d].dup.reverse);
			}
			if(stride>0) {
				auto backstr = ret.str;
				ret.str = "";
				foreach(ch;std.range.stride(backstr,stride)) {
					ret.str ~= ch;
				}
			} else if(stride<0) {
				char[] backstr = ret.str.dup.reverse;
				ret.str = "";
				foreach(ch;std.range.stride(backstr,-stride)) {
					ret.str ~= ch;
				}
			} else {
				// This shouldn't happen...
				throw new OratrInvalidStrideException(0);
			}
		} else if(ret.type == Token.VarType.tArray) {
			start.d = cast(uint)start.d;
			if(stop.d < 0) stop.d = ret.arr.length - stop.d - 1;
			stop.d = cast(uint)stop.d;
			if(stop.d > ret.arr.length) {
				throw new OratrOutOfRangeException("", cast(int)stop.d);
			}
			if(stop.d >= start.d) {
				ret.arr = ret.arr[cast(uint)start.d .. cast(uint)stop.d];
			} else {
				ret.arr = ret.arr[cast(uint)stop.d .. cast(uint)start.d].reverse;
			}
			if(stride>0) {
				auto backarr = ret.arr;
				ret.arr.length = 0;
				foreach(ch;std.range.stride(backarr,stride)) {
					ret.arr ~= ch;
				}
			} else if(stride<0) {
				auto backarr = ret.arr.dup.reverse;
				ret.arr.length = 0;
				foreach(ch;std.range.stride(backarr,-stride)) {
					ret.arr ~= ch;
				}
			} else {
				// This shouldn't happen...
				throw new OratrInvalidStrideException(0);
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
		ret = env.eval(argv[0]);
		if(ret.type != Token.VarType.tString) {
			throw new OratrInvalidArgumentException(vartypeToStr(ret.type),0);
		}
		ret.str = strip(ret.str);
	} else if(argv.length == 2 ) { 
		ret = env.eval(argv[0]);
		if(ret.type == Token.VarType.tNumeric) {
			// trim the decimals
			Token precision = env.eval(argv[1]);
			if(precision.type != Token.VarType.tString) {
				throw new OratrInvalidArgumentException(vartypeToStr(precision.type),1);
			}
			// This is needed to properly handle the format string without too many evil tricks
			ret.d = strToDouble(format(format("%%%sf",precision.str),ret.d));
		} else if(ret.type == Token.VarType.tString) {
			Token delims = env.eval(argv[1]);
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
	ret = env.eval(argv[0]);
	if(ret.type == Token.VarType.tArray) {
		ret = Token(ret.arr.length);
	} else if(ret.type == Token.VarType.tString) {
		ret = Token(ret.str.length);
	} else if(ret.type == Token.VarType.tDictionary) {
		ret = Token(ret.arr.length);
	} else {
		throw new OratrInvalidArgumentException(vartypeToStr(ret.type),0);
	}
	return ret;
}

Token bi_store(ref Token[] argv, ref Environment env)
{
	if(!argv.length) throw new OratrArgumentCountException(0,"store","1+");
	Token ret = env.eval(argv[0]);
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
		Token val = env.eval(ret.arr[i-1]);
		*env.evalVarname(argv[i].str) = val;
	}
	ret.arr = ret.arr[(i-1)..$];
	return ret;
}

Token bi_map2(ref Token[] argv, ref Environment env)
{
	if(!argv.length) throw new OratrArgumentCountException(0,"map","2"); 
	Token func = env.eval(argv[0]);
	if(func.type != Token.VarType.tFunction) {
		throw new OratrInvalidArgumentException(vartypeToStr(func.type),0);
	}
	Token arr = env.eval(argv[1]);
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

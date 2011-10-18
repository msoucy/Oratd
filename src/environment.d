import token;
import typedefs;
import errors;
import tokenize;
import std.cstream;

struct Environment {
private:
	typedef Token[string] Scope;
public:
	Token* evalVarname(string src) {
		Token* ret;
		int recastLoc = std.string.indexOf(src,'$');
		int offsetLoc = std.string.lastIndexOf(src,':');
		if(offsetLoc > recastLoc && recastLoc != -1) {
			throw(new OratrParseException(std.string.format("Illegal offset after cast in `%s`", src)));
		}
		string key;
		string newcast;
		string[] offsets;
		if(recastLoc != -1) {
			newcast = src[recastLoc+1..$];
			src= src[0..recastLoc];
		}
		offsetLoc = std.string.indexOf(src,':');
		if(offsetLoc == -1) {
			key = src;
		} else {
			key = src[0..offsetLoc];
			src = src[offsetLoc+1..$];
			offsetLoc = std.string.indexOf(src,':');
			while(offsetLoc != -1) {
				offsets ~= src[0..offsetLoc];
				src = src[offsetLoc+1..$];
				offsetLoc = std.string.indexOf(src,':');
			}
			offsets ~= src;
		}
		
		foreach_reverse(Scope s ; scopes) {
			if(key in s) {
				ret = &s[key];
			}
		}
		if(ret == null) {
			scopes[$-1][cast(string)(key)] = Token();
			ret = &scopes[$-1][cast(string)(key)];
		}
		foreach(string o;offsets) {
			if(ret.type == Token.VarType.tArray) {
				Token off = makeToken(o,din,BraceType.bNone);
				off = eval(off);
				if(off.type != Token.VarType.tNumeric) {
					throw new OratrInvalidOffsetException(o);
				}
				if(ret.arr.length <= cast(uint)off.d) {
					throw new OratrOutOfRangeException(src,cast(uint)off.d);
				} else {
					ret = &ret.arr[cast(uint)off.d];
				}
			} else if(ret.type == Token.VarType.tType) {
				// Things are offset by data name, use the lookup table in env
			} else {
				throw new OratrInvalidOffsetException(vartypeToStr(ret.type));
			}
		}
		return ret;
	}
	ref Token evalRawArray(ref Token src) {
		Token[][] args;
		args.length = 1;
		foreach(tok;src.arr) {
			if(tok.type == Token.VarType.tArrayElementSeperator) {
				args.length += 1;
			} else {
				args[$-1] ~= tok;
			}
		}
		return src;
	}
	Scope[] scopes;
	void init() {
		scopes.length = 1;
		scopes[0]["__scope__"] = Token(1);
	}
	void inscope() {
		scopes.length += 1;
		
	}
	void outscope() {
		if(scopes.length>1) {
			scopes.length -= 1;
		}
	}
	size_t getscope() {
		return scopes.length;
	}
	ref Token eval(ref Token src) {
		Token* ret;
		switch(src.type) {
			case Token.VarType.tVarname: {
				ret = evalVarname(src.str);
				break;
			}
			case Token.VarType.tRawArray: {
				evalRawArray(src);
				break;
			}
			default: {
				ret = &src;
				break;
			}
		}
		return *ret;
	}
}

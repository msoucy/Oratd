import token;
import errors;
import tokenize;
import parse;
import dictionary;
import std.cstream;

template AddFunc(string name, string funcname="bi_"~name) {
	const char[] AddFunc =  "env.scopes[0][\""~name~"\"] = Token(\""~name~"\");" ~
							"env.scopes[0][\""~name~"\"].func = &"~funcname~";" ~
							"env.scopes[0][\""~name~"\"].type = Token.VarType.tBuiltin;"; 
}

struct Environment {
private:
	alias Token[string] Scope;
public:
	Token function(Token)[string][string] conversions;
	enum Flags {
		Break=0x01
	}
	uint flags = 0;
	Token* evalVarname(string src) {
		Token* ret;
		auto recastLoc = std.string.indexOf(src,'$');
		auto offsetLoc = std.string.lastIndexOf(src,':');
		if(offsetLoc > recastLoc && recastLoc != -1) {
			throw new OratrParseException(std.string.format("Illegal offset after cast in `%s`", src));
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
		
		foreach_reverse(ref s ; scopes) {
			if(key in s) {
				ret = &s[key];
				break;
			}
		}
		if(ret == null) {
			scopes[$-1][cast(string)(key)] = Token();
			ret = &scopes[$-1][cast(string)(key)];
		}
		foreach(string o;offsets) {
			if(ret.type == Token.VarType.tArray) {
				Token off = makeToken(o,din,BraceType.None);
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
			} else if(ret.type == Token.VarType.tDictionary) {
				// Things are offset by data name, using the module lookup
				ret = &(Dictionary(*ret)[o]);
			} else if(ret.type == Token.VarType.tString) {
				Token off = makeToken(o,din,BraceType.None);
				off = eval(off);
				if(off.type != Token.VarType.tNumeric) {
					throw new OratrInvalidOffsetException(o);
				}
				if(ret.str.length <= cast(uint)off.d) {
					throw new OratrOutOfRangeException(src,cast(uint)off.d);
				} else {
					ret = new Token(""~ret.str[cast(uint)off.d]);
				}
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
		scopes[0]["__prompt__"] = Token("==> ");
	}
	/// Handles making a new scope
	void inscope() {
		scopes.length += 1;
		scopes[0]["__scope__"].d += 1;
	}
	/// Removes the outermost scope
	void outscope() {
		if(scopes.length>1) {
			scopes.length -= 1;
			scopes[0]["__scope__"].d -= 1;
		}
	}
	/// Gets the number of the scope level
	size_t getscope() {
		return scopes.length;
	}
	/++
		Try to get the "real" value of the passed-in variable
		
		Evaluates Variable types into the value contained in them
		Evaluates raw arrays and executes compound statements
	+/
	ref Token eval(ref Token src) {
		Token* ret;
		with(Token.VarType) switch(src.type) {
			case tCompoundStatement: {
				parse.parse(src.arr, this);
				ret = evalVarname("__return__"); 
				break;
			}
			case tVarname: {
				ret = evalVarname(src.str);
				break;
			}
			case tRawArray: {
				ret = &evalRawArray(src);
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

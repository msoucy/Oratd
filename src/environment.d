import token;
import errors;
import typedefs;
import std.cstream;
import std.stdio;
import std.string;


struct Environment {
private:
	typedef Token[string] Scope;
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
			while(offsetLoc != -1) {
				offsets ~= src[0..offsetLoc];
				src = src[offsetLoc+1..$];
				offsetLoc = std.string.indexOf(src,':');
			}
			offsets ~= src;
		}
		writefln("Cast: `%s`", newcast);
		writefln("Keys: `%s`", key);
		writefln("Offsets:");
		foreach(string o ; offsets) {
			writefln("\t`%s`",o);
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
			// DO THIS NOW
			// preprocess each offset string
			// Evaluate the result
			// Offset ret by that much
			// If it's a function, and there are more offsets, throw an error
		}
		return ret;
	}
public:
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
				break;
			}
			case Token.VarType.tNumeric:
			case Token.VarType.tString:
			case Token.VarType.tOpcode:
			case Token.VarType.tSpecial:
			case Token.VarType.tArray: {
				ret = &src;
				break;
			}
			default: {
				break;
			}
		}
		return *ret;
	}
}

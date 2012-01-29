import token;

struct Dictionary {
	Token* _tok;
	this(ref Token tok) {
		_tok = &tok;
		tok.type = Token.VarType.tDictionary;
	}
	ref Token opIndex(string offset) {
		Token* ret;
		foreach(ref t;_tok.arr) {
			if(t.str == offset) {
				ret = &t.arr[0];
				break;
			}
		}
		if(!ret) {
			_tok.arr ~= Token(offset);
			ret = &_tok.arr[$-1];
			ret.arr ~= Token();
			ret = &ret.arr[0];
		}
		return *ret;
	}
	int opApply(int delegate(ref string, ref Token) dg) {
		auto ret = 0;
		foreach(ref t;_tok.arr) {
			ret = dg(t.str, t.arr[0]);
		}
		return ret;
	}
	int opApply(int delegate(ref size_t, ref string, ref Token) dg) {
		auto ret = 0;
		foreach(ref i, ref t;_tok.arr) {
			ret = dg(i, t.str, t.arr[0]);
		}
		return ret;
	}
	bool opIn(string key) {
		foreach(ref t;_tok.arr) {
			if(t.str == key) return true;
		}
		return false;
	}
	@property size_t length() {
		return _tok.arr.length;
	}
}
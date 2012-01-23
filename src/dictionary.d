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
}
import token;
import dictionary;

struct FunctionWrapper {
	private invariant() {
		// This gets called after every member completes
		// It must pass any asserts.
		assert(_tok.arr.length == 2);
	}
	Token* _tok;
	this(ref Token tok) {
		_tok = &tok;
		if(_tok.type != Token.VarType.tVariadicFunction) _tok.type = Token.VarType.tFunction;
		_tok.arr.length = 2;
		_tok.arr[0].type = Token.VarType.tArray;
	}
	@property {
		ref Token[] argv() {
			return _tok.arr[0].arr;
		}
		ref Token code() {
			return _tok.arr[1];
		}
	}
}
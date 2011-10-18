import token;
import environment;
import bi_basics;
import bi_math;
import bi_stdio;
import bi_vars;

template AddFunc(string name, string funcname="bi_"~name) {
	const char[] AddFunc =  "env.scopes[0][\""~name~"\"] = Token(\""~name~"\");" ~
							"env.scopes[0][\""~name~"\"].func = &"~funcname~";" ~
							"env.scopes[0][\""~name~"\"].type = Token.VarType.tBuiltin;"; 
}

void init_builtins(ref Environment env) {
	// Basic constructs and functions
	mixin(AddFunc!("null"));
	// I/O
	mixin(AddFunc!("echo"));
	mixin(AddFunc!("print"));
	mixin(AddFunc!("echo"));
	mixin(AddFunc!("get"));
	// Variables
	mixin(AddFunc!("set"));
	mixin(AddFunc!("typeid"));
	mixin(AddFunc!("trim"));
	mixin(AddFunc!("slice"));
	// Math
	mixin(AddFunc!("math", "bi_math.bi_math"));
}

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
	mixin(AddFunc!("null"));
	mixin(AddFunc!("echo"));
	mixin(AddFunc!("set"));
	mixin(AddFunc!("print"));
	mixin(AddFunc!("echo"));
	mixin(AddFunc!("get"));
	mixin(AddFunc!("math", "bi_math.bi_math"));
}

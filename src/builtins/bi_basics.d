import token;
import environment;
import errors;

Token bi_null(ref Token[] argv, ref Environment env) {
	Token ret = "__return__";
	ret.type=Token.VarType.tVarname;
	ret = env.eval(ret);
	return ret;
}

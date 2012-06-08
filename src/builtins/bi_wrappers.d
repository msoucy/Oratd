import token;
import environment;

template UnaryWrapperFunc(string funcname, string actualfunc = funcname, Token.VarType accepts) {
	static if(accepts == Token.VarType.tNumeric)
		const char[] UnaryFunc = `Token bi_`~funcname~`(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"`~funcname~`","1");
	}
	if(ret.type != Token.VarType.tNumeric) throw new OratrInvalidArgumentException("`~funcname~`",0);
	Token ret = env.eval(argv[0]);
	ret.d = `~actualfunc~`(ret.d);
	return ret;
}`;
	static if(accepts == Token.VarType.tString)
		const char[] UnaryFunc = `Token bi_`~funcname~`(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"`~funcname~`","1");
	}
	Token ret = env.eval(argv[0]);
	if(ret.type != Token.VarType.tString) throw new OratrInvalidArgumentException("`~funcname~`",0);
	ret.str = `~actualfunc~`(ret.str);
	return ret;
}`;
}
template UnaryWrapperFunc(string funcname, string actualfunc = funcname, string accepts) {
	static if(accepts == Token.VarType.tNumeric)
		const char[] UnaryFunc = `Token bi_`~funcname~`(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"`~funcname~`","1");
	}
	if(ret.type != `~accepts~`) throw new OratrInvalidArgumentException("`~funcname~`",0);
	Token ret = env.eval(argv[0]);
	ret.d = `~actualfunc~`(ret.d);
	return ret;
}`;
}
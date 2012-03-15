import token;
import environment;
import errors;
import std.cstream;
import std.math;
import std.random;
import std.range;

void import_math(ref Environment env) {
	// Math
	mixin(AddFunc!"math");
	mixin(AddFunc!"int");
	mixin(AddFunc!"rand");
	mixin(AddFunc!"frand");
	// Trig - a category of its own <_<
	mixin(AddFunc!"sin");
	mixin(AddFunc!"cos");
	mixin(AddFunc!"tan");
	mixin(AddFunc!"asin");
	mixin(AddFunc!"acos");
	mixin(AddFunc!"atan");
	mixin(AddFunc!"sinh");
	mixin(AddFunc!"cosh");
	mixin(AddFunc!"tanh");
	mixin(AddFunc!"asinh");
	mixin(AddFunc!"acosh");
	mixin(AddFunc!"atanh");
	mixin(AddFunc!"abs");
	// Not quite math, but still useful
	mixin(AddFunc!"ord");
	mixin(AddFunc!"chr");
	
	// Rounding errors cause problems in precision for PI and trig operations
	// Manually specify more precision
	env.scopes[0]["PI"] = Token(PI);
	env.scopes[0]["E"] = Token(E);
	env.scopes[0]["SQRT2"] = Token(SQRT2);
	env.scopes[0]["EPSILON"] = Token(1e-16);
	env.scopes[0]["true"] = Token(1);
	env.scopes[0]["false"] = Token(0);
}

real _bi_numeric_math_solve(real a, string op, real b)
{
	switch(op) {
	case "+":		return a+b;
	case "-":		return a-b;
	case "*":		return a*b;
	case "/":
		if(b!=0) {
			return a/b;
		} else {
			return real.nan;
		}
	case "**":
	case "^^":		return pow(a, b);
	case "%":		return a%b;
	case "<<":		return a * pow(2,b);
	case ">>":		return a * pow(2,-b);
	case "|":		return cast(int)a | cast(int)b;
	case "&":		return cast(int)a & cast(int)b;
	case "^":		return cast(int)a ^ cast(int)b;
	case "<?":		return fmin(a,b);
	case ">?":		return fmax(a,b);
	case ">":		return a>b;
	case "<":		return a<b;
	case "<=":		return a<=b;
	case ">=":		return a>=b;
	case "!=":		return a<>b;
	case "==":		return a==b;
	case "->":		return (!a)||(a&&b);
	case "&&":		return a&&b;
	case "||":		return a||b;
	default:		return real.nan;
	}
}

real _bi_string_math_solve(string a, string op, string b)
{
	switch(op) {
	case ">":		return a>b;
	case "<":		return a<b;
	case "<=":		return a<=b;
	case ">=":		return a>=b;
	case "!=":		return a!=b;
	case "==":		return a==b;
	default:		return real.nan;
	}
}

real _bi_array_math_solve(Token[] a, string op, Token[] b)
{
	switch(op) {
	case "!=": {
		if(a.length != b.length) return true;
		foreach(x,y;lockstep(a,b)) {if(x != y) return true;}
		return false;
	}
	case "==": {
		if(a.length != b.length) return false;
		foreach(x,y;lockstep(a,b)) {if(x != y) return false;}
		return true;
	}
	default:		return real.nan;
	}
}

real _bi_typeid_math_solve(Token a, string op, Token b)
{
	switch(op) {
	case "!=": {
		return a.str != b.str;
	}
	case "==": {
		return a.str == b.str;
	}
	default:		return real.nan;
	}
}

Token _bi_math_solve(Token a, Token op, Token b)
{
	Token ret = 0;
	if(op.str == "~") {
		if(a.type == Token.VarType.tString && b.type == Token.VarType.tString) {
			ret.type = Token.VarType.tString;
			ret.str = a.str ~ b.str;
		} else if(a.type == Token.VarType.tArray) {
			if(a.type == b.type) {
				ret.type = Token.VarType.tArray;
				ret.arr = a.arr ~ b.arr;
			} else {
				ret = a;
				ret.arr ~= b;
			}
		} else if(b.type == Token.VarType.tArray) {
			ret.type = Token.VarType.tArray;
			ret.arr = a ~ b.arr;
		} else if((a.type == Token.VarType.tString && b.type == Token.VarType.tNumeric) ||
				  (a.type == Token.VarType.tNumeric && b.type == Token.VarType.tString)) {
			ret = Token(a.str~b.str);
		} else if(a.type == Token.VarType.tNumeric && b.type == Token.VarType.tNumeric) {
			ret.type = Token.VarType.tArray;
			ret.arr = [a,b];
		} else if(a.type == Token.VarType.tCode && b.type == Token.VarType.tCode) {
			ret.type = Token.VarType.tCode;
			ret.arr = a.arr~b.arr;
		} else if(a.type == Token.VarType.tFunction && b.type == Token.VarType.tFunction) {
			// Check to see if the arguments are equal
			if(a.arr[0] == b.arr[0]) {
				ret = a;
				// Concatenate commands, not tokens
				ret.arr ~= Token(";").withType(Token.VarType.tCommandSeperator)~b.arr[1..$];
			} else {
				throw new OratrMathOperatorException(vartypeToStr(a.type),vartypeToStr(b.type));
			}
		} else if(a.type == Token.VarType.tFunction && b.type == Token.VarType.tCode) {
			// Code can be appended to a function, but not vice versa
			ret = a;
			// Concatenate commands, not tokens
			ret.arr ~= Token(";").withType(Token.VarType.tCommandSeperator)~b.arr;
		} else {
			throw new OratrMathOperatorException(vartypeToStr(a.type),vartypeToStr(b.type));
		}
	} else if(a.type == Token.VarType.tNumeric && b.type == Token.VarType.tNumeric) {
		ret.type = Token.VarType.tNumeric;
		if(Operator_Priority(op.str)) {
			ret.d = _bi_numeric_math_solve(a.d,op.str,b.d);
		} else {
			throw new OratrInvalidMathOperatorException(op.str);
		}
	} else if(a.type == Token.VarType.tTypeID && b.type == Token.VarType.tTypeID) {
		ret.type = Token.VarType.tNumeric;
		if(Operator_Priority(op.str)) {
			ret.d = _bi_typeid_math_solve(a,op.str,b);
		} else {
			throw new OratrInvalidMathOperatorException(op.str);
		}
	} else if((a.type == Token.VarType.tString && b.type == Token.VarType.tString) ||
			  (a.type == Token.VarType.tTypeID && b.type == Token.VarType.tTypeID)) {
		ret = Token(_bi_string_math_solve(a.str,op.str,b.str)).withType(Token.VarType.tNumeric);
	} else if(a.type == Token.VarType.tArray && b.type == Token.VarType.tArray) {
		ret = Token(_bi_array_math_solve(a.arr,op.str,b.arr)).withType(Token.VarType.tNumeric);
	} else {
		
	}
	return ret;
}

int Operator_Priority(string str)
{
	// Based on the C++ order of operations
	switch(str) {
	case "**":
	case "^^":
		return 9;
	case "*":
	case "/":
	case "%":
		return 8;
	case "+":
	case "-":
		return 7;
	case "<<":
	case ">>":
	case ">>>":
		return 6;
	case "<?":
	case ">?":
		return 5;
	case "==":
	case "!=":
	case ">":
	case ">=":
	case "<":
	case "<=":
	case "->":
		return 4;
	case "|":
	case "&":
	case "^":
		return 3;
	case "~":
		return 2;
	case "&&":
	case "||":
		return 1;
	default:
		return 0;
	}
}

Token bi_math(ref Token[] argv, ref Environment env)
{
	Token tmp;
	// Preprocessing to make sure the {2 -3} bug isn't in here
	for(uint i=0;i<argv.length;i++) {
		tmp = env.eval(argv[i]);
		argv[i] = tmp;
		if(tmp.type == Token.VarType.tNumeric && i<(argv.length-1)) {
			tmp = env.eval(argv[++i]);
			if(tmp.type == Token.VarType.tNumeric) {
				argv = argv[0..i]~Token("+").withType(Token.VarType.tOpcode)~argv[i..$];
			}
		}
	}
	
	// Step 1: infix to postfix
	Token[] s;
	Token[] postfix;
	
	foreach(uint i,ref tok;argv) {
		tok = env.eval(tok);
		switch(tok.type) {
		case Token.VarType.tOpcode: {
			while(s.length) {
				int new_prio = Operator_Priority(tok.str);
				int old_prio = Operator_Priority(s[$-1].str);
				if(new_prio > old_prio) {
					// New operator gets pushed directly onto the stack
					break;
				} else {
					// Pop anything off and put it into the postfix list
					postfix ~= s[$-1];
					s.length -= 1;
				}
			}
			s ~= tok;
			break;
		}
		case Token.VarType.tArray:
		case Token.VarType.tCode:
		case Token.VarType.tFunction:
		case Token.VarType.tNumeric:
		case Token.VarType.tTypeID:
		case Token.VarType.tString: {
			postfix ~= tok;
			break;
		}
		default: {
			throw new OratrInvalidArgumentException(token.vartypeToStr(tok.type), i);
		}
		} // switch
	}
	while(s.length) {
		postfix ~= s[$-1];
		s.length -= 1;
	}
	
	// s is now empty, so we'll reuse it
	
	// Step 2: solve the postfix expression
	foreach(uint i,ref tok;postfix) {
		if(tok.type == Token.VarType.tOpcode) {
			// Pop two and do the matching operation
			// They're done backwards...just part of the algorithm
			Token a, b;
			if(s.length > 1) {
				b = s[$-1];
				s.length -= 1;
				a = s[$-1];
				s.length -= 1;
			} else {
				throw new OratrMissingOperandException();
			}
			s ~= _bi_math_solve(a,tok,b);
		} else  {
			s ~= tok;
		}
	}
	return s[$-1];
}

Token bi_int(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"int","1");
	}
	Token ret = Token(lrint(env.eval(argv[0]).d));
	return ret;
}

Token bi_rand(ref Token[] argv, ref Environment env)
{
	Token ret = 0;
	switch(argv.length) {
	case 0: {
		ret.d = uniform!long();
		break;
	}
	case 1: {
		Token high = env.eval(argv[0]);
		if(high.type != Token.VarType.tNumeric) {
			throw new OratrInvalidArgumentException(vartypeToStr(high.type),0);
		}
		// Assume a minimum of 0
		ret.d = uniform(0,cast(uint)high.d);
		break;
	}
	case 2: {
		Token low = env.eval(argv[0]);
		Token high = env.eval(argv[1]);
		if(low.type != Token.VarType.tNumeric) {
			throw new OratrInvalidArgumentException(vartypeToStr(low.type),0);
		}
		if(high.type != Token.VarType.tNumeric) {
			throw new OratrInvalidArgumentException(vartypeToStr(high.type),1);
		}
		ret.d = uniform(cast(uint)low.d,cast(uint)high.d);
		break;
	}
	default: {
		throw new OratrArgumentCountException(argv.length,"rand","0-2");
	}
	}
	return ret;
}

Token bi_frand(ref Token[] argv, ref Environment env)
{
	Token ret = 0;
	switch(argv.length) {
	case 0: {
		ret.d = uniform!long();
		break;
	}
	case 1: {
		Token high = env.eval(argv[0]);
		if(high.type != Token.VarType.tNumeric) {
			throw new OratrInvalidArgumentException(vartypeToStr(high.type),0);
		}
		// Assume a minimum of 0
		ret.d = uniform(0.0,high.d);
		break;
	}
	case 2: {
		Token low = env.eval(argv[0]);
		Token high = env.eval(argv[1]);
		if(low.type != Token.VarType.tNumeric) {
			throw new OratrInvalidArgumentException(vartypeToStr(low.type),0);
		}
		if(high.type != Token.VarType.tNumeric) {
			throw new OratrInvalidArgumentException(vartypeToStr(high.type),1);
		}
		ret.d = uniform(low.d,high.d);
		break;
	}
	default: {
		throw new OratrArgumentCountException(argv.length,"frand","0-2");
	}
	}
	return ret;
}

template MathFunc(string funcname, string actualfunc = funcname) {
	const char[] MathFunc = `Token bi_`~funcname~`(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"`~funcname~`","1");
	}
	Token ret = env.eval(argv[0]);
	if(ret.type != Token.VarType.tNumeric) throw new OratrInvalidArgumentException("`~funcname~`",0);
	ret.d = `~actualfunc~`(ret.d);
	return ret;
}`;
}

// Create "cookie cutter" functions for the basic trig functions
mixin(MathFunc!"sin");
mixin(MathFunc!"cos");
mixin(MathFunc!"tan");
mixin(MathFunc!"asin");
mixin(MathFunc!"acos");
mixin(MathFunc!"atan");
mixin(MathFunc!"sinh");
mixin(MathFunc!"cosh");
mixin(MathFunc!"tanh");
mixin(MathFunc!"asinh");
mixin(MathFunc!"acosh");
mixin(MathFunc!"atanh");
mixin(MathFunc!("abs","fabs"));

Token bi_log(ref Token[] argv, ref Environment env)
{
	Token ret;
	if(argv.length == 1) {
		ret = env.eval(argv[0]);
		ret.d = log(ret.d);
		if(approxEqual(ret.d,0)) {
			ret.d = 0;
		}
	} else if(argv.length == 2) {
		Token base = env.eval(argv[0]);
		ret = env.eval(argv[1]);
		ret.d = log(ret.d)/log(base.d);
		if(approxEqual(ret.d,0)) {
			ret.d = 0;
		}
	} else {
		throw new OratrArgumentCountException(argv.length,"log","1-2");
	}
	return ret;
}

Token bi_chr(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"chr","1");
	}
	Token ret = env.eval(argv[0]);
	if(ret.type != Token.VarType.tNumeric || ret.d != cast(byte)ret.d) {
		throw new OratrInvalidArgumentException(vartypeToStr(ret.type),0);
	}
	ret.str = ""~cast(byte)(ret.d);
	ret.type = Token.VarType.tString;
	return ret;
}

Token bi_ord(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"ord","1");
	}
	Token ret = env.eval(argv[0]);
	if(ret.type != Token.VarType.tString || ret.str.length != 1) {
		throw new OratrInvalidArgumentException(vartypeToStr(ret.type),0);
	}
	ret.d = cast(real)(ret.str[0]);
	ret.type = Token.VarType.tNumeric;
	return ret;
}
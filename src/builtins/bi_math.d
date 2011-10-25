import token;
import environment;
import errors;
import std.cstream;
import std.math;
import std.random;

void import_math(ref Environment env) {
	// Math
	mixin(AddFunc!("math"));
	mixin(AddFunc!("rand"));
	mixin(AddFunc!("frand"));
	// Trig - a category of its own <_<
	mixin(AddFunc!("sin"));
	mixin(AddFunc!("cos"));
	mixin(AddFunc!("tan"));
	mixin(AddFunc!("asin"));
	mixin(AddFunc!("acos"));
	mixin(AddFunc!("atan"));
	mixin(AddFunc!("sinh"));
	mixin(AddFunc!("cosh"));
	mixin(AddFunc!("tanh"));
	mixin(AddFunc!("asinh"));
	mixin(AddFunc!("acosh"));
	mixin(AddFunc!("atanh"));
	mixin(AddFunc!("abs"));
	
	// Rounding errors cause problems in precision for PI and trig operations
	// Manually specify more precision
	env.scopes[0]["PI"] = Token().withType(Token.VarType.tNumeric).withPreciseNumeric(PI);
	env.scopes[0]["E"] = Token().withType(Token.VarType.tNumeric).withPreciseNumeric(E);
	env.scopes[0]["SQRT2"] = Token().withType(Token.VarType.tNumeric).withPreciseNumeric(SQRT2);
}

real _bi_numeric_math_solve(real a, string op, real b)
{
	switch(op) {
	case "+":
		return a+b;
	case "-":
		return a-b;
	case "*":
		return a*b;
	case "/":
		if(b!=0) {
			return a/b;
		} else {
			return real.nan;
		}
	case "**":
	case "^^":
		return pow(a, b);
	case "%":
		return remainder(a,b);
	case "<<":
		return a * pow(2,b);
	case ">>":
		return a * pow(2,-b);
	case ">>>":
		return a * pow(2,-b);
	case "|":
		return cast(int)a | cast(int)b;
	case "&":
		return cast(int)a & cast(int)b;
	case "^":
		return cast(int)a ^ cast(int)b;
	case "<?":
		return fmin(a,b);
	case ">?":
		return fmax(a,b);
	default:
		return real.nan;
	}
}

Token _bi_math_solve(Token a, Token op, Token b)
{
	Token ret = 0;
	if(a.type != b.type) {
		throw new OratrMathOperatorException(vartypeToStr(a.type),vartypeToStr(b.type));
	}
	if(a.type == Token.VarType.tNumeric) {
		ret.type = Token.VarType.tNumeric;
		if(Operator_Priority(op.str)) {
			ret.d = _bi_numeric_math_solve(a.d,op.str,b.d);
		} else {
			// It's possibly a user defined overload?
		}
	} else if(op.str == "~") {
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
		}
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
		return 8;
	case "*":
	case "/":
	case "%":
		return 7;
	case "+":
	case "-":
		return 6;
	case "<<":
	case ">>":
	case ">>>":
		return 5;
	case "<?":
	case ">?":
		return 4;
	case "==":
	case "!=":
	case ">":
	case ">=":
	case "<":
	case "<=":
		return 3;
	case "|":
	case "&":
	case "^":
		return 2;
	case "~":
		return 1;
	default:
		return 0;
	}
}

Token bi_math(ref Token[] argv, ref Environment env)
{
	Token tmp;
	// Preprocessing to make sure the {2 -3} bug isn't in here
	static if(0) {
		for(uint i=1;i<argv.length;i++) {
			tmp = argv[i];
			env.eval(tmp);
			if(tmp.type == Token.VarType.tNumeric && i<(argv.length-1)) {
				tmp = argv[++i];
				env.eval(tmp);
				if(tmp.type == Token.VarType.tNumeric) {
					Token op = "+";
					op.type = Token.VarType.tOpcode;
					argv = argv[0..i]~op~argv[i+1..$];
				}
			}
		}
	}
	
	// Step 1: infix to postfix
	Token[] s;
	Token[] postfix;
	
	for(uint i=0;i<argv.length;i++) {
		argv[i] = env.eval(argv[i]);
		switch(argv[i].type) {
		case Token.VarType.tOpcode: {
			while(s.length) {
				int new_prio = Operator_Priority(argv[i].str);
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
			s ~= argv[i];
			break;
		}
		case Token.VarType.tNumeric:
		case Token.VarType.tString: {
			postfix ~= argv[i];
			break;
		}
		default: {
			throw new OratrInvalidArgumentException(token.vartypeToStr(argv[i].type), i);
		}
		};
	}
	while(s.length) {
		postfix ~= s[$-1];
		s.length -= 1;
	}
	
	// s is now empty, so we'll reuse it
	
	// Step 2: solve the postfix expression
	for(uint i=0;i<postfix.length;i++) {
		switch(postfix[i].type) {
		case Token.VarType.tOpcode: {
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
			s ~= _bi_math_solve(a,postfix[i],b);
			break;
		}
		case Token.VarType.tNumeric:
		case Token.VarType.tString: {
			s ~= postfix[i];
			break;
		}
		default: {
			// It should never reach this, but just in case...
			throw new OratrInvalidArgumentException(token.vartypeToStr(argv[i].type), i);
		}
		};
	}
	
	return s[$-1];
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
		Token high = argv[0];
		high = env.eval(high);
		if(high.type != Token.VarType.tNumeric) {
			throw new OratrInvalidArgumentException(vartypeToStr(high.type),0);
		}
		// Assume a minimum of 0
		ret.d = uniform(0,cast(uint)high.d);
		break;
	}
	case 2: {
		Token low = argv[0];
		Token high = argv[1];
		low = env.eval(low);
		high = env.eval(high);
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
		Token high = argv[0];
		high = env.eval(high);
		if(high.type != Token.VarType.tNumeric) {
			throw new OratrInvalidArgumentException(vartypeToStr(high.type),0);
		}
		// Assume a minimum of 0
		ret.d = uniform(0.0,high.d);
		break;
	}
	case 2: {
		Token low = argv[0];
		Token high = argv[1];
		low = env.eval(low);
		high = env.eval(high);
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

Token bi_sin(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"sin","1");
	}
	Token ret = argv[0];
	ret = env.eval(ret);
	ret.d = sin(ret.d);
	if(approxEqual(ret.d,0)) {
		ret.d = 0;
	}
	return ret;
}

Token bi_cos(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"cos","1");
	}
	Token ret = argv[0];
	ret = env.eval(ret);
	ret.d = cos(ret.d);
	if(approxEqual(ret.d,0)) {
		ret.d = 0;
	}
	return ret;
}

Token bi_tan(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"sin","1");
	}
	Token ret = argv[0];
	ret = env.eval(ret);
	ret.d = tan(ret.d);
	if(approxEqual(ret.d,0)) {
		ret.d = 0;
	}
	return ret;
}

Token bi_asin(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"sin","1");
	}
	Token ret = argv[0];
	ret = env.eval(ret);
	ret.d = asin(ret.d);
	if(approxEqual(ret.d,0)) {
		ret.d = 0;
	}
	return ret;
}

Token bi_acos(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"sin","1");
	}
	Token ret = argv[0];
	ret = env.eval(ret);
	ret.d = acos(ret.d);
	if(approxEqual(ret.d,0)) {
		ret.d = 0;
	}
	return ret;
}

Token bi_atan(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"sin","1");
	}
	Token ret = argv[0];
	ret = env.eval(ret);
	ret.d = atan(ret.d);
	if(approxEqual(ret.d,0)) {
		ret.d = 0;
	}
	return ret;
}

Token bi_sinh(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"sin","1");
	}
	Token ret = argv[0];
	ret = env.eval(ret);
	ret.d = sinh(ret.d);
	if(approxEqual(ret.d,0)) {
		ret.d = 0;
	}
	return ret;
}

Token bi_cosh(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"cos","1");
	}
	Token ret = argv[0];
	ret = env.eval(ret);
	ret.d = cosh(ret.d);
	if(approxEqual(ret.d,0)) {
		ret.d = 0;
	}
	return ret;
}

Token bi_tanh(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"sin","1");
	}
	Token ret = argv[0];
	ret = env.eval(ret);
	ret.d = tanh(ret.d);
	if(approxEqual(ret.d,0)) {
		ret.d = 0;
	}
	return ret;
}

Token bi_asinh(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"sin","1");
	}
	Token ret = argv[0];
	ret = env.eval(ret);
	ret.d = asinh(ret.d);
	if(approxEqual(ret.d,0)) {
		ret.d = 0;
	}
	return ret;
}

Token bi_acosh(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"sin","1");
	}
	Token ret = argv[0];
	ret = env.eval(ret);
	ret.d = acosh(ret.d);
	if(approxEqual(ret.d,0)) {
		ret.d = 0;
	}
	return ret;
}

Token bi_atanh(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"sin","1");
	}
	Token ret = argv[0];
	ret = env.eval(ret);
	ret.d = atanh(ret.d);
	if(approxEqual(ret.d,0)) {
		ret.d = 0;
	}
	return ret;
}

Token bi_log(ref Token[] argv, ref Environment env)
{
	Token ret;
	if(argv.length == 1) {
		ret = argv[0];
		ret = env.eval(ret);
		ret.d = log(ret.d);
		if(approxEqual(ret.d,0)) {
			ret.d = 0;
		}
	} else if(argv.length == 2) {
		Token base = argv[0];
		base = env.eval(base);
		ret = argv[1];
		ret = env.eval(ret);
		ret.d = log(ret.d)/log(base.d);
		if(approxEqual(ret.d,0)) {
			ret.d = 0;
		}
	} else {
		throw new OratrArgumentCountException(argv.length,"sin","1");
	}
	return ret;
}

Token bi_abs(ref Token[] argv, ref Environment env)
{
	if(argv.length != 1) {
		throw new OratrArgumentCountException(argv.length,"sin","1");
	}
	Token ret = argv[0];
	ret = env.eval(ret);
	ret.d = fabs(ret.d);
	if(approxEqual(ret.d,0)) {
		ret.d = 0;
	}
	return ret;
}

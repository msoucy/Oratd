import token;
import environment;
import errors;
import std.string;
import std.cstream;
import std.math;

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
		return pow(a, b);
	case "^^":
		return a ^^ b;
	case "%":
		return a%b;
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
		return 7;
	case "*":
	case "/":
	case "%":
		return 6;
	case "+":
	case "-":
		return 5;
	case "<<":
	case ">>":
	case ">>>":
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
			break;
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
			break;
		}
		};
	}
	
	return s[$-1];
}

Token bi_trim(ref Token[] argv, ref  Environment env)
{
	// Trim a number to a precision, or a string's leading/trailing signs (default whitespace)
	Token ret;
	if(argv.length == 1) {
		ret = argv[0];
		ret = env.eval(ret);
		if(ret.type != Token.VarType.tString) {
			throw new OratrInvalidArgumentException(vartypeToStr(ret.type),0);
		}
		ret.str = strip(ret.str);
	} else if(argv.length == 2 ) {
		// It has to be a number - trim the decimals
		ret = argv[0];
		ret = env.eval(ret);
		if(ret.type == Token.VarType.tNumeric) {
			Token precision = argv[1];
			precision = env.eval(precision);
			if(precision.type != Token.VarType.tString) {
				throw new OratrInvalidArgumentException(vartypeToStr(precision.type),1);
			}
			ret.str = format(format("%%%sf",precision.str),ret.d);
		} else if(ret.type == Token.VarType.tString) {
			Token delims = argv[1];
			delims = env.eval(delims);
			if(delims.type != Token.VarType.tString) {
				throw new OratrInvalidArgumentException(vartypeToStr(delims.type),1);
			}
			while(ret.str.length && inPattern(ret.str[0],delims.str)) {
				ret.str = ret.str[1..$];
			}
			while(ret.str.length && inPattern(ret.str[$-1],delims.str)) {
				ret.str = ret.str[0..$-1];
			}
		} else {
			throw new OratrInvalidArgumentException(vartypeToStr(ret.type),0);
		}
	} else {
		throw new OratrArgumentCountException(argv.length,"trim","1-2");
	}
	return ret;
}

Token bi_slice(ref Token[] argv, ref  Environment env)
{
	Token ret;
	if(argv.length == 3) {
		// It's an array or a string
		ret = argv[0];
		ret = env.eval(ret);
		Token start = argv[1];
		start = env.eval(start);
		if(start.type != Token.VarType.tNumeric) {
			throw new OratrInvalidArgumentException(vartypeToStr(start.type),1);
		}
		Token stop = argv[2];
		stop = env.eval(stop);
		if(stop.type != Token.VarType.tNumeric) {
			throw new OratrInvalidArgumentException(vartypeToStr(stop.type),2);
		}
		if(start.d < 0) {
			throw new OratrOutOfRangeException("",cast(int)start.d);
		}
		start.d = cast(uint)start.d;
		stop.d = cast(uint)stop.d;
		if(ret.type == Token.VarType.tString) {
			if(stop.d >= ret.str.length) {
				throw new OratrOutOfRangeException("string", cast(int)stop.d);
			}
			if(stop.d >= start.d) {
				ret.str = ret.str[cast(uint)start.d .. cast(uint)stop.d];
			} else {
				ret.str = ret.str[cast(uint)stop.d .. cast(uint)start.d].reverse;
			}
		} else if(ret.type == Token.VarType.tArray) {
			if(stop.d >= ret.arr.length) {
				throw new OratrOutOfRangeException("", cast(int)stop.d);
			}
			if(stop.d >= start.d) {
				ret.arr = ret.arr[cast(uint)start.d .. cast(uint)stop.d];
			} else {
				ret.arr = ret.arr[cast(uint)stop.d .. cast(uint)start.d].reverse;
			}
		} else {
			throw new OratrInvalidArgumentException(vartypeToStr(ret.type),0);
		}
	} else {
		// Expand for start...stop...step?
		throw new OratrArgumentCountException(argv.length,"slice","3-4");
	}
	return ret;
}
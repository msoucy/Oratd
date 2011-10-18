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
	case "%":
		// math.modf requires the divisor to be a reference
		return modf(a, b);
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
	if(str == "**") {
		// Exponentiation
		return 7;
	} else if(str == "*" || str == "/" || str == "%") {
		// Multiplication operators
		return 6;
	} else if(str == "+" || str == "-") {
		// Addition/subtraction
		return 5;
	} else if(str == "<<" || str == ">>" || str == ">>>") {
		// Shift operators - I feel like those should be with the mults, but C priorities says otherwise
		return 4;
	} else if(str == "==" || str == "!=" || str == ">" || str == ">=" || str == "<" || str == "<=") {
		// (in)equality operators
		return 3;
	} else if(str == "|" || str == "&" || str == "^") {
		// Bitwise operators
		return 2;
	} else if(str == "~") {
		// Concatenation operator - lowest so you can concatenate expressions
		return 1;
	} else {
		// It's not a valid operator - sorry, no custom operators
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

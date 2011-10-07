import token;
import environment;
import errors;
import std.string;

int Operator_Priority(string str)
{
	// Based on the C++ order of operations
	if(str == "**") {
		return 6;
	} else if(str == "*" || str == "/" || str == "%") {
		return 5;
	} else if(str == "+" || str == "-") {
		return 4;
	} else if(str == "<<" || str == ">>") {
		return 3;
	} else if(str == "==" || str == "!=" || str == ">" || str == ">=" || str == "<" || str == "<=") {
		return 2;
	} else if(str == "|" || str == "&" || str == "^") {
		return 1;
	} else {
		// Any user-created operators get a 0 priority, below all others
		return 0;
	}
}

Token bi_math(ref Token[] argv, ref Environment env)
{
	Token tmp;
	/+
	// Preprocessing to make sure the {2 -3} bug isn't in here
	for(uint i=1;i<argv.length;i++) {
		tmp = argv[i];
		env.verify(tmp);
		if(tmp.type == tNumeric && i<(argv.length-1)) {
			tmp = argv[++i];
			env.verify(tmp);
			if(tmp.type == Token.VarType.tNumeric) {
				Token op = "+";
				op.type = tOpcode;
				argv.insert(argv.begin()+i,op);
			}
		}
	}
	+/
	
	// Step 1: infix to postfix
	Token[] s;
	Token[] postfix;
	
	for(uint i=1;i<argv.length;i++) {
		env.eval(argv[i]);
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
			throw new OratrArgumentException(format("Invalid argument type: %s", token.vartypeToStr(argv[i].type)));
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
			//Pop two and do the matching operation
			// They're done backwards...just part of the algorithm
			Token a, b;
			b = s[$-1];
			s.length -= 1;
			a = s[$-1];
			s.length -= 1;
			//s ~= _bi_math_solve(a,postfix[i],b);
			break;
		}
		case Token.VarType.tNumeric:
		case Token.VarType.tString: {
			s ~= postfix[i];
			break;
		}
		default: {
			// It should never reach this, but just in case...
			throw new OratrArgumentException(format("Invalid argument type: %s", token.vartypeToStr(argv[i].type)));
			break;
		}
		};
	}
	
	return s[$-1];
}

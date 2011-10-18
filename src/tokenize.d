import token;
import environment;
import errors;
import system;
import bi_basics;
import std.cstream;
import std.string;
import std.regex;

// Regexes that handle the basic tokens
string doubleQuotedStringRegex = "(\"[^\"\\\\]*(?:\\\\.[^\"\\\\]*)*\")";
string singleQuotedStringRegex = "(\'[^\'\\\\]*(?:\\\\.[^\'\\\\]*)*\')";
string singleQuotedRawStringRegex = "(`.*?`)";
string simpleStringRegex = "(`.*?`)";
string hexRegex = "((\\+|-)?0[xX][0-9A-Fa-f]*(\\.[0-9A-Fa-f]*)?)";
string binaryRegex = "([\\+\\-]?0[bB][01]*(\\.[01]*)?)";
string octalRegex = "([\\+\\-]?0[oO][0-7]*(\\.[0-7]*)?)";
string decimalRegex = "([\\+\\-]?[0-9]*(\\.[0-9]*)?)";
string opcodeRegex = "([\\+\\-\\*/\\\\=\\^&!%~\\|<>]+)";
string opcodeList = "+\\*/\\=^&!%~|<>";
string varNameRegex = "((?:[a-zA-Z_][a-zA-Z0-9_]*))";
//string simpleVarNameRegex = "((?:[a-zA-Z_][a-zA-Z0-9_]*))";
//string varNameRegex = "((?:[a-zA-Z_][a-zA-Z0-9_]*(:[a-zA-Z_][a-zA-Z0-9_]*)*(\\$[a-zA-Z_][a-zA-Z0-9_]*)?))";
string varNameList = "a-zA-Z_";
enum BraceType {bNone, bParen, bBracket, bBrace}

string evalStr(string str) {
	string s = "";
	size_t i;
	for(i=0;i<str.length;i++) {
		if(str[i]=='\\') {
			if(i+1 != str.length) {
				switch(str[++i]) {
				case 'b':
					// Backspace
					s = s[0..$-1];
					break;
				case 'n':
					// Newline
					s ~= '\n';
					break;
				case 't':
					// Tab
					s ~= '\t';
					break;
				case 'r':
					// Carriage return
					s ~= '\r';
					break;
				case '\\':
					// Backslash
					s ~= '\\';
					break;
				case '"':
					// Doublequote
					s ~= '"';
					break;
				case '\'':
					// Singlequote
					s ~= '\'';
					break;
				default:
					throw new OratrParseException(format("Invalid escape sequence: \\%s",str[i]));
				}
			} else {
				s ~= '\\';
			}
		} else {
			s ~= str[i];
		}
	}
	return s;
}

string unevalStr(string str) {
	string s = "";
	size_t i;
	for(i=0;i<str.length;i++) {
		switch(str[++i]) {
		case '\b':
			// Backspace
			s ~= "\\b";
			break;
		case '\n':
			// Newline
			s ~= "\\n";
			break;
		case '\t':
			// Tab
			s ~= "\\t";
			break;
		case '\r':
			// Carriage return
			s ~= "\\r";
			break;
		case '\\':
			// Backslash
			s ~= "\\\\";
			break;
		case '"':
			// Doublequote
			s ~= "\\\"";
			break;
		case '\'':
			// Singlequote
			s ~= "\\\'";
			break;
		default:
			throw new OratrParseException(format("Invalid escape sequence: \\%s",str[i]));
		}
	}
	return s;
}


real getNumeric(ref string src) {
	string s;
	real ret;
	if(src.length>2 && src[0] == '0' && (
			toLower(src)[1] == 'x' ||
			toLower(src)[1] == 'b' ||
			toLower(src)[1] == 'o'
		)) {
		switch(toLower(src)[1]) {
		case 'x':
			s = cast(string)(match(src,hexRegex).captures[0]);
			ret = strToDouble(s[2..$],16);
			break;
		case 'b':
			s = cast(string)(match(src,binaryRegex).captures[0]);
			ret = strToDouble(s[2..$],2);
			break;
		case 'o':
			s = cast(string)(match(src,octalRegex).captures[0]);
			ret = strToDouble(s[2..$],8);
			break;
		default:
			s = cast(string)(match(src,decimalRegex).captures[0]);
			ret = strToDouble(s[2..$],10);
			break;
		}
	} else {
		s = cast(string)(match(src,decimalRegex).captures[0]);
		ret = strToDouble(s,10);
	}
	src = src[s.length..$];
	return ret;
}

string getNextLine(InputStream source) {
	string str = "";
	str = cast(string)(source.readLine());
	if(source.eof()) {
		throw new OratrParseException("End of Input Stream");
	}
	return str;
}

Token makeToken(ref string src, InputStream source, BraceType escapeFrom=BraceType.bNone) {
	Token ret;
	src = strip(src);
	if(src[0] == '#') {
		// # ends the line with a comment
		// #[ and #] are block comments
		if(src.length>1 && src[1] == '[') {
			sizediff_t pos = indexOf(src,"]#");
			while(pos == -1) {
				src ~= getNextLine(source);
				pos = indexOf(src,"]#");
			}
			src = src[pos+2..$];
		}  else {
			ret.str = "";
			ret.type = Token.VarType.tNone;
			src = "";
		}
	} else if(src[0] == ';') {
		// ; seperates sequences of commands
		ret.str = "";
		ret.type = Token.VarType.tCommandSeperator;
		src = src[1..$];
	} else if(src[0] == ':') {
		// : seperates array offsets
		ret.str = ":";
		ret.type = Token.VarType.tVarOffsetSeperator;
		src = src[1..$];
	} else if(src[0] == '$') {
		// $ seperates type casts
		ret.str = "$";
		ret.type = Token.VarType.tRecast;
		src = src[1..$];
	} else if(src[0] == ',') {
		// , seperates array values
		ret.str = ",";
		ret.type = Token.VarType.tArrayElementSeperator;
		src = src[1..$];
	} else if(src[0] == '`') {
		auto m = match(src,singleQuotedRawStringRegex);
		if(!m.captures.length) {
			throw new OratrParseException("Mismatched `");
		}
		string s = cast(string)(m.captures[0]);
		ret.str = s[1..$-1];
		ret.type = Token.VarType.tString;
		src = src[s.length..$];
	} else if(src[0] == '\'') {
		auto m = match(src,singleQuotedStringRegex);
		if(!m.captures.length) {
			throw new OratrParseException("Mismatched '");
		}
		string s = cast(string)(m.captures[0]);
		ret.str = evalStr(s)[1..$-1];
		ret.type = Token.VarType.tString;
		src = src[s.length..$];
	} else if(src[0] == '"') {
		auto m = match(src,doubleQuotedStringRegex);
		if(!m.captures.length) {
			throw new OratrParseException("Mismatched \"");
		}
		string s = cast(string)(m.captures[0]);
		ret.str = evalStr(s)[1..$-1];
		ret.type = Token.VarType.tString;
		src = src[s.length..$];
	} else if(src[0] == '-') {
		if(src.length == 1 || inPattern(src[1],opcodeRegex)) {
			// It's an operator???
			string s = cast(string)(match(src,opcodeRegex).captures[0]);
			ret.str = s;
			ret.type = Token.VarType.tOpcode;
			src = src[s.length..$];
		} else {
			// It's a number???
			src = src[1..$];
			ret.d = -getNumeric(src);
			ret.type = Token.VarType.tNumeric;
		}
	} else if(inPattern(src[0],opcodeList)) {
		string s = cast(string)(match(src,opcodeRegex).captures[0]);
		ret.str = s;
		ret.type = Token.VarType.tOpcode;
		src = src[s.length..$];
	} else if(inPattern(src[0],"0-9.")) {
		ret.d = getNumeric(src);
		ret.type = Token.VarType.tNumeric;
	} else if(src[0] == '(') {
		// Recursion all up in this code
		src = src[1..$];
		ret.arr = tokenize(src, source, BraceType.bParen);
		ret.type = Token.VarType.tArgumentList;
	} else if(src[0] == '[') {
		// Recursion all up in this code
		src = src[1..$];
		ret.arr = tokenize(src, source, BraceType.bBrace);
		ret.type = Token.VarType.tRawArray;
	} else if(src[0] == '{') {
		// Recursion all up in this code
		src = src[1..$];
		ret.arr = tokenize(src, source, BraceType.bBracket);
		ret.type = Token.VarType.tCode;
	} else if(src[0] == ')') {
		if(escapeFrom == BraceType.bParen) {
			// Recursive return
			ret.type = Token.VarType.tClosingParen;
			src = src[1..$];
		} else {
			throw new OratrParseException("Mismatched )");
		}
	} else if(src[0] == ']') {
		if(escapeFrom == BraceType.bBrace) {
			// Recursive return
			ret.type = Token.VarType.tClosingBrace;
			src = src[1..$];
		} else {
			throw new OratrParseException("Mismatched ]");
		}
	} else if(src[0] == '}') {
		if(escapeFrom == BraceType.bBracket) {
			// Recursive return
			ret.type = Token.VarType.tClosingBracket;
			src = src[1..$];
		} else {
			throw new OratrParseException("Mismatched }");
		}
	} else if(inPattern(src[0],varNameList)) {
		ret.str = cast(string)(match(src,varNameRegex).captures[0]);
		ret.type = Token.VarType.tVarname;
		src = src[ret.str.length..$];
	}
	return ret;
}

Token[] tokenize(ref string src, InputStream source, BraceType escapeFrom=BraceType.bNone) {
	Token[] ret;
	Token tmp;
	
	// Trim leading whitespace
	src = strip(src);
	
	if(!src.length) {
		tmp.str = "null";
		tmp.type = Token.VarType.tBuiltin;
		tmp.func = &bi_null;
		ret ~= tmp;
		return ret;
	}
	
	do {
		tmp = makeToken(src,source,escapeFrom);
		switch(tmp.type){
			case Token.VarType.tClosingParen:
			case Token.VarType.tClosingBrace:
			case Token.VarType.tClosingBracket: {
				// Just return the expression
				return ret;
			}
			default: {
				ret ~= tmp;
				break;
			}
		}
		if(!src.length && escapeFrom != BraceType.bNone) {
			dout.writef("> ");
			src ~= getNextLine(source);
		}
	} while(src.length);
	return ret;
}

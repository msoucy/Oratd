import token;
import environment;
import errors;
import system;
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

char[] preprocess(string str, InputStream source = din, BraceType escapeFrom=BraceType.bNone) {
	char[] ret;
	BraceType[] delims;
	bool flag = false;
	size_t charpos;
	while(str.length) {
		version(linux) {
			if(str[$-1]=='\r') {
				str = str[0..$-1];
			}
		}
		while(str.length) {
			switch(str[0]) {
			case ';':
				flag=true;
				ret ~= str[0];
				str = str[1..$];
				break;
			case '{':
				delims ~= BraceType.bBrace;
				ret ~= str[0];
				str = str[1..$];
				break;
			case '(':
				delims ~= BraceType.bParen;
				ret ~= str[0];
				str = str[1..$];
				break;
			case '[':
				delims ~= BraceType.bBracket;
				ret ~= str[0];
				str = str[1..$];
				break;
			case '}':
				if(delims.length) {
					if(delims[$-1] != BraceType.bBrace) {
						throw new OratrParseException(std.string.format(
								"Mismatched } in position %d", charpos
								));
					} else {
						delims.length -= 1;
					}
				} else {
					if(escapeFrom == BraceType.bBrace) {
						//
					} else {
						throw new OratrParseException(std.string.format(
								"Mismatched } in position %d", charpos
								));
					}
				}
				ret ~= str[0];
				str = str[1..$];
				break;
			case ']':
				if(delims.length) {
					if(delims[$-1] != BraceType.bBracket) {
						throw new OratrParseException(std.string.format(
								"Mismatched ] in position %d", charpos
								));
					} else {
						delims.length -= 1;
					}
				} else {
					throw new OratrParseException(std.string.format(
							"Mismatched ] in position %d", charpos
							));
				}
				ret ~= str[0];
				str = str[1..$];
				break;
			case ')':
				dout.writef("Delim size: %d\n", delims.length);
				if(delims.length) {
					if(delims[$-1] != BraceType.bParen) {
						throw new OratrParseException(std.string.format(
								"Mismatched ) in position %d", charpos
								));
					} else {
						delims.length -= 1;
						ret ~= str[0];
						str = str[1..$];
					}
				} else if(escapeFrom != BraceType.bParen) {
					ret~=str[0];
					str = str[1..$];
					return ret;
				} else {
					throw new OratrParseException(std.string.format(
							"Leading ) in position %d", charpos
							));
				}
				break;
			case '"':
			case '\'':
				uint i=0;
				ret ~= str[0];
				for(i=1;i<str.length;i++) {
					if(str[i] == '\\') {
						ret ~= '\\';
						if(i+1 != str.length) {
							if(str[i]==str[0]) {
								i++;
								str ~= str[0];
							}
						} else {
							throw new OratrParseException(std.string.format(
									"Open %c in position %d", str[0], charpos+i
									));
						}
					} else if(str[i]==str[0]) {
						ret ~= str[0];
						break;
					} else {
						ret ~= str[i];
					}
				}
				if(ret[$-1] != str[0]) {
					throw new OratrParseException(std.string.format(
							"Open %s in position %d", str[0], charpos+i
							));
				}
				if(i!=str.length) {
					str = str[i+1..$];
				} else {
					str = "";
				}
				charpos += i-1;
				break;
			case '`':
				uint i=0;
				ret ~= str[0];
				for(i=1;i<str.length;i++) {
					if(str[i]==str[0]) {
						ret ~= str[0];
						break;
					} else {
						ret ~= str[i];
					}
				}
				if(i==str.length) {
					throw new OratrParseException(std.string.format(
							"Open %s in position %d", str[0], charpos+i
							));
				}
				if(i!=str.length) {
					str = str[i+1..$];
				} else {
					str = "";
				}
				charpos += i-1;
				break;
			case '#':
				str.length = 0;
				break;
			default:
				ret ~= str[0];
				str = str[1..$];
				break;
			}
			charpos++;
		}
		if(delims.length) {
			version(linux) {
				if(str.length && str[$-1]=='\r') {
					str = str[0..$-1];
				}
			}
			char[] buf;
			do {
				buf = std.string.strip(source.readLine());
			} while(!buf.length);
			str ~= buf;
		}
	}
	return ret;
}

Token makeToken(ref string src, InputStream source, BraceType escapeFrom=BraceType.bNone) {
	Token ret;
	src = strip(src);
	if(src[0] == ';') {
		// ; seperates sequences of commands
		ret.str = "";
		ret.type = Token.VarType.tCommandSeperator;
		src = src[1..$];
	} else if(src[0] == ':') {
		// : seperates array offsets
		ret.str = ":";
		ret.type = Token.VarType.tVarOffsetSeperator;
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
		ret.str = s;
		ret.type = Token.VarType.tString;
		src = src[s.length..$];
	} else if(src[0] == '\'') {
		auto m = match(src,singleQuotedStringRegex);
		if(!m.captures.length) {
			throw new OratrParseException("Mismatched '");
		}
		string s = cast(string)(m.captures[0]);
		ret.str = evalStr(s);
		ret.type = Token.VarType.tString;
		src = src[s.length..$];
	} else if(src[0] == '"') {
		auto m = match(src,doubleQuotedStringRegex);
		if(!m.captures.length) {
			throw new OratrParseException("Mismatched \"");
		}
		string s = cast(string)(m.captures[0]);
		ret.str = evalStr(s);
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
			string s;
			if(src.length>2 && src[0] == '0' && (
					toLower(src)[1] == 'x' ||
					toLower(src)[1] == 'b' ||
					toLower(src)[1] == 'o'
				)) {
				switch(toLower(src)[1]) {
				case 'x':
					s = cast(string)(match(src,hexRegex).captures[0]);
					ret.d = strToDouble(s[2..$],16);
					break;
				case 'b':
					s = cast(string)(match(src,binaryRegex).captures[0]);
					ret.d = strToDouble(s[2..$],2);
					break;
				case 'o':
					s = cast(string)(match(src,octalRegex).captures[0]);
					ret.d = strToDouble(s[2..$],8);
					break;
				default:
					s = cast(string)(match(src,decimalRegex).captures[0]);
					ret.d = strToDouble(s[2..$],10);
					break;
				}
			} else {
				s = cast(string)(match(src,decimalRegex).captures[0]);
				ret.d = strToDouble(s,10);
			}
			ret.type = Token.VarType.tNumeric;
			src = src[s.length..$];
		}
	} else if(inPattern(src[0],opcodeList)) {
		string s = cast(string)(match(src,opcodeRegex).captures[0]);
		ret.str = s;
		ret.type = Token.VarType.tOpcode;
		src = src[s.length..$];
	} else if(inPattern(src[0],"0-9.")) {
		string s;
		if(src.length>2 && src[0] == '0' && (
				toLower(src)[1] == 'x' ||
				toLower(src)[1] == 'b' ||
				toLower(src)[1] == 'o'
			)) {
			switch(toLower(src)[1]) {
			case 'x':
				s = cast(string)(match(src,hexRegex).captures[0]);
				ret.d = strToDouble(s[2..$],16);
				break;
			case 'b':
				s = cast(string)(match(src,binaryRegex).captures[0]);
				ret.d = strToDouble(s[2..$],2);
				break;
			case 'o':
				s = cast(string)(match(src,octalRegex).captures[0]);
				ret.d = strToDouble(s[2..$],8);
				break;
			default:
				s = cast(string)(match(src,decimalRegex).captures[0]);
				ret.d = strToDouble(s[2..$],10);
				break;
			}
		} else {
			s = cast(string)(match(src,decimalRegex).captures[0]);
			ret.d = strToDouble(s,10);
		}
		ret.type = Token.VarType.tNumeric;
		src = src[s.length..$];
	} else if(src[0] == '(') {
		// Recursion all up in this code
		src = src[1..$];
		ret.arr = tokenize(src, source, BraceType.bParen);
		ret.type = Token.VarType.tCompoundStatement;
	} else if(src[0] == '[') {
		// Recursion all up in this code
		src = src[1..$];
		ret.arr = tokenize(src, source, BraceType.bBrace);
		ret.type = Token.VarType.tArray;
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
		if(escapeFrom == BraceType.bParen) {
			// Recursive return
			ret.type = Token.VarType.tClosingBracket;
			src = src[1..$];
		} else {
			throw new OratrParseException("Mismatched ]");
		}
	} else if(src[0] == '}') {
		if(escapeFrom == BraceType.bParen) {
			// Recursive return
			ret.type = Token.VarType.tClosingBrace;
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
	while((src[0]=='\t') || (src[0]==' ')) {
		src=src[1..$];
	}
	
	if(!src.length) {
		tmp.str = "null";
		tmp.type = Token.VarType.tFunction;
		ret ~= tmp;
		return ret;
	}
	// Fix this to work with the new processing scheme
	//src = preprocess(src, source);
	
	do {
		tmp = makeToken(src,source,escapeFrom);
		switch(tmp.type){
			case Token.VarType.tClosingParen: {
				// Just return the () expression
				break;
			}
			case Token.VarType.tClosingBrace: {
				// Evaluate the array
				break;
			}
			case Token.VarType.tClosingBracket: {
				// Just return the {} expression
				break;
			}
			default: {
				ret ~= tmp;
				break;
			}
		}
	} while(src.length);	
	return ret;
}

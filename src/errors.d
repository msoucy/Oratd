import std.exception;
import std.conv;

class OratrBaseException : Error {
	this( string reason, string file = __FILE__, size_t line = __LINE__ )
    {
        super( reason, file, line );
    }
}

class OratrParseException : OratrBaseException {
	this( string reason, string file = __FILE__, size_t line = __LINE__ )
    {
        super( "Parser error: "~reason, file, line );
    }
}

class OratrInvalidArgumentException : OratrBaseException {
	this( string type, size_t position, string file = __FILE__, size_t line = __LINE__ )
    {
        super( "Invalid argument type \""~type~"\" in position "~to!string(position), file, line );
    }
}

class OratrInvalidCodeException : OratrBaseException {
	this( string file = __FILE__, size_t line = __LINE__ )
    {
        super( "Expected code in conditional", file, line );
    }
}

class OratrArgumentCountException : OratrBaseException {
	this( size_t count, string func, string possible, string file = __FILE__, size_t line = __LINE__ )
    {
        super( "Invalid argument count "~to!string(count)~" in function "~func
        	~" accepting "~to!string(possible)~" arguments",
        	file, line );
    }
}

class OratrArgumentCountExceptionControlStructure : OratrBaseException {
	this( size_t count, string func, string possible, string file = __FILE__, size_t line = __LINE__ )
    {
        super( "Invalid argument count "~to!string(count)~" in control structure "~func
        	~" accepting "~to!string(possible)~" arguments",
        	file, line );
    }
}

class OratrInvalidOffsetException : OratrBaseException {
	this( string type, string file = __FILE__, size_t line = __LINE__ )
    {
        super( "Invalid offset type \""~type~"\"", file, line );
    }
	this( string type, int position, string file = __FILE__, size_t line = __LINE__ )
    {
        super( "Invalid offset type \""~type~"\" in position "~to!string(position), file, line );
    }
}

class OratrInvalidConversionFromException : OratrBaseException {
	this( string type, string file = __FILE__, size_t line = __LINE__ )
    {
        super( "Invalid conversion from type \""~type~"\"", file, line );
    }
}

class OratrInvalidConversionToException : OratrBaseException {
	this( string type, string file = __FILE__, size_t line = __LINE__ )
    {
        super( "Invalid conversion to type \""~type~"\"", file, line );
    }
}

class OratrOutOfRangeException : OratrBaseException {
	this( string arr, int position, string file = __FILE__, size_t line = __LINE__ )
    {
        super( "Position "~to!string(position)~" out of range for array "~arr, file, line );
    }
}

class OratrUnidentifiedMemberException : OratrBaseException {
	this(string type, string member, string file = __FILE__, size_t line = __LINE__ )
    {
        super( "Member "~member~" out of range for type "~type~"\"", file, line );
    }
}

class OratrMathOperatorException : OratrBaseException {
	this( string atype, string btype, string file = __FILE__, size_t line = __LINE__ )
    {
        super( "Illegal operation on types \""~atype~"\" and \""~btype~"\"", file, line );
    }
}

class OratrInvalidMathOperatorException : OratrBaseException {
	this( string op, string file = __FILE__, size_t line = __LINE__ )
    {
        super( "Illegal operation \""~op~"\"", file, line );
    }
}

class OratrMissingOperandException : OratrBaseException {
	this( string file = __FILE__, size_t line = __LINE__ )
    {
        super( "Missing operand in math expression", file, line );
    }
}

class OratrMissingFileException : OratrBaseException {
	this( string filename, string file = __FILE__, size_t line = __LINE__ )
    {
        super( "File not found: "~filename, file, line );
    }
}

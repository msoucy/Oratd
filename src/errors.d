import std.exception;
import std.conv;

class OratrParseException : Error {
	this( string reason, string file = __FILE__, size_t line = __LINE__ )
    {
        super( "Parser error: "~reason, file, line );
    }
}

class OratrInvalidArgumentException : Error {
	this( string type, int position, string file = __FILE__, size_t line = __LINE__ )
    {
        super( "Invalid argument type "~type~" in position "~to!string(position), file, line );
    }
}
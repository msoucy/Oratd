import std.exception;

class OratrParseException : Error {
	this( string reason, string file = __FILE__, size_t line = __LINE__ )
    {
        super( "Parser error: "~reason, file, line );
    }
}

class OratrArgumentException : Error {
	this( string reason, string file = __FILE__, size_t line = __LINE__ )
    {
        super( "Parser error: "~reason, file, line );
    }
}
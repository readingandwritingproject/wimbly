
local ffi = require( 'ffi' )
ffi.cdef[[

void combine_files( const char *iname1, const char *iname2, const char *oname );

void mark_file( const char *iname, const char *oname, const char *name, const char *email );
void mark_buffer( const char *buffer, long buffer_size, const char *oname, const char *name, const char *email );

void complete_certificate( const char *iname, const char *oname, const char *descriptive_text, const char *name, const char *title, const char *date );

]]

local lib = ffi.load( 'libpdf/libpdf.so' )

return lib

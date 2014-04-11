
local ffi = require( 'ffi' )
ffi.cdef[[

struct csv_parser {
  int pstate;         /* Parser state */
  int quoted;         /* Is the current field a quoted field? */
  size_t spaces;      /* Number of continious spaces after quote or in a non-quoted field */
  unsigned char * entry_buf;   /* Entry buffer */
  size_t entry_pos;   /* Current position in entry_buf (and current size of entry) */
  size_t entry_size;  /* Size of entry buffer */
  int status;         /* Operation status */
  unsigned char options;
  unsigned char quote_char;
  unsigned char delim_char;
  int (*is_space)(unsigned char);
  int (*is_term)(unsigned char);
  size_t blk_size;
  void *(*malloc_func)(size_t);
  void *(*realloc_func)(void *, size_t);
  void (*free_func)(void *);
};

int csv_init(struct csv_parser *p, unsigned char options);
int csv_fini(struct csv_parser *p, void (*cb1)(void *, size_t, void *), void (*cb2)(int, void *), void *data);
void csv_free(struct csv_parser *p);
size_t csv_parse(struct csv_parser *p, const void *s, size_t len, void (*cb1)(void *, size_t, void *), void (*cb2)(int, void *), void *data);
size_t csv_write(void *dest, size_t dest_size, const void *src, size_t src_size);

]]


local lib = ffi.load( 'libcsv/lib/libcsv.so' )

--[=[

local csv = {}
--setmetatable( csv, metatable )

local parser = ffi.new( 'struct csv_parser' )

local example = [[
name, email
daniel, daniel@readingandwritingproject.com
jose, jose@readingandwritingproject.com
]]

function csv.cb1( str, len, data )
  ngx.say( 'field length: ', tonumber( len ) )
  ngx.say( 'field value: ', ffi.string( str, len ) )
end

function csv.cb2( num, data )
  ngx.say( 'end of row reached' )
end

function csv:init()
  lib.csv_init( parser, 0 )
  lib.csv_parse( parser, example, #example, csv.cb1, csv.cb2, nil )
  lib.csv_fini( parser, csv.cb1, csv.cb2, nil )
  lib.csv_free( parser )
end

--]=]

local SLACSV = {}


function SLACSV:parse( content )
  lib.csv_init( self.parser, 0 )
  lib.csv_parse( self.parser, content, #content, self.fieldWrapped, self.endRowWrapped, nil )
  lib.csv_fini( self.parser, self.fieldWrapped, self.endRowWrapped, nil )
  lib.csv_free( self.parser )
end


-- expects options = { field = function() ..., endRow = function() ... }
function SLACSV:parser( options )
  local instance = {}
  instance.parser = ffi.new( 'struct csv_parser' )
  instance.fieldWrapped = function( str, len, data )
    options.field( ffi.string( str, len ) )
  end
  instance.endRowWrapped = function( num, data )
    options.endRow()
  end
  instance.parse = SLACSV.parse
  return instance
end


return SLACSV

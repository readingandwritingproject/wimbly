
-- part of openresty
cjson = require "cjson"

-- luarocks
require "luarocks.loader"

-- uuid generator
uuid = require "uuid"
uuid.randomseed( os.time() * 10000 )

-- bcrypt password hasher
bcrypt = require "bcrypt"

-- date library
date = require "date"


-- wrapping some of podofo
pdf = require "libpdf"

-- wrapping some of libcsv in an interface like SLAXML
--slacsv = require "libcsv"

-- native CSV Lua library
csv = require "csv"

-- for data structure inspection during development
inspect = require "inspect"


-- for light-weight classes
class = require "middleclass"

-- for a streaming XML parser
slaxml = require "slaxml"


-- for some utility functions
require "util"

-- form and field validation library
validate = require "validate"

-- REST API helper
restfully = require "restfully"

-- DataTables Javascript library interface  
datatables = require "datatables"


wimbly = require "wimbly"

-- preprocess connect application conf
wimbly.preprocess( "/var/www/connect", {
  ["app"] = "/var/www/connect"
} )

-- for browser-based error traces
--wimbly.debug( "/var/www/connect" )

-- to ovverride error method with JSON response
_error = error
error = function( message, data )
  restfully.respond( { error = message, previous_sql = ngx.ctx.sql, data = data }, ngx.HTTP_INTERNAL_SERVER_ERROR )
  exit( ngx.OK )
end



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
slacsv = require "libcsv"

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

wimbly = require "wimbly"

-- wimbly config
--ngx.shared.wimbly:set( )

-- preprocess connect application conf 
wimbly.preprocess( "/var/www/application/connect", {
  ["app"] = "/var/www/application/connect"
} )

-- preprocess connect application conf 
wimbly.preprocess( "/var/www/application/staging", {
  ["app"] = "/var/www/application/staging",
  ["/"] = '/_'
} )

-- load the correct runtime files
_require = require
require = function( path )
  if path:match( 'models' ) or path:match( 'lib' ) then
    path = ngx.var.server_header..'/'..path
  end
  return _require( path )
end

-- for browser-based error reporting
_error = error
error = function( message, data )
  restfully.respond( { error = message, previous_sql = ngx.ctx.sql, data = data }, ngx.HTTP_INTERNAL_SERVER_ERROR )
  exit( ngx.OK )
end


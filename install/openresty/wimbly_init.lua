
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

-- preprocess connect application conf 
wimbly.preprocess( "/var/www/application", {
  ["app"] = "/var/www/application"
} )

-- in case of use outside of ngx
if not ngx then ngx = { ctx = {} } end

local http = {}


function http.accept_form_with_uploads() 

  local upload = require "resty.upload"
  local chunk_size = 4096

  local form, err = upload:new( chunk_size )
  if not form then
    ngx.log( ngx.ERR, "failed to register form upload reader: ", err )
    ngx.exit( 500 )
  end

  form:set_timeout( 1000 )

  local tmpfile = ''
  --local tmppath = ngx.now()..'.uploaded'
  local file

  local posted = {}
  local key = ''
  local filename = nil

  while true do
    local typ, res, err = form:read()

    if typ == 'header' then

      if res[2]:match( '^form%-data' ) then
        key = res[2]:match( ' name="(.-)"' )
        if res[2]:match( ' filename="(.-)"' ) then filename = res[2]:match( ' filename="(.-)"' ) end
      elseif res[1]:match( '^Content%-Type' ) then
        tmpfile = 'static/tmp/'..ngx.now()..'.uploaded_'..filename
        file = io.open( tmpfile, 'w+' )
        posted[key] = tmpfile
      end
      
    elseif typ == 'body' then
    
      if filename then 
        file:write( res ) 
      else
        posted[key] = res
      end
      
    elseif typ == 'part_end' then
      if file then file:close(); file = nil; filename = nil end
    elseif typ == 'eof' or err then
      if file then file:close(); file = nil end
      break
    end

  end
  
  return posted 

end


return http

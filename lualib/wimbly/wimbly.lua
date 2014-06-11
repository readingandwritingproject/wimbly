local wimbly = {}

function wimbly.find( path, filter )
  local filter = filter or '.*'
    
  local directories, results = {}, {}
  for item in lfs.dir( path ) do
    
    local attr = lfs.attributes( path..'/'..item )

    if attr.mode == "directory" and not ( item == '.' or item == '..' ) then
      table.insert( directories, item )
    elseif attr.mode == 'file' and item:match( filter ) then
      table.insert( results, path..'/'..item )
    end
  end
  
  if #directories > 0 then
    for _, subdirectory in ipairs( directories ) do
      local subresults = wimbly.find( path..'/'..subdirectory, filter )
      for _, subitem in ipairs( subresults ) do table.insert( results, subitem ) end
    end
  end
  
  return results
end


function wimbly.preprocess( path, replacements )
  
  local lfs = require "lfs"
  --local inspect = require "inspect"
  --require "util"
  
  local confs = wimbly.find( path, '%.conf%.source$' )
  
  if ngx then ngx.log( ngx.DEBUG, 'wimbly preprocessing...' ) end
  
  for _, source in ipairs( confs ) do
    -- load contents
    local f = io.open( source, 'r' )
    local conf_source = f:read( '*all' )
    f:close()
    
    local conf = conf_source:interpolate( replacements ) --original, replacement )

    -- write changes
    local f = io.open( source:gsub( '.source$', '' ), 'w' )   
    
    if f then
      f:write( conf )
      f:close()
    end
    
  end
  

end

--wimbly.preprocess( '/var/www/application/connect.readingandwritingproject.com', { ['app'] = '../../application/connect.readingandwritingproject.com' } )

return wimbly
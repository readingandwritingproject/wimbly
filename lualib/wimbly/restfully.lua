local RESTfully = {
  GET = {},
  POST = {}
}


function RESTfully.json( content )
  --local content = content or ''

  if type( content ) ~= 'string' then
    content = cjson.encode( content )
  end

  if ngx.var.arg_callback then
    if ngx.header.content_type ~= 'text/javascript' then
      ngx.header.content_type = 'text/javascript'
    end
    ngx.say( ngx.var.arg_callback..'( '..content..' );' )
  else
    if ngx.header.content_type ~= 'text/json' then
      ngx.header.content_type = 'text/json'
    end
    ngx.say( content )
  end
end


function RESTfully.respond( content, ngx_status )
  local ngx_status = ngx_status or ngx.status
  
  ngx.status = ngx_status
  restfully.json( content )
  return ngx.exit( ngx.OK )
end


function RESTfully.validate( parameters_mapping )
  
  local params = {}
  for name, mapping in pairs( parameters_mapping ) do
    params[name] = mapping.location
  end
  
  local success, errors, cleaned = validate.parameters( params, parameters_mapping )
  if not success then
    return restfully.respond( errors, ngx.HTTP_BAD_REQUEST )
    --restfully.json( errors )
    --return ngx.exit( ngx.OK )
  end
  
  return cleaned
  
end


function RESTfully._generate_human_readable_model_name( model_path )
  local parts = model_path:split( '/' )
  local model_name = parts[#parts]:gsub( '_', ' ' )
  return model_name
end

-- !!!
-- TODO, this should accept a 4th parameter of the fields that should be returned
-- and it should rely on the object get call that allows more than one field to be specified,
-- and those should be returned in a table
-- !!!
function RESTfully.GET.data( model_path, loader, load_parameter )

  local BusinessModel = require( model_path )
  local model_name = RESTfully._generate_human_readable_model_name( model_path )

  local results = {}

  local business_object
  local parameter = ngx.var['arg_'..load_parameter ]

  if parameter ~= nil then
    business_object = BusinessModel[loader]( BusinessModel, ngx.unescape_uri( parameter ) )
  end

  if business_object ~= nil then
    results = business_object:data()
  else
    if not ngx.var.arg_callback then
      ngx.status = ngx.HTTP_BAD_REQUEST
    else
      -- jsonp
      results.success = false
    end
    results.message = model_name..' not found'
  end

  RESTfully.json( results )
  
end


function RESTfully.GET.metadata( model_path )

  local BusinessModel = require( model_path )
  local model_name = RESTfully._generate_human_readable_model_name( model_path )

  local results = {}

  -- store the relative order
  local ordered = {}
  
  for key, values in pairs( BusinessModel.fieldMapping ) do
    if not values.generated then
      results[key] = {
        type = values.type,
        required = ( values.required or false ),
        order = values.order,
        readonly = ( values.readonly or false ),
      }
      
      if values.type == 'enumeration' and values.values and type( values.values ) == 'table' then
        if table.isarray( values.values ) then
          results[key].values = values.values
        else
          results[key].values = table.keys( values.values )        
        end
      end
      
      if values.order then ordered[values.order] = key end
    end
  end

  -- update the order numbers
  local order = 1
  for i = 1, table.getn( ordered ) do
    if ordered[i] ~= nil then
      results[ ordered[i] ].order = order
      order = order + 1
    end
  end

  RESTfully.json( results )

end


function RESTfully.POST.create( model_path )

  local BusinessModel = require( model_path )
  local model_name = RESTfully._generate_human_readable_model_name( model_path )

  -- must read the request body up front
  ngx.req.read_body()
  local posted = ngx.req.get_post_args()

  local valid, errors, cleaned = validate.for_creation( posted, BusinessModel.fieldMapping )
   
  local results = {}
  local model = nil

  if not valid then
    ngx.status = ngx.HTTP_BAD_REQUEST
    results.message = 'submitted '..model_name..' values are invalid'
    results.errors = errors
  else
    model = BusinessModel:insert( cleaned )
    if not model then
      ngx.status = ngx.HTTP_BAD_REQUEST
      results.message = model_name..' creation failed'
    else
      results.message = model_name..' created successfully'
      results.details = model:data()
    end
  end

  RESTfully.json( results )
  return model

end


function RESTfully.POST.delete( model_path, loader, load_parameter )

  local BusinessModel = require( model_path )
  local model_name = RESTfully._generate_human_readable_model_name( model_path )

  local results = {}

  local business_object
  local parameter = ngx.var['arg_'..load_parameter ]

  if parameter ~= nil then
    business_object = BusinessModel[loader]( BusinessModel, ngx.unescape_uri( parameter ) )
  end

  if business_object then
    business_object:delete()
    results.message = model_name..' deleted'
  else
    ngx.status = ngx.HTTP_BAD_REQUEST
    results.message = model_name..' not found'
  end

  RESTfully.json( results )

end

function RESTfully._posted_name_to_value( name, value, posted )
  
  -- direct assignments and arrays can be assigned directly
  if name:match( '%[' ) and type( value ) == 'string' then
    
    ngx.log( ngx.DEBUG, 'IN]  name: ', name, ', value: ', value ) 
    
    -- if needed wrap first element in square parentheses for uniformity
    -- nuts[0][items][0][it] -> [nuts][0][items][0][it]
    if name[1] ~= '%[' then
      local part, remainder
      part, remainder = name:match( '^(.-)(%[.*)$' )
      name = '['..part..']'..remainder
    end

    ngx.log( ngx.DEBUG, 'NORMAL]  name: ', name, ', value: ', value ) 
  
    local var_sofar = posted
    local remaining = name
    local index = ''
    --local tab
    
    while remaining and remaining:match( '%[' ) do
      index, remaining = remaining:match( '^%[(.-)%](.*)$' )
      ngx.log( ngx.DEBUG, 'LOOP]  index: ', index, ', remaining: ', remaining ) 
      
      -- handle array indexes
      if index:match( '^%d' ) then
        -- switch to array lookups and account for lua counting from 1
        index = tonumber( index ) + 1
      elseif index == '' then
        index = #var_sofar + 1        
        ngx.log( ngx.DEBUG, 'EMPTY INDEX]  index: ', index ) 
      end
      
      if var_sofar[index] == nil then
        if type( index ) == 'number' then
          local inner = {}
          table.insert( var_sofar, inner )
          var_sofar = inner
        else
          var_sofar[index] = {}
          var_sofar = var_sofar[index]
        end
      else
        var_sofar = var_sofar[index]
      end
  -- nuts[0]['items'][0]['it'] = 'item1a'
    end
    
    var_sofar[index] = value
    
  else
    posted[name] = value
  end
end


function RESTfully.post_to_table( posted )
  
  --local input = table.copy( posted )
  local results = {}
  local input = posted 
  local input = { 
    ['ubga[]'] = 'abc',
    ['ubga[]'] = 'def'
    --    ['nuts[0][items][0][it]'] = 'item1a' 
  }
  
  for name, value in pairs( input ) do
    RESTfully._posted_name_to_value( name, value, results ) 
  end
  
  return results
  --[[
  nuts[0][items][0][it] item1a
  nuts[0][items][1][it] item1b
  nuts[0][name]   name1
  nuts[1][items][0][it] item2a
  nuts[1][items][1][it] item2b
  nuts[1][name]   name2

  --]]
  
  --[=[
  local result = {}
  for key, value in pairs( posted ) do
    if key:match( '[' ) then
      local name
      _, name, remainder = key:match( '^(.*)([.*)' )
      if result[name] == nil then result[name] = {} end
      
      
      
    else
      --key
    end
  end
  --]=]
  
end


function RESTfully.POST.data2( model_path, loader, load_parameter )

  ngx.req.read_body()
  local posted = ngx.req.get_post_args()

  --local results = RESTfully.post_to_table( posted )
  local results = posted
  
  RESTfully.json( results )

  
  
  
end


function RESTfully.POST.data( model_path, loader, load_parameter )

  local BusinessModel = require( model_path )
  local model_name = RESTfully._generate_human_readable_model_name( model_path )

  local results = {}

  local business_object
  local parameter = ngx.var['arg_'..load_parameter ]

  if parameter ~= nil then
    business_object = BusinessModel[loader]( BusinessModel, ngx.unescape_uri( parameter ) )
  end
  
  if business_object then
    -- must read the request body up front
    ngx.req.read_body()
    local posted = ngx.req.get_post_args()

    local valid, errors, cleaned = validate.for_update( posted, BusinessModel.fieldMapping )

    if not valid then
      ngx.status = ngx.HTTP_BAD_REQUEST
      results.message = 'submitted '..model_name..' values are invalid'
      results.errors = errors
    else
      business_object:set( cleaned )
      results.message = model_name..' updated successfully'
      
      -- reload from database to verify changes and force cache flush
      results.data = BusinessModel[loader]( BusinessModel, ngx.unescape_uri( parameter ), { reload = true } ):data() 
    end
  else
    ngx.status = ngx.HTTP_BAD_REQUEST
    results.message = model_name..' not found'
  end

  RESTfully.json( results )

end


return RESTfully

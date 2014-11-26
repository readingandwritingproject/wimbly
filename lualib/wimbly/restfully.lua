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



function RESTfully.POST.create2( model_path )

  local BusinessModel = require( model_path )
  local model_name = RESTfully._generate_human_readable_model_name( model_path )

  ngx.req.read_body()
  local posted = restfully.post_to_table( ngx.req.get_post_args(), BusinessModel.fieldMapping )

  ngx.say( 'posted', inspect( posted ) )

  local valid, errors, cleaned = validate.for_creation( posted, BusinessModel.fieldMapping )

  ngx.say( 'cleaned', inspect( cleaned ) )
  --ngx.exit( ngx.OK )


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


-- convert strings (or an array of strings) to numbers or booleans (or an array of numbers or booleans)
function RESTfully._string_type_convert( value, to_type )
  local to_type = ( to_type or '' )

  local _convert = function( val, t )
    if t:match( 'number' ) or t:match( 'integer' ) or t:match( 'float' ) then
      return tonumber( val )
    elseif t:match( 'boolean' ) then
      return ( val:lower():trim() == 'true' or val:trim() == '1' )
    else
      return val
    end
  end

  local standardized_type = to_type:gsub( '[_ ]', '' ):lower()

  if standardized_type:ends( 'array' ) then
    if type( value ) ~= 'table' or not table.isarray( value ) then error( 'type change of an array type expects a table', 2 ) end
    local results = {}
    for i = 1, #value do
      results[i] = _convert( value[i], standardized_type )
    end
    return results
  else
    return _convert( value, standardized_type )
  end

end



function RESTfully._posted_name_to_value( name, value, posted, mapping )

  if name:match( '%[' ) then

    -- if needed wrap first element in square parentheses for uniformity
    -- nuts[0][items][0][it] -> [nuts][0][items][0][it]
    if name[1] ~= '%[' then
      local part, remainder
      part, remainder = name:match( '^(.-)(%[.*)$' )
      name = '['..part..']'..remainder
    end

    -- remove the array signifier [] since ngx.req.get_post_args() handles that
    -- [nuts][0][items][0][it][] -> [nuts][0][items][0][it]
    if name:match( '%[%]$' ) then
      name = name:sub( 1, -3 )
    end

    local var_sofar = posted
    local index = ''

    local indices = {}
    for index in name:gmatch( '%[(.-)%]' ) do
      table.insert( indices, index )
    end

    for count, index in ipairs( indices ) do

      -- handle array indexes
      if index:match( '^%d' ) then
        -- switch to array lookups and account for lua counting from 1
        index = tonumber( index ) + 1
      end

      if var_sofar[index] == nil and count < #indices then
        if type( index ) == 'number' then
          local inner = {}
          table.insert( var_sofar, inner )
          var_sofar = inner
        else
          var_sofar[index] = {}
          var_sofar = var_sofar[index]
        end
      else
        if count < #indices then
          var_sofar = var_sofar[index]
        else
          --local clean_name = name:gsub( '[
          --var_sofar[index] = RESTfully._string_type_convert( value, table.dotget( mapping, name..'.type' ) )

          var_sofar[index] = value
        end
      end
    end

  else
    posted[name] = RESTfully._string_type_convert( value, table.dotget( mapping, name..'.type' ) )
    --posted[name] = value
  end
end



function RESTfully.post_to_table( posted, mapping )
  local mapping = ( mapping or {} )

  local results = {}
  local input = posted

  for name, value in pairs( input ) do
    RESTfully._posted_name_to_value( name, value, results, mapping )
  end

  -- if a mapping is supplied with type information then try to convert types
  --if mapping then
--    for name, value in pairs( results ) do
      --RESTfully._posted_name_to_value( name, value, results )
    --end
  --end

  return results

end


function RESTfully.POST.data2( model_path, loader, load_parameter )

  ngx.req.read_body()
  local posted = ngx.req.get_post_args()

  local results = RESTfully.post_to_table( posted )

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

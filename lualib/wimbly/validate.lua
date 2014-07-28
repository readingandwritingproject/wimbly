local validate = {
  type = {}
}

--[[
see Institute.propertyMapping for an example of a valid field to property mapping
--]]

-- example types:
-- string array
-- whole number array
-- sqldate
-- yesno array


function validate.field( name, value, mapping )
  if ( mapping == nil ) then
    return false, "unable to validate field '"..name.."' without a mapping"
  else

    -- don't use the original mapping table so that it does not get modified by validation
    local mapping = table.copy( mapping )
  
    if mapping.type and type( mapping.type ) == 'string' then
  
      -- handle an array of values if type ends with 'array'
      if mapping.type:ends( 'array' ) then
        mapping.type = mapping.type:match( '(.+)array' )
        if type( value ) == 'table' then
          for _, val in ipairs( value ) do
            local res, err = validate.field( name, val, mapping )
            if not res then return res, err end
          end
          mapping.type = nil
        end
      -- handle a string comma separated list if type ends with 'list'
      elseif mapping.type:ends( 'list' ) then
        mapping.type = mapping.type:match( '(.+)list' )
        if type( value ) == 'string' then
          for _, val in ipairs( value:split( ',' ) ) do
            local res, err = validate.field( name, val, mapping )
            if not res then return res, err end
          end
          mapping.type = nil
        end
      end
      
    end
  
    -- cannot handle table values
    if mapping.type and type( value ) == 'table' then
      return false, "validate can only occur on table values if the mapping type ends with 'array'"
    end
  
    -- if a mapping type was specified
    if mapping.type and type( mapping.type ) == 'string' and value ~= false then
    
      -- remove spaces and underscores from type
      mapping.type = mapping.type:gsub( '[_ ]', '' ):lower()
      
      if mapping.type == 'sqldatetime' then
        if not validate.type.sqldatetime( value ) then
          return false, "'"..name.."' requires a valid SQL datetime, '"..value.."' is invalid"
        end      
      elseif mapping.type == 'sqldate' or mapping.type == 'date' then
        if not validate.type.sqldate( value ) then
          return false, "'"..name.."' requires a valid SQL date, '"..value.."' is invalid"
        end
      elseif mapping.type == 'integer' or mapping.type == 'integernumber' then
        if not validate.type.integernumber( value ) then
          return false, "'"..name.."' requires a integer number value, '"..value.."' is invalid"
        end
      elseif mapping.type == 'rational' or mapping.type == 'rationalnumber' then
        if not validate.type.rationalnumber( value ) then
          return false, "'"..name.."' requires a rational number value, '"..value.."' is invalid"
        end
      elseif mapping.type == 'wholenumber' then
        if not validate.type.wholenumber( value ) then
          return false, "'"..name.."' requires a whole number value, '"..value.."' is invalid"
        end
      elseif mapping.type == 'boolean' then
        if not validate.type.boolean( value ) then
          return false, "'"..name.."' must be of type 'boolean', '"..type( value ).."' is invalid"
        end
      elseif mapping.type == 'enumeration' then
        if not validate.type.enumeration( value, mapping.values ) then
          local values
          if table.isarray( mapping.values ) then values = mapping.values else values = table.keys( mapping.values ) end
          return false, "'"..name.."' must be of one of '"..table.concat( values, "', '" ).."'"
        end
      elseif mapping.type == 'email' or mapping.type == 'emailaddress' then
        if not validate.type.emailaddress( value ) then
          return false, "'"..name.."' must be a valid email address, '"..value.."' is invalid"
        end
      elseif mapping.type == 'yesno' then
        if not validate.type.yesno( value ) then
          return false, "'"..name.."' must be either 'yes' or 'no', '"..value.."' is invalid"
        end        
      elseif mapping.type == 'string' then
        if not type( value ) == 'string' then
          return false, "'"..name.."' should be of type 'string', '"..type( value ).."' is invalid"
        end
      else
        return false, "no method found to validate '"..name.."' as type '"..mapping.type.."'"
      end
      
    end

    -- if a mapping pattern was specified
    if mapping.pattern and value ~= false and type( value ) == 'string' and not value:match( mapping.pattern ) then
      return false, "'"..name.."' fails pattern validation '"..mapping.pattern.."'"
    end

    -- if a validation function was provided in mapping
    if mapping.validation and type( mapping.validation ) == 'function' then
      return mapping.validation( value )
    end

  end -- if a mapping entry exists

  return true
end


function validate.fields( fields, mapping, options )
  local options = options or {}
  
  local errors = {}
  
  -- check for existence and required
  for name, values in pairs( mapping ) do
    if values.required and options.create and fields[name] == nil then
      table.insert( errors, { name = name, message = "'"..name.."' is required" } )
    end    
  end
  
  
  for name, value in pairs( fields ) do
       
    -- if options.update is set then readonly must be enforced
    if value and mapping[name] and mapping[name].readonly and options.update then
      table.insert( errors, { name = name, message = "'"..name.."' is readonly" } )
    end
      
    local valid, message = validate.field( name, value, mapping[name] )
    if not valid then
      table.insert( errors, { name = name, message = message } )
    end

  end -- iterate through the values

  return #errors == 0, errors
  
end


function validate.convert( name, value, typ, options )
  local options = options or {}
    
  if type( name ) ~= 'string' or type( value ) ~= 'string' or type( typ ) ~= 'string' then 
    ngx.exit( ngx.OK )
    error( "convert must be called with strings" ) 
  end
  
  local success = true
    
  local original = value
  if typ:match( '^integer' ) or typ:match( '^rational' ) or typ:match( 'number' ) then
    -- an empty string should convert to nil instead of zero
    if value:trim() == '' then 
      value = nil
    else
      value = tonumber( original )
      if not original:match( tostring( value ) ) then success = false end
    end
  elseif typ:match( '^boolean' ) then
    value = ( value:trim():lower() == 'true' )
    if not ( original:lower():trim() == 'true' or original:lower():trim() == 'false' ) then success = false end
  end
  
  if options.unescape and type( value ) == 'string' then
    value = ngx.unescape_uri( value )
  end
  
  return success, value 
end


function validate.transform( posted, mapping, options )
  local options = options or {}

  local errors = {}
  local cleaned = table.copy( posted )
  
  -- check that all required fields are present 
  if options.create then
    for name, values in pairs( mapping ) do
      if ( not cleaned[name] or ( type( cleaned[name] ) == 'string' and cleaned[name]:trim() == '' ) ) and values.required then
        table.insert( errors, { name = name, message = "'"..name.."' is required" } )
      end
    end
  end
  
  local converted, success
     
  -- if valid conversions convert posted string fields to the intended data types in 'cleaned'
  for name, value in pairs( cleaned ) do
    if type( name ) ~= 'string' then error( "table 'posted' must be composed only of string keys" ) end
  
    if type( value ) == 'table' then
      converted = {}
      
      for index, val in ipairs( value ) do
        if type( val ) == 'string' then
          if mapping[name].type then
            success, converted[index] = validate.convert( name, val, mapping[name].type, options )
            if not success then table.insert( errors, { name = name, message = "value in '"..name.."' table could not be converted to type '"..mapping[name].type.."'" } ) end
          else
            converted[index] = val
          end
        else
          table.insert( errors, { name = name, message = "'"..name.."' must be a table of strings" } )
        end
      end
      
    elseif type( value ) == 'string' then
      if mapping[name] and mapping[name].type then
        success, converted = validate.convert( name, value, mapping[name].type, options )
        if not success then table.insert( errors, { name = name, message = "value in '"..name.."' field could not be converted to type '"..mapping[name].type.."'" } ) end
      else
        converted = value
      end
    else
      table.insert( errors, { name = name, message = "'"..name.."' must be of type string" } )
    end
    
    cleaned[name] = converted
  end
  
  return #errors == 0, errors, cleaned 
end


function validate.for_creation( posted, mapping, options )
  -- check that all required fields are present
  local options = options or { create = true }

  if ( mapping == nil ) then
    return false, "unable to validate"
  end
  
  local transform_success, transform_errors, cleaned = validate.transform( posted, mapping, options ) 
  -- don't show create (required) errors twice
  options.create = false
  local validation_success, validation_errors = validate.fields( cleaned, mapping, options )
  
  local errors = {}
  for i, err in ipairs( transform_errors ) do errors[i] = err end
  for i, err in ipairs( validation_errors ) do errors[#transform_errors + i] = err end
  
  return #errors == 0, errors, cleaned
end


function validate.parameters( params, mapping )
  return validate.for_creation( params, mapping, { create = true, unescape = true } )
end


function validate.for_update( posted, mapping )
  -- check that all readonly fields are left alone
  local options = options or { readonly = true }

  if ( mapping == nil ) then
    return false, "unable to validate"
  end

  local transform_success, transform_errors, cleaned = validate.transform( posted, mapping, options )
  
  local validation_success, validation_errors = validate.fields( cleaned, mapping, options )
  
  local errors = {}
  for i, err in ipairs( transform_errors ) do errors[i] = err end
  for i, err in ipairs( validation_errors ) do errors[#transform_errors + i] = err end

  return #errors == 0, errors, cleaned
end


function validate.type.enumeration( submitted, values )
  local vals = {}
  
  if table.isarray( values ) then
    for _, value in ipairs( values ) do
      vals[value] = value
    end
  else
    vals = values
  end
  
  if vals[submitted] then
    return true, vals[submitted]
  else
    return false, submitted
  end

end


function validate.type.sqldatetime( str )
  
  local parts = str:split( ' ' )
  
  local datepart = validate.type.sqldate( parts[1] )
  
  local h, m, s = parts[2]:match( '^([0-2][0-9]):([0-5][0-9]):([0-5][0-9])$' )
  
  h = tonumber( h )
  
  if ( h ~= nil and m ~= nil and s ~= nil ) then
    return ( h <= 23 and datepart ), str
  else
    return false, str
  end

end


-- check whether string could be a sqldate
function validate.type.sqldate( str )
  local y, m, d = str:match( '^([1-2][9,0]%d%d)%-([0-1][0-9])%-([0-3][0-9])$' )

  if y ~= nil and m ~= nil and d ~= nil then

    y, m, d = tonumber( y ), tonumber( m ), tonumber( d )

    -- Apr, Jun, Sep, Nov can have at most 30 days
    if m == 4 or m == 6 or m == 9 or m == 11 then
      return d <= 30, str
    -- Feb
    elseif m == 2 then
      -- if leap year, days can be at most 29
      if y%400 == 0 or ( y%100 ~= 0 and y%4 == 0 ) then
        return d <= 29, str
      -- else 28 days is the max
      else
        return d <= 28, str
      end
    -- all other months can have at most 31 days
    else
      return d <= 31, str
    end
  else
    return false, str
  end
end

-- check comma separated list of dates
function validate.type.sqldates( str )
  local dates = str:split( ',' )
  if #dates > 0 then
    for _, d in ipairs( dates ) do
      if not validate.type.sqldate( d ) then
        return false
      end
    end
    return true, str
  else
    return false, str
  end
end

-- check for a valid integer
function validate.type.integernumber( num )
  local cleaned = tostring( num )
  return ( type( num ) == 'number' and cleaned:match( '^-?%d+$' ) ), cleaned
end

-- check for valid rational number
function validate.type.wholenumber( num )
  local cleaned = tostring( num )
  return ( type( num ) == 'number' and cleaned:match( '^-?%d+%.?%d-$' ) ), cleaned
end

-- check for valid whole number
function validate.type.wholenumber( num )
  local cleaned = tostring( num )
  return ( type( num ) == 'number' and cleaned:match( '^%d+$' ) ), cleaned
end

function validate.type.boolean( bool )
  local cleaned = tostring( bool )
  return type( bool ) == 'boolean', cleaned
end

function validate.type.yesno( str )
  local cleaned = tostring( str )
  cleaned = str:lower():trim()
  return ( cleaned == 'yes' or cleaned == 'no' ), cleaned
end

function validate.type.emailaddress( str )
  local cleaned = tostring( str )
  return ( cleaned:match( "[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?" ) ), cleaned
end

return validate

local validate = {
  type = {}
}

--[[
see Institute.propertyMapping for an example of a valid field to property mapping
--]]


function validate.field( name, value, mapping )
  if ( mapping == nil ) then
    return false, "unable to validate field '"..name.."'"
  else

    -- if a mapping type was specified
    if mapping.type and value ~= false then
      if mapping.type == 'date' and not validate.type.sqldate( value ) then
        return false, "'"..name.."' requires a valid date, '"..value.."' is invalid"
      elseif mapping.type == 'dates' and not validate.type.sqldates( value ) then
        return false, "'"..name.."' requires a list of valid dates, '"..value.."' is invalid"
      elseif mapping.type == 'integernumber' and not validate.type.integernumber( value ) then
        return false, "'"..name.."' requires a integer number value, "..value.." is invalid"
      elseif mapping.type == 'rationalnumber' and not validate.type.rationalnumber( value ) then
        return false, "'"..name.."' requires a rational number value, "..value.." is invalid"
      elseif mapping.type == 'wholenumber' and not validate.type.wholenumber( value ) then
        return false, "'"..name.."' requires a whole number value, "..value.." is invalid"
      elseif mapping.type == 'boolean' and not type( value ) == 'boolean' then
        return false, "'"..name.."' must be of type 'boolean', '"..type( value ).."' is invalid"
      elseif mapping.type == 'enumeration' and not validate.type.enumeration( value, mapping.values ) then
        local values
        if table.isarray( mapping.values ) then values = mapping.values else values = table.keys( mapping.values ) end
        return false, "'"..name.."' must be of one of '"..table.concat( values, "', '" ).."'"
      elseif mapping.type == 'string' and not type( value ) == 'string' then
        return false, "'"..name.."' should be of type 'string', '"..type( value ).."' is invalid"
      end
    end

    -- if a mapping pattern was specified
    if mapping.pattern and value ~= false and not value:match( mapping.pattern ) then
      return false, "'"..name.."' fails pattern validation '"..mapping.pattern.."'"
    end

    -- if a validation function was provided in mapping
    if mapping.validation and type( mapping.validation ) == 'function' then
      return mapping.validation( value )
    end

  end -- if a mapping entry exists

  return true
end


function validate.for_creation( posted, mapping, options )
  local options = options or {}

  local received = posted
  local errors = {}

  if ( mapping == nil ) then
    return false, "unable to validate"
  end

  -- check that all required fields were submitted
  for name, values in pairs( mapping ) do
    if ( not posted[name] or posted[name]:trim() == '' ) and values.required then
      table.insert( errors, { name = name, message = "'"..name.."' is required" } )
    end
  end

  -- validate submitted fields
  for name, value in pairs( received ) do

    if type( name ) ~= 'string' or type( value ) ~= 'string' then
      error( "table 'posted' passed to validate.for_creation must be composed only of string values" )
    end

    -- for values that should not be strings convert datatypes to match mapping and validate
    if mapping[name] and ( mapping[name].type == 'boolean' or mapping[name].type == 'integernumber' or mapping[name].type == 'wholenumber' or mapping[name].type == 'rationalnumber' ) then
      local original = value
      if mapping[name].type:match( 'number' ) then
        -- convert to number
        value = tonumber( original )
      else
        -- convert to boolean
        if value:trim():lower() == 'true' or value:trim():lower() == 'false' then
          value = ( value:trim():lower() == 'true' )
        end
      end

      local valid = validate.type[ mapping[name].type ]( value )
      if ( not valid and not ( value == nil and not mapping[name].required ) ) or not original:match( '^%d+%.?%d-$' ) then
        table.insert( errors, { name = name, message = "'"..name.."' requires a "..mapping[name].type:gsub( 'number', ' number' ).." value, '"..original.."' is invalid" } )
      else
        posted[name] = value
      end
    else
      -- unescape?
      if options.unescape then
        posted[name] = ngx.unescape_uri( value )
      end

      -- validate the rest
      local valid, message = validate.field( name, value, mapping[name] )
      if not valid then
        table.insert( errors, { name = name, message = message } )
      end
    end

  end -- iterate through the values

  return #errors == 0, errors
end


function validate.parameters( params, mapping )
  return validate.for_creation( params, mapping, { unescape = true } )
end


function validate.for_update( posted, mapping )
  local received = posted
  local errors = {}

  if ( mapping == nil ) then
    return false, "unable to validate 'posted'"
  end

  for name, value in pairs( received ) do

    if type( name ) ~= 'string' or type( value ) ~= 'string' then
      error( "table 'posted' passed to validate.for_update must be composed only of string values" )
    end

    -- if readonly was specified
    if value and mapping[name] and mapping[name].readonly then
      table.insert( errors, { name = name, message = "'"..name.."' is readonly" } )
    end

    -- for values that should not be strings convert datatypes to match mapping and validate
    if mapping[name] and ( mapping[name].type == 'boolean' or mapping[name].type == 'integernumber' or mapping[name].type == 'wholenumber' ) then
      local original = value
      if mapping[name].type:match( 'number' ) then
        -- convert to number
        value = tonumber( original )
      else
        -- convert to boolean
        if value:trim():lower() == 'true' or value:trim():lower() == 'false' then
          value = ( value:trim():lower() == 'true' )
        end
      end

      local valid = validate.type[ mapping[name].type ]( value )
      if ( not valid and not ( value == nil and not mapping[name].required ) ) or not original:match( '^%d+%.?%d-$' ) then
        table.insert( errors, { name = name, message = "'"..name.."' requires a "..mapping[name].type:gsub( 'number', ' number' ).." value, '"..original.."' is invalid" } )
      else
        posted[name] = value
      end
    else
      -- validate the rest
      local valid, message = validate.field( name, value, mapping[name] )
      if not valid then
        table.insert( errors, { name = name, message = message } )
      end
    end

  end -- iterate through the values

  return #errors == 0, errors
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
  --return false, submitted
end


-- check whether string could be a sqldate
function validate.type.sqldate( str )
  local y, m, d = str:match( '([1-2][9,0]%d%d)%-([0-1][0-9])%-([0-3][0-9])' )

  if y ~= nil and m ~= nil and d ~= nil then

    y, m, d = tonumber(y), tonumber(m), tonumber(d)

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

function validate.type.yesno( str )
  local cleaned = str:lower():trim()
  return ( cleaned == 'yes' or cleaned == 'no' ), cleaned
end

function validate.type.boolean( bool )
  --local cleaned = tostring( str )
  --str:lower():trim()
  return type( bool ) == 'boolean', cleaned
end

return validate

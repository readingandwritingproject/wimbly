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
    ngx.header.content_type = 'text/javascript'
    ngx.say( ngx.var.arg_callback..'( '..content..' );' )
  else
    ngx.header.content_type = 'text/json'
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
    params[name] = mapping.source
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



-- delete below once conversion is complete
-- details API call
function RESTfully.GET.details( model_path, loader, load_parameter )

  local BusinessModel = require( model_path )
  local model_name = RESTfully._generate_human_readable_model_name( model_path )

  local results = {}

  local business_object
  local parameter = ngx.var['arg_'..load_parameter ]

  if parameter ~= nil then
    business_object = BusinessModel[loader]( BusinessModel, ngx.unescape_uri( parameter ) )
  end

  if business_object ~= nil then
    results = business_object:details()
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


-- delete below once conversion is complete
-- details API call
function RESTfully.GET.fields( model_path )

  local BusinessModel = require( model_path )
  local model_name = RESTfully._generate_human_readable_model_name( model_path )

  local results = {}

  -- store the relative order
  local ordered = {}

  
  -- delete below once conversion to field/get/set is complete
  --- ***
  if BusinessModel.detailMapping then
    BusinessModel.fieldMapping = BusinessModel.detailMapping
  end
  --- ***
  
  for key, values in pairs( BusinessModel.fieldMapping ) do
    if not values.generated then
      results[key] = {
        type = values.type,
        required = ( values.required or false ),
        order = values.order,
        readonly = ( values.readonly or false ),
        --values = values.values
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

-- delete below once conversion is complete
-- details API call
function RESTfully.POST.details( model_path, loader, load_parameter )

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

    local valid, errors, cleaned = validate.for_update( posted, BusinessModel.detailMapping )

    if not valid then
      ngx.status = ngx.HTTP_BAD_REQUEST
      results.message = 'submitted '..model_name..' values are invalid'
      results.errors = errors
    else
      local success, errors = business_object:update( cleaned )
      if not success then
        ngx.status = ngx.HTTP_BAD_REQUEST
        results.message = model_name..' update failed'
        results.errors = errors
      else
        results.message = model_name..' updated successfully'
        results.details = business_object:details()
      end
    end
  else
    ngx.status = ngx.HTTP_BAD_REQUEST
    results.message = model_name..' not found'
  end

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
      results.details = business_object:data()
    end
  else
    ngx.status = ngx.HTTP_BAD_REQUEST
    results.message = model_name..' not found'
  end

  RESTfully.json( results )

end




return RESTfully

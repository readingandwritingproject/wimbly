
local DataTables = {
  GET = {}
}


function DataTables._collection( collection_path, options )

  local Collection = require( collection_path )

  local collection = Collection:new( options )
  
  local result = {}

  local tablerows = {}
  for _, row in ipairs( collection:rows() ) do
    local tablerow = {}
    for _, column in ipairs( options.columns ) do
      if Collection.fieldMapping[column].location then
        table.insert( tablerow, row[column] )
      elseif Collection.fieldMapping[column].accessor then
        table.insert( tablerow, Collection.fieldMapping[column].accessor( row ) )        
      end
    end
    table.insert( tablerows, tablerow )
  end
  result.data = tablerows
 
  result.recordsTotal = collection:totalCount()
   
  if options.filter then
    result.recordsFiltered = collection:filteredCount()
  else
    result.recordsFiltered = result.recordsTotal
  end
 
  return result
end  



function DataTables.GET.collection( collection_path, parameters )

  local args = ngx.req.get_uri_args()

  local params = {
    draw = { location = ngx.var.arg_draw, required = true, type = integer },
    columns = { location = ngx.var.arg_columns, required = true, type = 'string list' },
    limit = { location = ngx.var.arg_length, required = true, type = 'integer' },
    offset = { location = ngx.var.arg_start, required = true, type = 'integer' }, 
    filter = { location = args['search[value]'], required = false, type = 'string' },
    filter_regex = { location = args['search[regex]'], required = true, type = 'boolean' },
    order_index = { location = args['order[0][column]'], required = true, type = 'integer' },
    order_direction = { location = args['order[0][dir]'], required = true, enumeration = { 'asc', 'desc' } }
  }
  
  local params = restfully.validate( params )

  local options = {
    columns = params.columns:split( ',' ),
    filter = params.filter,
    offset = params.offset,
    limit = params.limit,
    conditions = parameters
  }
 
  restfully.respond( DataTables._collection( collection_path, options ) )
end



return DataTables

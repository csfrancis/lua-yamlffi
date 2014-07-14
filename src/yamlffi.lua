local ffi = require('ffi')
local stack = require('yamlffi.stack')

local C = nil
local _M = {}

local STATE_ROOT = 1
local STATE_MAP = 2
local STATE_SEQUENCE = 3

local function create_context(ctx, state)
  local new_ctx = { map = {}, state = state, stack = ctx.stack, anchors = ctx.anchors }
  return new_ctx
end

local function process_map_start(event, ctx)
  local new_ctx = create_context(ctx, STATE_MAP)
  if ctx.state == STATE_ROOT then
    ctx.map = new_ctx.map
  elseif ctx.state == STATE_SEQUENCE then
    table.insert(ctx.map, new_ctx.map)
  elseif ctx.map_key then
    ctx.map[ctx.map_key] = new_ctx.map
    ctx.map_key = nil
  end

  if ffi.cast('uint64_t', event[0].data.mapping_start.anchor) > 0 then
    ctx.anchors[ffi.string(event[0].data.mapping_start.anchor)] = new_ctx.map
  end

  new_ctx.stack:push(new_ctx)
  return new_ctx
end

local function process_map_end(event, ctx)
  local ctx = ctx.stack:pop()
  return ctx.stack:peek()
end

local function process_sequence_start(event, ctx)
  local new_ctx = create_context(ctx, STATE_SEQUENCE)
  if ctx.state == STATE_ROOT then
    ctx.map = new_ctx.map
  elseif ctx.state == STATE_SEQUENCE then
    table.insert(ctx.map, new_ctx.map)
  elseif ctx.map_key then
    ctx.map[ctx.map_key] = new_ctx.map
    ctx.map_key = nil
  end
  new_ctx.stack:push(new_ctx)
  return new_ctx
end

local function process_sequence_end(event, ctx)
  local ctx = ctx.stack:pop()
  return ctx.stack:peek()
end

local function process_scalar(event, ctx)
  local val = ffi.string(event[0].data.scalar.value)
  if ctx.state == STATE_MAP then
    if not ctx.map_key then
      ctx.map_key = val
    else
      ctx.map[ctx.map_key] = val
      ctx.map_key = nil
    end
  end
  return ctx
end

local function process_alias(event, ctx)
  if ctx.map_key then
    local val = ffi.string(event[0].data.alias.anchor)
    if ctx.anchors[val] then
      ctx.map[ctx.map_key] = ctx.anchors[val]
    end
  end
  ctx.map_key = nil
  return ctx
end

local function process_event(event, ctx)
  if event[0].type == C.YAML_SCALAR_EVENT then
    return process_scalar(event, ctx)
  elseif event[0].type == C.YAML_MAPPING_START_EVENT then
    return process_map_start(event, ctx)
  elseif event[0].type == C.YAML_MAPPING_END_EVENT then
    return process_map_end(event, ctx)
  elseif event[0].type == C.YAML_SEQUENCE_START_EVENT then
    return process_sequence_start(event, ctx)
  elseif event[0].type == C.YAML_SEQUENCE_END_EVENT then
    return process_sequence_end(event, ctx)
  elseif event[0].type == C.YAML_ALIAS_EVENT then
    return process_alias(event, ctx)
  end
  return ctx
end

function _M.load(yaml)
  local parser = ffi.new('yaml_parser_t[1]')
  local event = ffi.new('yaml_event_t[1]')
  C.yaml_parser_initialize(parser)
  C.yaml_parser_set_input_string(parser, yaml, string.len(yaml))

  local ctx_stack = stack.new()
  local root_ctx = { state = STATE_ROOT, stack = ctx_stack, anchors = {} }
  local ctx = root_ctx

  while true do
    if C.yaml_parser_parse(parser, event) == 0 then
      error('error parsing yaml: ' .. ffi.string(parser.problem))
      break
    end
    if event[0].type == C.YAML_STREAM_END_EVENT then
      break
    end
    ctx = process_event(event, ctx)
    C.yaml_event_delete(event)
  end

  C.yaml_parser_delete(parser)

  return root_ctx.map
end

function _M.loadfile(filename)
  local f = assert(io.open(filename, "r"))
  local yaml = f:read("*all")
  return _M.load(yaml)
end

function _M.libyaml_version()
  return ffi.string(C.yaml_get_version_string())
end

local function init_yaml()
  require('yamlffi.yaml_h')
  C = ffi.load('yaml')
  local version = ffi.string(C.yaml_get_version_string())
  if string.sub(version, 1, 3) ~= "0.1" then
    error("incompatible version of libyaml: " .. version)
  end
end

init_yaml()

return _M

package = "lua-yamlffi"
version = "0.1-1"
source = {
  url = "git://github.com/csfrancis/lua-yamlffi.git",
  tag = "1.0"
}
description = {
  summary = "Lua FFI YAML library",
  homepage = "https://github.com/csfrancis/lua-yamlffi",
  license = "MIT/X11",
  maintainer = "Scott Francis <scott.francis@shopify.com>"
}
dependencies = {
  "lua >= 5.1",
}
build = {
  type = "builtin",
  modules = {
    yamlffi = "src/yamlffi.lua",
    ["yamlffi.yaml_h"] = "src/yamlffi/yaml_h.lua",
    ["yamlffi.stack"] = "src/yamlffi/stack.lua",
  }
}

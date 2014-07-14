##lua-yamlffi##

Lua library that uses FFI to load YAML via libyaml.

### Installation ###

```
luarocks install lua-yamlffi
```

### Dependencies ###

- Luajit >= 2.0.0
- libyaml >= 0.1.4

### Usage ###

```lua
yaml = require("yamlffi")
doc = yaml.loadfile('file.yaml')
```

The following APIs are provided:
- `load(content)`
- `loadfile(filename)`
- `libyaml_version()`

### Development ###

Tests can be run using [busted](http://olivinelabs.com/busted):

```
sudo luarocks install busted
busted test/yamlffi_test.lua
```

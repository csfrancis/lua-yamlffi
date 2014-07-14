require("luarocks.loader")

describe("yamlffi tests", function()
  local yaml

  setup(function()
    yaml = require("yamlffi")
  end)

  it("should load inline yaml", function()
    local doc = yaml.load[[
---
receipt:     Oz-Ware Purchase Invoice
date:        2012-08-06
]]
  end)

  it("should fail to load invalid inline yaml", function()
    assert.has_error(function()
      yaml.load[[dfkljdfl:dfjkhdf:djfhdkfjh
      sdfdf:
      df]]
    end)
  end)

  it("should load a sample yaml file", function()
    local doc = yaml.loadfile('test/sample.yaml')
  end)

  it("should support anchors", function()
    local doc = yaml.loadfile('test/sample.yaml')
    assert.is.truthy(doc['ship-to'])
  end)

  it("should support sequences", function()
    local doc = yaml.loadfile('test/sample.yaml')
    assert.are.equals(2, #doc.items)
    assert.are.equals("A4786", doc.items[1].part_no)
  end)

  it("should support nested maps", function()
    local doc = yaml.loadfile('test/sample.yaml')
    assert.are.equals('Dorothy', doc.customer.given)
  end)

  it("should error on an invalid file", function()
    assert.has_error(function()
      yaml.loadfile('test/invalid.yaml')
    end)
  end)
end)

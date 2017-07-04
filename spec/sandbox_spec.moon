sandbox = require "moonship.sandbox"

describe "moonship.sandbox", ->

  it "correctly load good function", ->
    expected = "hello world"
    fn = sandbox.loadstring "return \"hello world\""
    actual = fn!
    assert.same expected, actual

  it "fail to load bad function", ->
    expected = nil
    actual = sandbox.loadstring "asdf"
    assert.same expected, actual

  it "fail to execute restricted function", ->
    expected = "ffail"
    data = "local function hi()\n"
    data ..= "  return 'hello world'\n"
    data ..= "end\nreturn string.dump(hi)"
    ignore, actual = sandbox.exec data, expected
    hasMatch = actual\match(expected)

    -- actual is error message
    assert.same expected, hasMatch

  it "correctly execute good function", ->
    expected = "hello world"
    fn = sandbox.loadstring_safe "return string.gsub('hello cruel world', 'cruel ', '')"
    actual = fn!
    assert.same expected, actual


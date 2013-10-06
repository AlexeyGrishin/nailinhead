
calc = require('../src/puzzle/calc')

describe "puzzle utils", ->
  it "shall correctly process points", ->
    expect(calc.p(4, 3)).toEqual({x:4, y:3})
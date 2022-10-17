local Output = require("lua.executor.output")

describe("Executor", function()
  describe("clean_lines", function()
    it("strips out empty lines at the beginning of the input only", function()
      local input = { "", "hello", "", "world" }
      local output = Output._clean_lines(input)
      assert.are.same(output, { "hello", "", "world" })
    end)

    it("strips out new lines at the beginning of the input only", function()
      local input = { "\r", "\n", "hello", "\n", "world" }
      local output = Output._clean_lines(input)
      assert.are.same(output, { "hello", "\n", "world" })
    end)
  end)
end)

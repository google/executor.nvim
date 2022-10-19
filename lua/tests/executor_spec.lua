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

  describe("filtering", function()
    it("uses the provided filter function to remove lines", function()
      local input = { "hello", "world" }
      local filter_function = spy.new(function(cmd, lines)
        return { "new lines" }
      end)
      local output = Output.process_lines("npm test", filter_function, input)
      assert.are.same(output, { "new lines" })
      assert.spy(filter_function).was_called_with("npm test", input)
    end)
  end)
end)

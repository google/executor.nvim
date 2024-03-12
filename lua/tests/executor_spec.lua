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
      local filter_function = spy.new(function()
        return { "new lines" }
      end)
      local output = Output.process_lines("npm test", filter_function, input)
      assert.are.same(output, { "new lines" })
      assert.spy(filter_function).was_called_with("npm test", input)
    end)
  end)

  describe("statusline", function()
    local statusline_config = {
      prefix_text = "prefix_text",
      icons = {
        in_progress = ".",
        failed = "F",
        passed = "P",
      },
    }
    it("returns nothing if there is no prior run and we are not running", function()
      local output = Output.statusline_output({
        last_exit_code = nil,
        running = false,
      }, statusline_config)
      assert.are.same(output, "")
    end)

    it("returns the prefix + in progress icon if we are running", function()
      local output = Output.statusline_output({
        last_exit_code = nil,
        running = true,
      }, statusline_config)
      assert.are.same(output, "[prefix_text.]")
    end)

    it("returns prefix + in progress if we are running even if there is prior output", function()
      local output = Output.statusline_output({
        last_exit_code = 0,
        running = true,
      }, statusline_config)
      assert.are.same(output, "[prefix_text.]")
    end)

    it("returns the prefix + failed text if the last run failed", function()
      local output = Output.statusline_output({
        last_exit_code = 1,
        running = false,
      }, statusline_config)
      assert.are.same(output, "[prefix_textF]")
    end)

    it("returns prefix + succeeded text if the last run succeeded", function()
      local output = Output.statusline_output({
        last_exit_code = 0,
        running = false,
      }, statusline_config)
      assert.are.same(output, "[prefix_textP]")
    end)
  end)
end)

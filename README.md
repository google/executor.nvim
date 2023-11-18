# Executor.nvim

_This is not an officially supported Google product._

Executor.nvim is a plugin that allows you to run command line tasks in the
background and be notified of results.

It is primarily designed for running tests, but any command line task can be
run using it.

Once the task is run, you can see the output in a split:

https://user-images.githubusercontent.com/193238/196712287-d374d435-fafd-4347-ad0b-7a44bd6fb1b4.mov

Or in a popup:

https://user-images.githubusercontent.com/193238/196712389-5884f468-20c9-4f2b-9919-c14d9f1ac42e.mov

## Installation

Install via your favourite plugin manager. **You also need to install
[`nui.nvim`](https://github.com/MunifTanjim/nui.nvim)** as this plugin depends
on it.

And then call the `setup` method:

```lua
require("executor").setup({})
```

## Usage

A typical workflow looks like:

1. `:ExecutorRun`: runs your given task. If it's the first time you've run it,
   you will be prompted for a command. After that, it will remember and re-use
   your command (See `:ExecutorSetCommand` if you'd like to change it).

2. The task will run in the background. You will get a small notification when
   the task has finished, and it will tell you if it was a success or not. This
   is based on the exit code of the command you ran.

3. You can use `:ExecutorShowDetail` to reveal the detail window showing the
   task output. By default this will open in a split window on the right hand
   side, but it can be configured to use a floating popup. The size and
   position of the split can be configured also.

4. `:ExecutorHideDetail` will hide the detail window. By default it will open
   in a floating window, but it can be configured to use a split too.

5. `:ExecutorToggleDetail` will hide the detail view if it is visible,
   otherwise it will show it.

## Key mappings

No keys are bound by default; it is left up to you to bind your preferred keys
to each option.

Available commands:

- `ExecutorRun`: run the stored command. Will prompt for the command if it
  does not exist. Use `<Esc>` or `q` in the initial text prompt to cancel.

- `ExecutorSetCommand`: change the command that runs when `ExecutorRun` is
  invoked. You can use `<Esc>` or `q` in normal mode to cancel this command.

- `ExecutorShowDetail`: reveal the details window for the last execution run.

- `ExecutorHideDetail`: hide the details window for the last execution run.

- `ExecutorToggleDetail`: toggle the visibility of the details window.

- `ExecutorSwapToSplit`: changes your view setting to render in a split, not a
  popup. Useful if you prefer a popup most of the time but want to temporarily
  swap for a particular task.

- `ExecutorSwapToPopup`: changes your view setting to render in a popup, not a
  split. Useful if you prefer a popup most of the time but want to temporarily
  swap for a particular task.

- `ExecutorShowPresets`: shows the preset commands set in config.

- `ExecutorShowHistory`: shows the previous commands run in the session.

- `ExecutorReset`: will clear the output from the statusline and clear the
  stored command. Useful if your last run was a while ago, and the status
  output on your statusline is no longer relevant.

- `ExecutorOneOff [cmd]`: runs the provided command and shows the results, but does not overwrite your stored command.

These options are all available via the Lua API also:

```lua
local executor = require("executor")

exector.commands.reset()
exector.commands.swap_to_split()
exector.commands.swap_to_popup()
exector.commands.show_detail()
exector.commands.hide_detail()
exector.commands.toggle_detail()
exector.commands.set_command()
exector.commands.run()
exector.commands.show_presets()
exector.commands.show_history()
exector.commands.run_one_off(cmd)
```

You can therefore map the Vim commands to a key:

```lua
vim.api.nvim_set_keymap("n", "<leader>er", ":ExecutorRun<CR>", {})
vim.api.nvim_set_keymap("n", "<leader>ev", ":ExecutorToggleDetail<CR>", {})
```

Or use the Lua API:

```lua
local executor = require('executor')

vim.keymap.set("n", "<leader>er", function()
  executor.commands.run()
end)
```

## Configuration

`setup` takes a Lua table with the following options. The options provided are
the default options.

```lua
require('executor').setup({
 -- View details of the task run in a split, rather than a popup window.
 -- Set this to `false` to use a popup.
 use_split = true,

  -- Configure the width of the input prompt when setting a command.
  input = {
    width = math.floor(vim.o.columns * 4/5),
    -- Border styles
   border = {
      style = "rounded",
      padding = {
        top = 1,
        bottom = 1,
        left = 2,
        right = 2,
      },
   },
  },

 -- Configure the split. These are ignored if you are using a popup.
 split = {
   -- One of "top", "right", "bottom" or "left"
   position = "right",
   -- The number of columns to take up. This sets the split to 1/4 of the
   -- space. If you're using the split at the top or bottom, you could also
   -- use `vim.o.lines` to set this relative to the height of the window.
   size = math.floor(vim.o.columns * 1/4)
 },

 -- Configure the popup. These are ignored if you are using a split.
 popup = {
   -- Sets the width of the popup to 3/5ths of the screen's width.
   width = math.floor(vim.o.columns * 3/5),
   -- Sets the height to almost full height, allowing for some padding.
   height = vim.o.lines - 20,
    -- Border styles
   border = {
      padding = {
        top = 2,
        bottom = 2,
        left = 3,
        right = 3,
      },
      style = "rounded",
   },
 },
 -- Filter output from commands. See *filtering_output* below for more
 details.
 output_filter = function(command, lines)
   return lines
 end,

 notifications = {
   -- Show a popup notification when a task is started.
   task_started = true,
   -- Show a popup notification when a task is completed.
   task_completed = true,
    -- Border styles
   border = {
      padding = {
        top = 0,
        bottom = 0,
        left = 1,
        right = 1,
      },
      style = "rounded",
   },
 }
})
```

## Status line

Executor will pop up when a task succeeds or fails, but you can also include it
in your status line. Use `require('executor').statusline()` to generate the
output.

## Filtering output

Executor provides a hook for you to filter any output from a task before it's
shown to you. This can be useful if a command outputs debugging lines that you
want to avoid, and cannot be configured via command line flags.

Note: you should always try to configure this via the command itself; this
option is designed as a last resort.

To add filtering, define the `output_filter` configuration function. This
function takes two arguments:

- `command`: this is a string that is the command that was run. This allows
  you to configure filtering conditionally based on commands.

- `lines`: this is a Lua table containing all the lines from the output.

The function should return a Lua table containing all the lines you want to
keep.

For example, this function removes any lines that contain the string "foo", if
the command was "npm test":

```lua
output_filter = function(command, lines)
  if command == "npm test" then
    local kept_lines = {}
    for _, line in ipairs(lines) do
      if string.substr(line, "foo") == nil then
        table.insert(kept_lines, line)
      end
    end
    return kept_lines
  end

  return lines
end
```

You have a lot of freedom here, whatever table of lines you return will be
used, so you are free to add/edit/remove lines as required.

## Preset commands

To save yourself repeating commands in the same directory, you can store them
and select them via a prompt.

Pass a table to the `preset_commands` config setting. Each key should be a
directory name, or a partial path (it will be matched against the current
working directory). The value should be a table of commonly used tasks:

```lua
preset_commands = {
  ["executor.nvim"] = {
    "make test",
  },
}
```

You can use `:ExecutorShowPresets` to bring up a UI with these options in.
Selecting one (using `Enter`) will cause it to be set as the default command
and then run. You can hit `ESC` to close the menu and not execute any task.

You can also define a command as a function by passing a table with a `cmd` key:

```lua
preset_commands = {
  ["executor.nvim"] = {
    {
      cmd = function()
        -- Use bufnr 0 to use current buffer.
        local buf_name = vim.api.nvim_buf_get_name(0)
        return "echo 'Buffer name:'" .. buf_name
      end,
    },
  },
}
```

If you have a command that you need to tweak before running, you can set it to be partial:

```lua
preset_commands = {
  ["executor.nvim"] = {
    { partial = true, cmd = "make test --filter="},
  },
}
```

When you pick a partial preset from the list you will then be presented with an input box where you can edit the command before applying it. You can define `cmd` here as a string or a function.

## One-off commands

You may have tasks you want to often run (such as a build script) but not use as your saved Executor task. In this case you can use `:ExecutorOneOff`, passing the command with it:

```
:ExecutorOneOff npm run build
```

This will execute `npm run build`, but not overwrite your saved task.

You may want to bind common tasks to a keybinding:

```lua
vim.api.nvim_set_keymap("n", "<leader>b", ":ExecutorOneOff npm run build<CR>", {})
```

## Historical commands

Using `:ExecutorShowHistory` will reveal a popup menu which shows all the
commands you have used Executor to run (limited to that session only - they are
not persisted). Picking one of these options will then set it as the new
default task and run it.

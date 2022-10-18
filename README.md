# Executor.nvim

_This is not an officially supported Google product._

Executor.nvim is a plugin that allows you to run command line tasks in the
background and be notified of results.

It is primarily designed for running tests, but any command line task can be
run using it.

## Installation

Install via your favourite plugin manager. **You also need to install
[`nui.nvim`](https://github.com/MunifTanjim/nui.nvim)** as this plugin depends
on it.

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

**There are no mappings provided by default, you should set these yourself.**

For example:

```lua
vim.api.nvim_set_keymap("n", "<leader>er", ":ExecutorRun<CR>", {})
vim.api.nvim_set_keymap("n", "<leader>ev", ":ExecutorToggleDetail<CR>", {})
```

## Configuration

You can configure between using a popup window and a split, and adjust their
sizes.
See `:h executor.nvim` for full details.


# Executor.nvim

This is not an officially supported Google product

Executor.nvim is a plugin that allows you to run command line tasks in the
background and be notified of results.

It is primarily designed for running tests, but any task can be run using it.

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
   task output. By default this will open in a floating window, but it can be
   configured to use a split too.

4. `:ExecutorHideDetail` will hide the detail window. By default it will open
   in a floating window, but it can be configured to use a split too.

5. `:ExecutorToggleDetail` will hide the detail view if it is visible,
   otherwise it will show it.

## Configuration

You can configure the plugin to use a split, rather than a popup. See `:h
executor.nvim` for full details.


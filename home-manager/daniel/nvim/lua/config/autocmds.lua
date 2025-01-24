-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
vim.api.nvim_create_autocmd({"BufEnter"}, {
    callback = function(event)
        local root_folder = vim.fs.find({".git", "package.json", ".gitignore"}, { upward = true, stop = vim.loop.os_homedir() })[1]
        local root_name = root_folder and vim.fs.basename(vim.fs.dirname(root_folder)) or ""

        local title = root_name
        if event.file ~= "" then
            title = string.format("%s: %s", root_name, vim.fs.basename(event.file))
        end

        vim.fn.system({"wezterm", "cli", "set-tab-title", title})
    end,
})


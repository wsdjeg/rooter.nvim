vim.api.nvim_create_user_command('Rooter', function(opt)
    if opt.args == 'clear' then
        require('rooter').clear()
    else
        require('rooter').current_root()
    end
end, { nargs = '*' })

vim.api.nvim_create_user_command('Rooter', function(opt)
    if opt.args == 'clear' then
        require('rooter').clear()
    elseif #opt.fargs >= 2 and opt.fargs[1] == 'kill' then
        for i = 2, #opt.fargs do
            require('rooter').kill_project(opt.fargs[i])
        end
    else
        require('rooter').current_root()
    end
end, { nargs = '*' })

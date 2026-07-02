return {
  {
    "nvimdev/dashboard-nvim",
    lazy = false,
    opts = function()
      local logo = [[
 ▄▀▀▀▀▀▀▀▀▀█  ▄▀▀▀▀▀▀▀▀▀█ █▀▀▀▀▀▀▀▀▀▄   ▄▀▀▀▀▀▀▀▀▀█ █▀▀▀▀█
█·   ▄▄▄▄▄▄█ █   .▄▄   ∙▀ ▀    ▄▄  ∙ █ █·   ▄▄▄▄▄▄█ ▀    ▓
▓  . ▓ ▄▄▄▄▄ ▓    ▐▄▌.  ▓ ▓    ▓▄▌   ▓ ▓  . ▓ ▄▄▄▄▄ ▓    ▓
▒ ∙  ▒ ▄   ▒ ▒∙ . ▄▄▄   ▒ ▒   ·▄▄▄  ▀▄ ▒ ∙  ▒ ▄   ▒ ▒   ·▒
░    ░▄░   ░ ░    ░ ░  ·░ ░ .  ░ ░  .░ ░    ░▄░   ░ ░ .  ░
█    .    ·█ █ .  █ █   █ █    █ █∙  █ █    .    ·█ █    █
█▄▄▄▄▄▄▄▄▄▄█ █▄▄▄▄█ █▄▄▄█ █▄▄▄▄█ █▄▄▄█ █▄▄▄▄▄▄▄▄▄▄█ █▄▄▄▄█
      ]]

      logo = string.rep("\n", 8) .. logo .. "\n\n"

      local function set_dashboard_colors()
        -- Base fallback color, in case the gradient does not apply instantly
        vim.api.nvim_set_hl(0, "DashboardHeader", { fg = "#c084fc" })

        -- Custom gradient colors
        vim.api.nvim_set_hl(0, "DashboardLogoWhite", { fg = "#ffffff" })
        vim.api.nvim_set_hl(0, "DashboardLogoPurple1", { fg = "#f3e8ff" })
        vim.api.nvim_set_hl(0, "DashboardLogoPurple2", { fg = "#d8b4fe" })
        vim.api.nvim_set_hl(0, "DashboardLogoPurple3", { fg = "#c084fc" })
        vim.api.nvim_set_hl(0, "DashboardLogoPurple4", { fg = "#a855f7" })
        vim.api.nvim_set_hl(0, "DashboardLogoPurple5", { fg = "#7e22ce" })
      end

      local function apply_logo_gradient(bufnr)
        bufnr = bufnr or vim.api.nvim_get_current_buf()

        if not vim.api.nvim_buf_is_valid(bufnr) then
          return
        end

        local ft = vim.bo[bufnr].filetype
        if ft ~= "dashboard" then
          return
        end

        set_dashboard_colors()

        local ns = vim.api.nvim_create_namespace("dashboard_logo_gradient")
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

        for row, line in ipairs(lines) do
          -- Only touch the logo lines, not the dashboard buttons/footer
          if
            line:find("▀")
            or line:find("▄")
            or line:find("█")
            or line:find("▓")
            or line:find("▒")
            or line:find("░")
          then
            local char_count = vim.fn.strchars(line)

            for char_index = 0, char_count - 1 do
              local ch = vim.fn.strcharpart(line, char_index, 1)
              local col = vim.fn.byteidx(line, char_index)
              local next_col = vim.fn.byteidx(line, char_index + 1)

              if next_col == -1 then
                next_col = #line
              end

              if col >= 0 and ch ~= " " then
                local hl

                -- Force the small inner dots to white
                if ch == "." or ch == "·" or ch == "∙" then
                  hl = "DashboardLogoWhite"
                -- Left-to-right white/purple gradient
                elseif char_index < 12 then
                  hl = "DashboardLogoWhite"
                elseif char_index < 24 then
                  hl = "DashboardLogoPurple1"
                elseif char_index < 36 then
                  hl = "DashboardLogoPurple2"
                elseif char_index < 48 then
                  hl = "DashboardLogoPurple3"
                elseif char_index < 60 then
                  hl = "DashboardLogoPurple4"
                else
                  hl = "DashboardLogoPurple5"
                end

                vim.api.nvim_buf_set_extmark(bufnr, ns, row - 1, col, {
                  end_col = next_col,
                  hl_group = hl,
                  priority = 10000,
                })
              end
            end
          end
        end
      end

      local group = vim.api.nvim_create_augroup("CustomDashboardGradient", { clear = true })

      -- Kanagawa/colorscheme may reset highlight groups, so define them again
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = function()
          set_dashboard_colors()
        end,
      })

      -- Reapply after dashboard renders
      vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter", "VimResized" }, {
        group = group,
        pattern = "*",
        callback = function(args)
          local bufnr = args.buf

          vim.defer_fn(function()
            apply_logo_gradient(bufnr)
          end, 20)

          vim.defer_fn(function()
            apply_logo_gradient(bufnr)
          end, 100)

          vim.defer_fn(function()
            apply_logo_gradient(bufnr)
          end, 300)
        end,
      })

      set_dashboard_colors()

      local opts = {
        theme = "doom",
        hide = {
          statusline = false,
        },
        config = {
          header = vim.split(logo, "\n"),
          center = {
            { action = "lua LazyVim.pick()()", desc = " Find File", icon = " ", key = "f" },
            { action = "ene | startinsert", desc = " New File", icon = " ", key = "n" },
            { action = 'lua LazyVim.pick("oldfiles")()', desc = " Recent Files", icon = " ", key = "r" },
            { action = 'lua LazyVim.pick("live_grep")()', desc = " Find Text", icon = " ", key = "g" },
            { action = "lua LazyVim.pick.config_files()()", desc = " Config", icon = " ", key = "c" },
            { action = 'lua require("persistence").load()', desc = " Restore Session", icon = " ", key = "s" },
            { action = "LazyExtras", desc = " Lazy Extras", icon = " ", key = "x" },
            { action = "Lazy", desc = " Lazy", icon = "󰒲 ", key = "l" },
            {
              action = function()
                vim.api.nvim_input("<cmd>qa<cr>")
              end,
              desc = " Quit",
              icon = " ",
              key = "q",
            },
          },
          footer = function()
            local stats = require("lazy").stats()
            local ms = math.floor(stats.startuptime * 100 + 0.5) / 100
            return { "⚡ Neovim loaded " .. stats.loaded .. "/" .. stats.count .. " plugins in " .. ms .. "ms" }
          end,
        },
      }

      for _, button in ipairs(opts.config.center) do
        button.desc = button.desc .. string.rep(" ", 43 - #button.desc)
        button.key_format = "  %s"
      end

      if vim.o.filetype == "lazy" then
        vim.api.nvim_create_autocmd("WinClosed", {
          pattern = tostring(vim.api.nvim_get_current_win()),
          once = true,
          callback = function()
            vim.schedule(function()
              vim.api.nvim_exec_autocmds("UIEnter", { group = "dashboard" })
            end)
          end,
        })
      end

      return opts
    end,
  },
}

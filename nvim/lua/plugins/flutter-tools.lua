return {
  "akinsho/flutter-tools.nvim",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "stevearc/dressing.nvim", -- optional for vim.ui.select
  },
  config = function()
    -- Resolve the host machine's local IP so the app can reach the API
    local function get_local_ip()
      local handle = io.popen("ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null")
      if not handle then return "10.0.2.2" end
      local ip = handle:read("*a"):gsub("%s+", "")
      handle:close()
      return ip ~= "" and ip or "10.0.2.2"
    end

    -- Debug mode (simulator or device with JIT support)
    vim.keymap.set("n", "<leader>FS", function()
      local ip = get_local_ip()
      vim.cmd(string.format(
        "FlutterRun --dart-define=API_BASE_URL=http://%s:3000 --dart-define=FRONTEND_URL=http://%s:3001",
        ip, ip
      ))
    end, { desc = "Flutter Run (debug)" })

    -- Physical device (profile mode — AOT, no JIT issues on iOS 26+)
    -- Uses terminal instead of FlutterRun to avoid build path mismatch.
    -- <leader>FP reuses the same vsplit after <leader>FQ so we don't
    -- accumulate splits on repeated start/quit cycles.
    local _profile_term_buf = nil

    --- True if the profile terminal buffer has a running job.
    local function is_profile_alive()
      if not _profile_term_buf or not vim.api.nvim_buf_is_valid(_profile_term_buf) then
        return false
      end
      local ok, chan = pcall(vim.api.nvim_buf_get_var, _profile_term_buf, "terminal_job_id")
      if not ok or not chan then return false end
      local pid_ok, pid = pcall(vim.fn.jobpid, chan)
      return pid_ok and pid > 0
    end

    --- Find the window showing a buffer, or nil.
    local function find_win(buf)
      for _, w in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(w) == buf then return w end
      end
    end

    --- Send a key to the profile terminal (for hot-restart, quit, etc.)
    local function send_to_profile_term(key)
      if is_profile_alive() then
        local chan = vim.bo[_profile_term_buf].channel
        if chan and chan > 0 then
          vim.fn.chansend(chan, key)
          return true
        end
      end
      vim.notify("No active profile Flutter session", vim.log.levels.WARN)
      return false
    end

    vim.keymap.set("n", "<leader>FP", function()
      if is_profile_alive() then
        -- Process still running — just focus the existing window
        local win = find_win(_profile_term_buf)
        if win then
          vim.api.nvim_set_current_win(win)
        else
          -- Buffer alive but hidden — reopen in the same split position
          vim.cmd("botright vsplit")
          vim.api.nvim_win_set_buf(0, _profile_term_buf)
        end
      else
        -- No running session — start a fresh one, reusing the window if possible
        local win = _profile_term_buf and find_win(_profile_term_buf)
        if win then
          -- Reuse the existing split (old process ended)
          vim.api.nvim_set_current_win(win)
        else
          vim.cmd("botright vsplit")
        end
        local ip = get_local_ip()
        vim.cmd("terminal " .. string.format(
          "cd %s && flutter run --profile --dart-define=API_BASE_URL=http://%s:3000 --dart-define=FRONTEND_URL=http://%s:3001",
          vim.fn.getcwd(), ip, ip
        ))
        _profile_term_buf = vim.api.nvim_get_current_buf()
      end
    end, { desc = "Flutter Run (profile, physical device)" })

    vim.keymap.set("n", "<leader>FQ", function()
      if not send_to_profile_term("q") then vim.cmd("FlutterQuit") end
    end, { desc = "Flutter Quit" })

    vim.keymap.set("n", "<leader>FR", function()
      if not send_to_profile_term("R") then vim.cmd("FlutterRestart") end
    end, { desc = "Flutter Restart" })
    vim.keymap.set("n", "<leader>FPR", function()
      send_to_profile_term("r")
    end, { desc = "Flutter Hot Reload (profile)" })
    vim.keymap.set("n", "<leader>FLR", ":FlutterLspRestart <CR>", {})
    vim.keymap.set("n", "<leader>FD", ":FlutterDevTools <CR>", {})
    require("flutter-tools").setup({
      decorations = {
        statusline = {
          app_version = true,
          device = true,
        },
      },
      dev_tools = {
        autostart = true, -- autostart devtools server if not detected
        auto_open_browser = false, -- Automatically opens devtools in the browser
      },
      lsp = {
        color = { -- show the derived colours for dart variables
          enabled = true, -- whether or not to highlight color variables at all, only supported on flutter >= 2.10
        },
      },
    })
  end,
}

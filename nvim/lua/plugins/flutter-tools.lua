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

    vim.keymap.set("n", "<leader>FS", function()
      local ip = get_local_ip()
      vim.cmd(string.format(
        "FlutterRun --dart-define=API_BASE_URL=http://%s:3000 --dart-define=FRONTEND_URL=http://%s:3001",
        ip, ip
      ))
    end, { desc = "Flutter Run with local IP" })
    vim.keymap.set("n", "<leader>FQ", ":FlutterQuit <CR>", {})
    vim.keymap.set("n", "<leader>FR", ":FlutterRestart <CR>", {})
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

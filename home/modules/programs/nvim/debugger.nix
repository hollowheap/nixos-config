{ pkgs, ... }:
{
  programs.nvf.settings.vim = {
    debugger = {
      nvim-dap = {
        enable = true;
        ui = {
          enable = true;
          autoStart = false;
        };
      };
    };

    lazy.plugins = {
      "nvim-dap-virtual-text" = {
        lazy = false;
        package = pkgs.vimPlugins.nvim-dap-virtual-text;
        setupModule = "nvim-dap-virtual-text";
        setupOpts = { };
      };
    };

    binds.whichKey.register = {
      "<leader>d" = "+Debugger";
      "<leader>db" = "Toggle Breakpoint";
      "<leader>dc" = "Continue / Start";
      "<leader>di" = "Step Into";
      "<leader>do" = "Step Over";
      "<leader>dO" = "Step Out";
      "<leader>dt" = "Terminate Debugger";
      "<leader>dr" = "Restart Debugger";
      "<leader>du" = "Toggle DAP UI";
      "<leader>dp" = "Toggle Profiler";
      "<leader>dP" = "Profiler Scratch";
    };

    keymaps = [
      {
        key = "<leader>db";
        lua = true;
        action = "function() require('dap').toggle_breakpoint() end";
        mode = "n";
        desc = "Toggle Breakpoint";
      }
      {
        key = "<leader>dc";
        lua = true;
        action = "function() require('dap').continue() end";
        mode = "n";
        desc = "Continue / Start";
      }
      {
        key = "<leader>di";
        lua = true;
        action = "function() require('dap').step_into() end";
        mode = "n";
        desc = "Step Into";
      }
      {
        key = "<leader>do";
        lua = true;
        action = "function() require('dap').step_over() end";
        mode = "n";
        desc = "Step Over";
      }
      {
        key = "<leader>dO";
        lua = true;
        action = "function() require('dap').step_out() end";
        mode = "n";
        desc = "Step Out";
      }
      {
        key = "<leader>dt";
        lua = true;
        action = "function() require('dap').terminate() end";
        mode = "n";
        desc = "Terminate Debugger";
      }
      {
        key = "<leader>dr";
        lua = true;
        action = "function() require('dap').restart() end";
        mode = "n";
        desc = "Restart Debugger";
      }
      {
        key = "<leader>du";
        lua = true;
        action = "function() require('dapui').toggle() end";
        mode = "n";
        desc = "Toggle DAP UI";
      }
      {
        key = "<leader>ds";
        lua = true;
        action = "function() require('dapui').float_element('scopes') end";
        mode = "n";
        desc = "Float scopes";
      }
      {
        key = "<leader>dS";
        lua = true;
        action = "function() require('dapui').float_element('stacks') end";
        mode = "n";
        desc = "Float stacks";
      }
      {
        key = "<leader>dw";
        lua = true;
        action = "function() require('dapui').float_element('watches') end";
        mode = "n";
        desc = "Float watches";
      }
      {
        key = "<leader>dB";
        lua = true;
        action = "function() require('dapui').float_element('breakpoints') end";
        mode = "n";
        desc = "Float breakpoints";
      }
      {
        key = "<leader>de";
        lua = true;
        action = "function() require('dapui').float_element('repl') end";
        mode = "n";
        desc = "Float REPL";
      }
      {
        key = "<leader>dp";
        lua = true;
        action = "function() Snacks.profiler.toggle() end";
        mode = "n";
        desc = "Toggle Profiler";
      }
      {
        key = "<leader>dP";
        lua = true;
        action = "function() Snacks.profiler.scratch() end";
        mode = "n";
        desc = "Profiler Scratch";
      }
    ];
  };
}

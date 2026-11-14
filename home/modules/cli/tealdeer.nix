{ ... }:
{
  programs.tealdeer = {
    enable = true;
    settings = {
      updates.auto_update = true;
      style = {
        description = {
          underline = false;
          bold = false;
          italic = false;
        };
        command_name = {
          foreground = "cyan";
          underline = false;
          bold = true;
          italic = false;
        };
        example_text = {
          foreground = "green";
          underline = false;
          bold = false;
          italic = false;
        };
        example_code = {
          foreground = "blue";
          underline = false;
          bold = false;
          italic = false;
        };
        example_variable = {
          foreground = "yellow";
          underline = true;
          bold = false;
          italic = false;
        };
      };
    };
  };
}

{ ... }:
{
  programs.gpg = {
    enable = true;
    settings = {
      "default-key" = "41F93F1724EDF2D022E696E86B2A3C5D49EE0523";
      "keyid-format" = "long";
    };
  };
}

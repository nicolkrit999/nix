{
  flake,
  vars,
  ...
}:
{
  programs.plasma.input = {
    # 1. KEYBOARD
    keyboard = {
      layouts = [
        {
          layout = vars.keyboardLayout;
          variant = vars.keyboardVariant;
        }
      ];
      numlockOnStartup = "on";
    };

    mice = vars.kdeMice or [ ];
    touchpads = vars.kdeTouchpads or [ ];
  };
}

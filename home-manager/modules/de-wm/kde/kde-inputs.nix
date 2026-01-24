{ flake, vars, ... }: {
  programs.plasma.input = {
    # 1. KEYBOARD
    keyboard = {
      layouts = [{
        layout = vars.keyboardLayout or "us";
        variant = vars.keyboardVariant or "";
      }];
      numlockOnStartup = "on";
    };

    mice = vars.kdeMice or [ ];
    touchpads = vars.kdeTouchpads or [ ];
  };
}

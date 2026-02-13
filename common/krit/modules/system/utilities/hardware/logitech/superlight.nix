{ pkgs, ... }:

{
  services.keyd = {
    enable = true;
    keyboards = {
      superlight = {
        ids = [ "046d:c54d" ]; # Superlight Receiver ID
        settings = {
          main = {
            # 🖱️ Side Button 1 (Back) -> Copy
            # keyd monitor called this "mouse1"
            mouse1 = "C-c";

            # 🖱️ Side Button 2 (Forward) -> Paste
            # keyd monitor called this "mouse2"
            mouse2 = "C-v";
          };
        };
      };
    };
  };
}

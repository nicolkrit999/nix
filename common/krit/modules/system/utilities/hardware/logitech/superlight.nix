{ ... }:

{
  services.keyd = {
    keyboards = {
      superlight = {
        ids = [ "046d:c54d" ]; # Superlight Receiver ID
        settings = {
          main = {
            # 🖱️ Side Button 1 (Back) -> Copy
            mouse1 = "C-c";

            # 🖱️ Side Button 2 (Forward) -> Paste
            mouse2 = "C-v";
          };
        };
      };
    };
  };
}

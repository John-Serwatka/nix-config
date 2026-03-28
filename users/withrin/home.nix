# users/withrin/home.nix — Home Manager configuration for withrin
{ pkgs, ... }:

{
  home.username      = "withrin";
  home.homeDirectory = "/home/withrin";
  home.stateVersion  = "25.05";

  programs.bash.enable = true;

 programs.git = {
   enable = true;

   userName = "John Serwatka";
   userEmail = "johnchrisserwatka@gmail.com";

   includes = [
     {
       condition = "gitdir:/home/withrin/code/**";
       contents = {
         user = {
           name = "John Serwatka";
           email = "jserwatka@pocketlorestudios.com";
         };
       };
     }
   ];
 };
  home.packages = with pkgs; [
    bat
  ];
}
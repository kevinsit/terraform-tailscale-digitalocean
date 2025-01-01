# shell.nix
{ pkgs ? import <nixpkgs> {
    # Enable unfree packages
    config = { allowUnfree = true; };
  }
}:

pkgs.mkShell {
  buildInputs = [
    pkgs.terraform
    # Add other packages here. If any are unfree, they will be allowed.
    # For example:
    # pkgs.someUnfreePackage
  ];

  # Optional: Set environment variables or other shell configurations
  shellHook = ''
    export TF_LOG=DEBUG
    echo "Terraform environment is ready."
  '';
}
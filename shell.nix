{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.pwgen
    pkgs.kubectl
    pkgs.cargo
    pkgs.kubernetes-helm
    pkgs.helmfile
    pkgs.git
    pkgs.minikube
  ];
}


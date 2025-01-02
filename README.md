## Background

I need VPN access, but IP addresses from most VPN providers are already tagged by IP location
database as proxies. Using the code in this repository, I can bring up a Tailscale exit node in 
DigitalOcean, so that I can route my traffic through DigitalOcean without getting tagged as
a proxy user.

## Assumptions

You already have a `ed25519` SSH key pair created under `~/.ssh`. If you wish to use RSA, please
modify the `ssh_public_key_file` and `ssh_private_key_file` in your `terraform.tfvars` file
(more on this later):
```
ssh_public_key_file = "~/.ssh/id_ed25519.pub"
ssh_private_key_file = "~/.ssh/id_ed25519"
```

## How to create an exit node

1. Run `nix-shell` to install the shell dependencies like Terraform
2. Make a copy of `terraform.tfvars.example`, rename it to `terraform.tfvars` and fill in the variables.
3. Run `terraform init`
4. Run `terraform apply`, type `yes` to confirm the change.
5. Go to Tailscale admin console and approve the newly added exit node.
6. Make sure you keep the `terraform.tfstate` file in a safe place

### Auto-approving exit nodes

1. Go to Tailscale admin console
2. Under Access Control, edit your ACL policy and add the following block:
    ```
        "autoApprovers": {
            "exitNode": ["<user>"],
        },
    ```
   Replace `<user>` with the email associated with the Tailscale API key set in `terraform.tfvars`

## How to destroy an exit node

1. Run `nix-shell` to install shell dependencies
2. Run `terraform destroy`

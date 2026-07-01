# Remote state — create bucket before first terraform init
# See docs/setup/02-terraform-remote-state.md

terraform {
  backend "gcs" {
    bucket = "boutique-gke-tfstate"
    prefix = "boutique"
  }
}

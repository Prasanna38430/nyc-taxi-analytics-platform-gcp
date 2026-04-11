# Main Infrastructure Definitions

locals {
  project_id = var.gcp_project_id
  region     = var.gcp_region
  zone       = var.gcp_zone

  common_labels = {
    project     = lower(replace(var.project_name, " ", "-"))
    environment = var.environment
    managed_by  = "terraform"
  }
}

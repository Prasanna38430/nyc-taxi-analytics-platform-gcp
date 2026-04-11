# Dataproc internal communication firewall rule
resource "google_compute_firewall" "allow_dataproc_internal" {
  name    = "allow-dataproc-internal"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_tags = ["dataproc-cluster"]
  target_tags = ["dataproc-cluster"]

  lifecycle {
    ignore_changes = all
  }
}

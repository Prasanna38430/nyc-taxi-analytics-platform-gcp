# Custom Firewall Rule for Dataproc Internal Communication
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

  allow {
    protocol = "icmp"
  }

  source_ranges = ["0.0.0.0/0"]
  priority      = 1000
}

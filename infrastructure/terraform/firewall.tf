# Reference existing firewall rule (already created)
data "google_compute_firewall" "allow_dataproc_internal" {
  name = "allow-dataproc-internal"
}

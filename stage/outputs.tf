output "etl_host_ip" {
  description = "IP of VM, which hosts the ETL code"
  value       = google_compute_instance.etl_host.network_interface.0.access_config.0.nat_ip
}

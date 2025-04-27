provider "google" {
  project = "your-project-id"
  region  = "us-central1"
}

resource "google_compute_instance_template" "default" {
  name         = "instance-template"
  machine_type = "e2-micro"
  
  disk {
    auto_delete  = true
    boot         = true
    source_image = "projects/debian-cloud/global/images/family/debian-11"
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = "echo Hello, World > /var/www/html/index.html"
  tags = ["http-server"]
}

resource "google_compute_instance_group_manager" "default" {
  name               = "instance-group"
  base_instance_name = "instance"
  region             = "us-central1"
  version {
    instance_template = google_compute_instance_template.default.self_link
  }
  target_size = 2
}

resource "google_compute_health_check" "default" {
  name = "health-check"
  
  http_health_check {
    request_path = "/"
    port         = 80
  }
}

resource "google_compute_backend_service" "default" {
  name                  = "backend-service"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL"
  port_name             = "http"
  health_checks         = [google_compute_health_check.default.self_link]
  
  backend {
    group = google_compute_instance_group_manager.default.instance_group
  }
}

resource "google_compute_url_map" "default" {
  name            = "url-map"
  default_service = google_compute_backend_service.default.self_link
}

resource "google_compute_target_http_proxy" "default" {
  name    = "http-proxy"
  url_map = google_compute_url_map.default.self_link
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "http-forwarding-rule"
  target     = google_compute_target_http_proxy.default.self_link
  port_range = "80"
  load_balancing_scheme = "EXTERNAL"
  ip_protocol = "TCP"
}

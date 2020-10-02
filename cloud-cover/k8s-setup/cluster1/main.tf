variable "node_count" {
  default = "4"
}
# Provider
provider "google" {
  project     = "spicy-carbon"
}

resource "google_compute_instance" "kubeadm_k8s_singlecluster" {
  count        = var.node_count
  machine_type = "n1-standard-8"
  zone         = var.zone
  name         = "cc-k8s-${count.index}"

  tags = ["cc-k8s-poc"]

  boot_disk {
    initialize_params {
      image = "ubuntu-1804-lts"
    }
  }

  network_interface {
    subnetwork = var.subnet
    access_config = {
        Ephemeral IP
    }
  }

  service_account {
    email  = "halyard-service-account@spicy-carbon.iam.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/compute.readonly"]
  }
}


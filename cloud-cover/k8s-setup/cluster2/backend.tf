terraform {
  backend "gcs" {
    bucket = "venky-ilb"
    prefix = "/terraform/state/carbon/gcp-instances/cc-k8s-multicluster"
  }
}
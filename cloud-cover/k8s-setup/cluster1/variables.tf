
variable "zone" {
  description = "The zone that the machine should be created in"
  default     = "us-central1-a"
}

variable "project_name" {
  description = "The ID of the project"
  default     = "spicy-carbon"
}


variable "subnet" {
  description = "subnetwork"
  default     = "https://www.googleapis.com/compute/v1/projects/spicy-carbon/regions/us-central1/subnetworks/default"
}

variable "network_name" {
  description = "network_name"
  default     = "https://www.googleapis.com/compute/v1/projects/spicy-carbon/global/networks/default"
}
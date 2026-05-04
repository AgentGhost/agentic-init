variable "environment" {
  description = "Environment (dev/uat/prod)"
  type        = string
  default     = "prod"
}

variable "hcloud_token" {
  description = "Hetzner API token"
  type        = string
  sensitive   = true
}

variable "plane_project" {
  description = "Plane project UUID"
  type        = string
  sensitive   = true
}

variable "plane_api_key" {
  description = "Plane API key"
  type        = string
  sensitive   = true
}

variable "plane_url" {
  description = "Plane URL"
  type        = string
  default     = "http://localhost"
}

variable "kafka_brokers" {
  description = "Kafka broker addresses"
  type        = list(string)
  default     = ["localhost:9092"]
}

variable "ollama_host" {
  description = "Ollama host URL"
  type        = string
  default     = "http://host.docker.internal:11434"
}

variable "jenkins_url" {
  description = "Jenkins URL"
  type        = string
  default     = "http://localhost:8081"
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key"
  type        = string
  default     = "~/.ssh/id_rsa"
}
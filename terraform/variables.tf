variable "default_tags" {
  description = "Default tags to be applied to all resources"
  type        = map(string)
  default = {
    Project = "factorio-server-manager"
  }
}
variable "availability_zone" {
  description = "Availability zone for the subnet"
  type        = string
  default     = "us-east-1a"
}

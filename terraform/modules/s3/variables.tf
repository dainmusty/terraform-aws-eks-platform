variable "tags" {
  description = "A map of tags to assign to the bucket."
  type        = map(string)
  default     = {}
}

variable "resource_prefix" {
  description = "Prefix to be used for naming resources"
  type        = string
}

variable "log_bucket_name" {
  description = "Name of the logging bucket"
  type        = string
}

variable "operations_bucket_name" {
  description = "Name of the operations bucket"
  type        = string
}

variable "replication_bucket_name" {
  description = "Name of the replication destination bucket"
  type        = string
}

variable "operations_bucket_versioning_status" {
  description = "Versioning status for the operations bucket"
  type        = string
}

variable "replication_bucket_versioning_status" {
  description = "Versioning status for the replication destination bucket"
  type        = string
}

variable "log_bucket_versioning_status" {
  description = "Versioning status for the replication destination bucket"
  type        = string
}

variable "logging_prefix" {
  description = "Prefix for logging in the operations bucket"
  type        = string
}





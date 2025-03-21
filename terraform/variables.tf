variable "region" {
  description = "The region within which this tf deployment can be found"
  type        = string
}

variable "domain_name" {
  description = "The name of the domain"
  type        = string
}

variable "email_address" {
  description = "Email Address of deploying user"
  type        = string
}
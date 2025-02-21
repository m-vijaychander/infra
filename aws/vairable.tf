variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "pub_cidr_block" {
  description = "The CIDR block for the public subnet"
  type        = list(string)
  default     = ["10.0.0.0/20","10.0.64.0/20"]
}

variable "private_cidr_block" {
  description = "The CIDR block for the private subnet"
  type        = list(string)
  default     = ["10.0.128.0/20","10.0.192.0/20"]
}

variable "enable_nacl" {
    description = "Enable network ACL"
    type        = bool
    default     = true
}
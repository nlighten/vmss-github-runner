variable "vnet" {
  type        = string
  description = "Name of the vnet the runner subnet is part of."
}

variable "subnet" {
  type        = string
  description = "Name of the subnet the runners are situated in."
}

variable "vnet_resource_group" {
  type        = string
  description = "Name of the resource group the vnet is in."
}

variable "runner_resource_group" {
  type        = string
  description = "Name of the resource group the runners need to be in."
}

variable "location" {
  type        = string
  description = "Location (francecentral/westeurope)."
  default     = "westeurope"
}

variable "instance" {
  type        = string
  description = "Instance number"
  default     = "001"
}

variable "tags" {
  type        = map(string)
  description = "Default tags to be added for each resource."
  default = {
    owner       = "devnet"
    environment = "ae"
  }
}

variable "github_repo" {
  type        = string
  description = "Github repo to attach the runners to."
}

variable "min_runners" {
  type        = number
  description = "Minimal number of runners to maintain at all times. Must be larger than 0."
  default     = 1
}

variable "max_runners" {
  type        = number
  description = "Maximum number of runners. Must be < 30 for now."
  default     = 4
}

variable "target_available_runners_percent" {
  type        = number
  description = "Target percentage of runners not running jobs."
  default     = 25
}

variable "admin_pwd" {
  type        = string
  description = "Admin password for scaler and runner (temporary, to be replaced by SSH key)"
}

variable "runner_runas_user" {
  type        = string
  description = "Userid the runner runs under"
  default     = "ghrunner"
}

variable "runner_sku" {
  type        = string
  description = "SKU of the runner instances."
}

variable "runner_image_name" {
  type        = string
  description = "Name of the runner image to use"
}

variable "runner_labels" {
  type        = string
  description = "Comma separated list of labels to use for this runner"
}

variable "runner_image_size" {
  type        = number
  description = "Size of the runner image"
  default     = 86
}

variable "scaler_port" {
  type        = number
  description = "Port number the scaler is listening on."
  default     = 5000
}

variable "scaler_instances" {
  type        = number
  description = "Number of scaler instances to run."
  default     = 1
}

variable "scaler_log_level" {
  type        = string
  description = "Log level for the scaler app (info/debug)"
  default     = "info"
}

variable "scaler_sku" {
  type        = string
  description = "SKU of the runner instances."
  default     = "Standard_B1s"
}

variable "scaler_admin_user" {
  type        = string
  description = "Admin user for scaler"
  default     = "ghscaleradmin"
}

variable "scaler_runas_user" {
  type        = string
  description = "User for scaler process"
  default     = "ghscaler"
}

variable "ssh_public_key" {
  type        = string
  description = "Public ssh key for both scaler and runner admin user"
}

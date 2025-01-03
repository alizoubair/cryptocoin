variable "github_repository" {
  type        = string
  description = "GitHub repository identifier in the format org/repo"
}

variable "branch_name" {
  type        = string
  description = "Name of the branch to trigger the build"
}
 variable "aws_region" {
      description = "AWS region to deploy resources"
      type        = string
      default     = "ap-south-1" # Or your preferred region
    }

    variable "project_name" {
      description = "Name to prefix all resources"
      type        = string
      default     = "devops-app"
    }

    variable "public_key_path" {
      description = "Path to the public SSH key (e.g., ~/.ssh/my-devops-key.pub)"
      type        = string
    }

    variable "instance_type" {
      description = "EC2 instance type"
      type        = string
      default     = "t3.micro" # Free tier eligible
    }

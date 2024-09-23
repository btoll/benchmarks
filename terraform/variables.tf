variable "bucket_name" {
  default = "benchmarks1337"
}

variable "bucket_folders" {
  type = set(string)
  default = [
    "benchmarks/"
  ]
}


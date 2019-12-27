output "username" {
  value = "${var.project}"
}

output "password" {
  value = "${random_string.password.result}"
}


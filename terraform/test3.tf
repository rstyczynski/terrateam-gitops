resource "null_resource" "example3" {
  triggers = {
    # This resource will be recreated whenever the value of this trigger changes.
    trigger_key = "trigger_value4"
  }

  provisioner "local-exec" {
    command = "echo This is a local provisioner no.3c"
  }
}


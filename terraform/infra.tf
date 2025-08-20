provider "null" {
  version = "~> 3.0"
}

resource "null_resource" "example2" {
  triggers = {
    # This resource will be recreated whenever the value of this trigger changes.
    trigger_key = "trigger_value1"
  }

  provisioner "local-exec" {
    command = "echo This is a local provisioner no.2"
  }
}




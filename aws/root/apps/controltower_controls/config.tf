variable "enabled_safe_controls" {
  type = map(list(string))
}

//noinspection SpellCheckingInspection
variable "enabled_unsafe_controls" {
  type = map(map(string))
}

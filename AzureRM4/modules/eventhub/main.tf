# Due to lifecycle limitations inside of the modules we are using delete locks to ensure database delete security
# tflint-ignore: azurerm_resources_missing_prevent_destroy
resource "azurerm_eventhub" "this" {
  name              = var.eventhub_name
  namespace_id      = var.namespace_id
  partition_count   = var.partition_count
  message_retention = var.message_retention
  status            = var.status

  dynamic "capture_description" {
    for_each = var.capture_description != null ? [var.capture_description] : []
    content {
      enabled             = capture_description.value.enabled
      encoding            = capture_description.value.encoding
      interval_in_seconds = try(capture_description.value.interval_in_seconds, 300)
      size_limit_in_bytes = try(capture_description.value.size_limit_in_bytes, 314572800)
      skip_empty_archives = try(capture_description.value.skip_empty_archives, false)

      destination {
        name                        = capture_description.value.destination.name
        archive_name_format         = capture_description.value.destination.archive_name_format
        blob_container_name         = capture_description.value.destination.blob_container_name
        storage_account_id          = capture_description.value.destination.storage_account_id
        storage_authentication_type = try(capture_description.value.destination.storage_authentication_type, "SAS")
        storage_authentication_id   = try(capture_description.value.destination.storage_authentication_id, null)
      }
    }
  }
}

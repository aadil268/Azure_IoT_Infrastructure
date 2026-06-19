resource "azurerm_eventhub_namespace" "this" {
  name                          = var.namespace_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku                           = var.sku
  capacity                      = var.capacity
  auto_inflate_enabled          = var.auto_inflate_enabled
  maximum_throughput_units      = var.auto_inflate_enabled ? var.maximum_throughput_units : null
  public_network_access_enabled = var.public_network_access_enabled
  local_authentication_enabled  = var.local_authentication_enabled
  minimum_tls_version           = var.minimum_tls_version

  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  lifecycle {
    ignore_changes  = [tags]
    prevent_destroy = true
  }
}

resource "azurerm_eventhub" "this" {
  name              = var.eventhub_name
  namespace_id      = azurerm_eventhub_namespace.this.id
  partition_count   = var.partition_count
  message_retention = var.sku == "Premium" ? null : var.message_retention
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
        name                = capture_description.value.destination.name
        archive_name_format = capture_description.value.destination.archive_name_format
        blob_container_name = capture_description.value.destination.blob_container_name
        storage_account_id  = capture_description.value.destination.storage_account_id
      }
    }
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_eventhub_consumer_group" "this" {
  for_each = { for cg in var.consumer_groups : cg.name => cg }

  name                = each.value.name
  namespace_name      = azurerm_eventhub_namespace.this.name
  eventhub_name       = azurerm_eventhub.this.name
  resource_group_name = var.resource_group_name
  user_metadata       = try(each.value.user_metadata, null)
}

# Authorization rule for IoT Hub routing
resource "azurerm_eventhub_authorization_rule" "iothub_sender" {
  name                = "iothub-sender"
  namespace_name      = azurerm_eventhub_namespace.this.name
  eventhub_name       = azurerm_eventhub.this.name
  resource_group_name = var.resource_group_name

  listen = true
  send   = true
  manage = false
}

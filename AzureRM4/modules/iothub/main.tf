resource "azurerm_iothub" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  local_authentication_enabled  = var.local_authentication_enabled
  public_network_access_enabled = var.public_network_access_enabled
  min_tls_version               = var.min_tls_version

  sku {
    name     = var.sku_name
    capacity = var.sku_capacity
  }

  dynamic "identity" {
    for_each = var.identity != null ? [var.identity] : []
    content {
      type         = identity.value.type
      identity_ids = try(identity.value.identity_ids, null)
    }
  }

  # NOTE: Endpoints, routes, enrichments and fallback_route defined here CANNOT be
  # mixed with the corresponding azurerm_iothub_endpoint_*, azurerm_iothub_route,
  # azurerm_iothub_enrichment, or azurerm_iothub_fallback_route resources. Use one
  # approach consistently per IoT Hub to avoid spurious plan differences.

  dynamic "endpoint" {
    for_each = var.endpoints
    content {
      type                       = endpoint.value.type
      name                       = endpoint.value.name
      authentication_type        = try(endpoint.value.authentication_type, "keyBased")
      identity_id                = try(endpoint.value.identity_id, null)
      endpoint_uri               = try(endpoint.value.endpoint_uri, null)
      entity_path                = try(endpoint.value.entity_path, null)
      connection_string          = try(endpoint.value.connection_string, null)
      resource_group_name        = try(endpoint.value.resource_group_name, null)
      container_name             = try(endpoint.value.container_name, null)
      encoding                   = try(endpoint.value.encoding, null)
      file_name_format           = try(endpoint.value.file_name_format, null)
      batch_frequency_in_seconds = try(endpoint.value.batch_frequency_in_seconds, null)
      max_chunk_size_in_bytes    = try(endpoint.value.max_chunk_size_in_bytes, null)
    }
  }

  dynamic "route" {
    for_each = var.routes
    content {
      name           = route.value.name
      source         = route.value.source
      condition      = try(route.value.condition, "true")
      endpoint_names = route.value.endpoint_names
      enabled        = try(route.value.enabled, true)
    }
  }

  dynamic "enrichment" {
    for_each = var.enrichments
    content {
      key            = enrichment.value.key
      value          = enrichment.value.value
      endpoint_names = enrichment.value.endpoint_names
    }
  }

  dynamic "fallback_route" {
    for_each = var.fallback_route != null ? [var.fallback_route] : []
    content {
      source         = try(fallback_route.value.source, "DeviceMessages")
      condition      = try(fallback_route.value.condition, "true")
      endpoint_names = fallback_route.value.endpoint_names
      enabled        = try(fallback_route.value.enabled, true)
    }
  }

  dynamic "cloud_to_device" {
    for_each = var.cloud_to_device != null ? [var.cloud_to_device] : []
    content {
      max_delivery_count = try(cloud_to_device.value.max_delivery_count, 10)
      default_ttl        = try(cloud_to_device.value.default_ttl, "PT1H")

      dynamic "feedback" {
        for_each = try(cloud_to_device.value.feedback, null) != null ? [cloud_to_device.value.feedback] : []
        content {
          time_to_live       = try(feedback.value.time_to_live, "PT1H")
          max_delivery_count = try(feedback.value.max_delivery_count, 10)
          lock_duration      = try(feedback.value.lock_duration, "PT60S")
        }
      }
    }
  }

  lifecycle {
    ignore_changes  = [tags]
    prevent_destroy = true
  }
}

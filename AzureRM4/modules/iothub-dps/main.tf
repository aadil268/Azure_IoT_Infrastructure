resource "azurerm_iothub_dps" "this" {
  name                          = var.name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  allocation_policy             = var.allocation_policy
  public_network_access_enabled = var.public_network_access_enabled
  data_residency_enabled        = var.data_residency_enabled

  sku {
    name     = var.sku_name
    capacity = var.sku_capacity
  }

  dynamic "linked_hub" {
    for_each = var.linked_hubs
    content {
      connection_string       = linked_hub.value.connection_string
      location                = linked_hub.value.location
      apply_allocation_policy = try(linked_hub.value.apply_allocation_policy, true)
      allocation_weight       = try(linked_hub.value.allocation_weight, 1)
    }
  }

  dynamic "ip_filter_rule" {
    for_each = var.ip_filter_rules
    content {
      name    = ip_filter_rule.value.name
      ip_mask = ip_filter_rule.value.ip_mask
      action  = ip_filter_rule.value.action
      target  = try(ip_filter_rule.value.target, "all")
    }
  }

  lifecycle {
    ignore_changes = [tags]
  }
}

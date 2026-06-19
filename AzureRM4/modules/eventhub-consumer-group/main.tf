# Due to lifecycle limitations inside of the modules we are using delete locks to ensure database delete security
# tflint-ignore: azurerm_resources_missing_prevent_destroy
resource "azurerm_eventhub_consumer_group" "this" {
  name                = var.consumer_group_name
  namespace_name      = var.namespace_name
  eventhub_name       = var.eventhub_name
  resource_group_name = var.resource_group_name
  user_metadata       = var.user_metadata
}

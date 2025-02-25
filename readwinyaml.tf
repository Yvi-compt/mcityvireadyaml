locals{
 windows_app = flatten([
    for f in fileset("${path.module}/winconfigs", "*.yaml") :
    yamldecode(file("${path.module}/winconfigs/${f}"))["windows_apps"]
  ])
  windows_app_list = flatten([
    for app in local.windows_app : [
      for windowsapps in try(app.windows_apps, []) :{
        name=windowsapps.name
        os_type=windowsapps.os_type
        sku_name=windowsapps.sku_name     
      }
    ]
])
   /* waf_policy=[for f in fileset("${path.module}/configs", "[^_]*.yaml") : yamldecode(file("${path.module}/configs/${f}"))]
    waf_policy_list = flatten([
    for policy in local.waf_policy : [
      for policies in try(policy.listofwafpolicies, []) :{
        name=policies.name
        custom_rules=policies.custom_rules
        managed_rules=policies.managed_rules
        }
    ]
])*/
}



resource "azurerm_service_plan" "batcha07sp" {
  for_each            ={for sp in local.windows_app_list: "${sp.name}"=>sp }
  name                = each.value.name
  resource_group_name = azurerm_resource_group.azureresourcegroup.name
  location            = azurerm_resource_group.azureresourcegroup.location
  os_type             = each.value.os_type
  sku_name            = each.value.sku_name
}

resource "azurerm_windows_web_app" "batcha07webapp" {
  for_each            = azurerm_service_plan.batcha07sp
  name                = each.value.name
  resource_group_name = azurerm_resource_group.azureresourcegroup.name
  location            = azurerm_resource_group.azureresourcegroup.location
  service_plan_id     = each.value.id

  site_config {}
}

##############################################################################
# Key Management
##############################################################################

module "key_management" {
  for_each                  = var.disable_key_management == true ? {} : { "key_management" : true }
  source                    = "github.com/Cloud-Schematics/key-management-module"
  region                    = var.region
  prefix                    = var.prefix
  tags                      = var.tags
  service_endpoints         = var.service_endpoints
  resource_group_id         = var.key_management.resource_group_id
  use_hs_crypto             = var.key_management.use_hs_crypto
  use_data                  = var.key_management.use_data
  authorize_vpc_reader_role = var.key_management.authorize_vpc_reader_role
  name                      = var.key_management.name
  keys                      = var.keys
}

locals {
  key_management_service_name = var.key_management.use_hs_crypto == true ? "hs-crypto" : "kms"
}

##############################################################################

##############################################################################
# Object Storage
##############################################################################

module "cloud_object_storage" {
  source                      = "github.com/Cloud-Schematics/cos-module"
  region                      = var.region
  prefix                      = var.prefix
  tags                        = var.tags
  use_random_suffix           = var.cos_use_random_suffix
  service_endpoints           = var.service_endpoints
  key_management_service_guid = var.disable_key_management == false ? null : module.key_management["key_management"].key_management_guid
  key_management_service_name = var.disable_key_management == false ? null : local.key_management_service_name
  key_management_keys         = var.disable_key_management == false ? [] : module.key_management["key_management"].keys
}

##############################################################################

##############################################################################
# Key Management Outputs
##############################################################################

output "key_management_name" {
  description = "Name of key management service"
  value       = var.disable_key_management == false ? null : module.key_management["key_management"].key_management_name
}

output "key_management_crn" {
  description = "CRN for KMS instance"
  value       = var.disable_key_management == false ? null : module.key_management["key_management"].key_management_crn
}

output "key_management_guid" {
  description = "GUID for KMS instance"
  value       = var.disable_key_management == false ? null : module.key_management["key_management"].key_management_guid
}

output "key_rings" {
  description = "Key rings created by module"
  value       = var.disable_key_management == false ? null : module.key_management["key_management"].key_rings
}

output "keys" {
  description = "List of names and ids for keys created."
  value       = var.disable_key_management == false ? null : module.key_management["key_management"].keys
}

##############################################################################

##############################################################################
# Cloud Object Storage Variables
##############################################################################


output "cos_instances" {
  description = "List of COS resource instances with shortname, name, id, and crn."
  value       = module.cloud_object_storage.cos_instances
}

output "cos_buckets" {
  description = "List of COS bucket instances with shortname, instance_shortname, name, id, crn, and instance id."
  value       = module.cloud_object_storage.cos_buckets
}

output "cos_keys" {
  description = "List of COS bucket instances with shortname, instance_shortname, name, id, crn, and instance id."
  value       = module.cloud_object_storage.cos_keys
}

##############################################################################

##############################################################################
# Secrets Manager Outputs
##############################################################################

output "secrets_manager_name" {
  description = "Name of secrets manager instance"
  value       = var.secrets_manager.use_secrets_manager == true ? ibm_resource_instance.secrets_manager[0].name : null
}

output "secrets_manager_id" {
  description = "id of secrets manager instance"
  value       = var.secrets_manager.use_secrets_manager == true ? ibm_resource_instance.secrets_manager[0].id : null
}

output "secrets_manager_guid" {
  description = "guid of secrets manager instance"
  value       = var.secrets_manager.use_secrets_manager == true ? ibm_resource_instance.secrets_manager[0].guid : null
}

##############################################################################
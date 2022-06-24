# IBM Cloud Solution Engineering Cloud Services Module

This module is used to create and manage resources for Cloud Object Storage, Key Management, and Secrets Manager.

## Supported Components

- Key Management
    - Key Management Keys
    - Key Management Rings
    - Key Management Key Policies
- Cloud Object Storage
    - Object Storage Buckets
    - Object Storage Resource Keys
- Secrets Manager

---

## Table of Contents

1. [Module Level Variables](#module-level-variables)
2. [Key Management](#key-management)
    - [Key Management Variables](#key-management-variables)
3. [Cloud Object Storage](#cloud-object-storage)
    - [Object Storage Service Authorizations](#object-storage-service-authorizations)
    - [Object Storage Variables](#object-storage-variables)
4. [Secrets Manager](#secrets-manager)
5. [Module Outputs](#modue-outputs)

---

## Module Level Variables

The following variables are used for provisioning any of the components

Name              | Type         | Description                                                                                                                                                                                                                            | Default
----------------- | ------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------
prefix            | string       | A unique identifier for resources. Must begin with a lowercase letter and end with a lowercase letter or number. This prefix will be prepended to any resources provisioned by this template. Prefixes must be 16 or fewer characters. | 
region            | string       | Region where VPC will be created. To find your VPC region, use `ibmcloud is regions` command to find available regions.                                                                                                                | 
tags              | list(string) | List of tags to apply to resources created by this module.                                                                                                                                                                             | []
service_endpoints | string       | Service endpoints. Can be `public`, `private`, or `public-and-private`                                                                                                                                                                 | private

---

## Key Management

This module uses the [ICSE Key Management Module](https://github.com/Cloud-Schematics/key-management-module) to create and manage Key Management Resources

### Key Management Variables

```terraform

variable "disable_key_management" {
  description = "OPTIONAL - If true, key management resources will not be created."
  type        = bool
  default     = false
}

```
### Key Management Service Instance

The following variable is used to manage the key management service instance:

```terraform
variable "key_management" {
  description = "Configuration for Key Management Service"
  type = object({
    name                      = string
    use_hs_crypto             = optional(bool)
    use_data                  = optional(bool)
    authorize_vpc_reader_role = optional(bool)
    resource_group_id         = optional(string)
  })
  ...
}
```

Key Name                  | Description
--------------------------|------------
name                      | Name of the service, created services will have the prefix variable prepended to the beginning of the name
use_hs_crypto             | Will force data source to be used. If not true, will default to kms this module cannot create and initialize HPCS instances
use_data                  | Get a Key Protect instance from Data
authorize_vpc_reader_role | Add an IAM Service Authorization Policy to allow VPC block storage resource to be encrypted keys from this instance
resource_group_id         | Resource group for key management resources

### Key Management Keys

Management keys for this instance are created using the [keys variable](./variables.tf#L70)

```terraform
variable "keys" {
  description = "List of keys to be created for the service"
  type = list(
    object({
      name            = string           # Name of the key
      root_key        = optional(bool)   # is a root key
      payload         = optional(string)
      key_ring        = optional(string) # Any key_ring added will be created
      force_delete    = optional(bool)   # Force delete key. Will be true unless this value is set to `false`
      endpoint        = optional(string) # can be public or private
      iv_value        = optional(string) # (Optional, Forces new resource, String) Used with import tokens. The initialization vector (IV) that is generated when you encrypt a nonce. The IV value is required to decrypt the encrypted nonce value that you provide when you make a key import request to the service. To generate an IV, encrypt the nonce by running ibmcloud kp import-token encrypt-nonce. Only for imported root key.
      encrypted_nonce = optional(string) # The encrypted nonce value that verifies your request to import a key to Key Protect. This value must be encrypted by using the key that you want to import to the service. To retrieve a nonce, use the ibmcloud kp import-token get command. Then, encrypt the value by running ibmcloud kp import-token encrypt-nonce. Only for imported root key.
      policies = optional(
        object({
          rotation = optional(
            object({
              interval_month = number
            })
          )
          dual_auth_delete = optional(
            object({
              enabled = bool
            })
          )
        })
      )
    })
  )
  ...
}
```

---

## Cloud Object Storage

This template uses the [ICSE Cloud Object Storage Module](https://github.com/Cloud-Schematics/cos-module) to create and manage Object Storage resources.

### Object Storage Service Authorizations

If this module is using key management, an IAM Service to Service authorization is created to allow each Object Storage instance to Read from the key management service. This authorization allows COS buckets to be encrypted with a Key Management key. Use the `kms_key` bucket object key to specify a key for each bucket to use.

### Object Storage Variables

COS instances, buckets, and key deployments are created and managed using the [cos variable](./variables.tf#L140).

To use a random suffix for Object Storage resource creation, set the [cos_use_random_suffix variable](./variables.tf#L134)

```terraform
variable "cos" {
  description = "Object describing the cloud object storage instance, buckets, and keys. Set `use_data` to false to create instance"
  type = list(
    object({
      name                = string           # Name of the COS instance
      use_data            = optional(bool)   # Optional - Get existing COS instance from data
      resource_group_name = optional(string) # Name of resource group where COS should be provisioned
      plan                = optional(string) # Can be `lite` or `standard`
      ##############################################################################
      # For more information on bucket creation, see the Terraform Documentation
      # https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/cos_bucket
      ##############################################################################
      buckets = list(object({
        name                  = string           # Name of the bucket
        storage_class         = string           # Storage class for the bucket
        endpoint_type         = string
        force_delete          = bool
        single_site_location  = optional(string)
        region_location       = optional(string)
        cross_region_location = optional(string)
        kms_key               = optional(string) # Encryption Key name from keys variable
        allowed_ip            = optional(list(string))
        hard_quota            = optional(number)
        archive_rule = optional(object({
          days    = number
          enable  = bool
          rule_id = optional(string)
          type    = string
        }))
        activity_tracking = optional(object({
          activity_tracker_crn = string
          read_data_events     = bool
          write_data_events    = bool
        }))
        metrics_monitoring = optional(object({
          metrics_monitoring_crn  = string
          request_metrics_enabled = optional(bool)
          usage_metrics_enabled   = optional(bool)
        }))
      }))
      ##############################################################################
      # Create Any number of keys 
      ##############################################################################
      keys = optional(
        list(object({
          name        = string
          role        = string
          enable_HMAC = bool
        }))
      )

    })
  )
```

---

## Secrets Manager

A secrets manager instance can be created using the [secrets_manager variable](./variables.tf#L352). The `secrets_manager`

```terraform
variable "secrets_manager" {
  description = "Map describing an optional secrets manager deployment"
  type = object({
    use_secrets_manager = bool             # Create Secrets Manager Instance
    name                = optional(string) # Name of Secrets Manager Instance
    kms_key_name        = optional(string) # Name of KMS key from key_management module
    resource_group_id   = optional(string) # Resource Group ID for the secrets manager instance
  })
  default = {
    use_secrets_manager = false
  }
}
```

### Secrets Manager Service Authorization

If Secrets Manager and Key Management are enabled and an encryption key name is provided, an authorization is created to allow the secrets manager instance to read from the Key Management instance.

---

## Module Outputs

Name                 | Description
-------------------- | ---------------------------------------
key_management_name  | Name of key management service
key_management_crn   | CRN for KMS instance
key_management_guid  | GUID for KMS instance
key_rings            | Key rings created by module
keys                 | List of names and ids for keys created
cos_instances        | List of COS resource instances with shortname, name, id, and crn.
cos_buckets          | List of COS bucket instances with shortname, instance_shortname, name, id, crn, and instance id.
cos_keys             | List of COS bucket instances with shortname, instance_shortname, name, id, crn, and instance id.
secrets_manager_name | Name of secrets manager instance
secrets_manager_id   | ID of secrets manager instance
secrets_manager_guid | GUID of secrets manager instance

### Key Management Keys Output

The `keys` output is a list with the following fields for each Key Management Key:

Field Name | Field Value
-----------|----------------------------
shortname  | Name of key without prefix
name       | Composed name including prefix
id         | ID of the Key
crn        | CRN of the Key
key_id     | Key ID of Key

### COS Instances Output

The `cos_instances` output is a list with the following fields for each Object Storage Instances:

Field Name | Field Value
-----------|----------------------------
shortname  | Name of instance without prefix and random suffix
name       | Composed name including prefix and random suffix
id         | ID of the instance
crn        | CRN of the instance

### COS Buckets Output

The `cos_buckets` output is a list with the following fields for each Object Storage Bucket:

Field Name          | Field Value
--------------------|----------------------------
instance_shortname  | Shortname of the Object Storage instance where the bucket is created
instance_id         | Instance ID of the Object Storage instance where the bucket is created
shortname           | Name of bucket without prefix and random suffix
name                | Composed name including prefix and random suffix
id                  | ID of the Bucket
crn                 | CRN of the Bucket


### COS Resource Keys Output

The `cos_keys` output is a list with the following fields for each Object Storage Bucket:

Field Name          | Field Value
--------------------|----------------------------
instance_shortname  | Shortname of the Object Storage instance where the key is created
instance_id         | Instance ID of the Object Storage instance where the key is created
shortname           | Name of key without prefix and random suffix
name                | Composed name including prefix and random suffix
id                  | Resource Key ID
crn                 | Resource Key CRN


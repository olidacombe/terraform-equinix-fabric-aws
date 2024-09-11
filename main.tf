data "equinix_fabric_service_profiles" "this" {
  filter {
    property = "/name"
    operator = "="
    values   = [var.bandwidth >= 1000 ? "AWS Direct Connect - High Capacity" : "AWS Direct Connect"]
  }
}

resource "equinix_fabric_connection" "this" {
  name = var.name
  type = "EVPL_VC"
  notifications {
    type   = "ALL"
    emails = var.notifications
  }
  redundancy {
    priority = "PRIMARY"
  }
  order {
    purchase_order_number = length(var.purchase_order_number) > 0 ? var.purchase_order_number : null
  }
  a_side {
    access_point {
      type = length(var.device_id) > 0 ? "VD" : "COLO"

      dynamic "virtual_device" {
        for_each = length(var.device_id) > 0 ? [""] : []
        content {
          type = "EDGE"
          uuid = var.device_id
        }
      }
      dynamic "interface" {
        for_each = length(var.device_interface_id) > 0 ? [""] : []
        content {
          type = "CLOUD"
          uuid = var.device_interface_id
        }
      }
      dynamic "port" {
        for_each = length(var.port_id) > 0 ? [""] : []
        content {
          uuid = length(var.port_id) > 0 ? var.port_id : null
        }
      }
      link_protocol {
        type       = "QINQ"
        vlan_s_tag = var.vlan_stag == 0 ? null : var.vlan_stag
        vlan_c_tag = var.vlan_ctag == 0 ? null : var.vlan_ctag
      }
    }
  }
  z_side {
    access_point {
      type               = "SP"
      authentication_key = var.aws_account_id
      seller_region      = var.aws_region
      profile {
        type = "L2_PROFILE"
        uuid = data.equinix_fabric_service_profiles.this.0.id
      }
      location {
        metro_code = var.aws_metro_code
      }
    }
  }
  bandwidth = var.bandwidth
  additional_info = [
    { key = "access_key", value = var.aws_access_key },
    { key = "secret_key", value = var.aws_secret_key },
  ]
}

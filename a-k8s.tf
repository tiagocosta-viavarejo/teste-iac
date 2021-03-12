resource "azurerm_resource_group" "k8s" {
    name     = var.resource_group_name
    location = var.location
}

resource "azurerm_kubernetes_cluster" "k8s" {
    name                    = var.cluster_name
    location                = azurerm_resource_group.k8s.location
    resource_group_name     = azurerm_resource_group.k8s.name
    dns_prefix              = var.dns_prefix
    private_cluster_enabled = true
    kubernetes_version      = var.kubernetes_version

    linux_profile {
        admin_username = "azureuser"

        ssh_key {
            key_data = file(var.ssh_public_key)
        }
    }

    default_node_pool {
        name                = var.system_pool_name
        vm_size             = "Standard_F4s_v2"
        vnet_subnet_id      = var.subnetid
        max_count           = var.system_count_max
        min_count           = var.system_count_min
        node_count          = var.system_count_min
        enable_auto_scaling = true
        node_labels         = {"app":"system"}
    }

    service_principal {
        client_id     = var.client_id
        client_secret = var.client_secret
    }

    network_profile {
        network_plugin     = "kubenet"
        service_cidr       = "10.2.0.0/24"
        dns_service_ip     = "10.2.0.10"
        docker_bridge_cidr = "172.17.0.1/16"
        load_balancer_sku  = "standard"
    }

    tags = {
        app           = var.tagapp
        squad         = var.tagsquad 
        tier          = "aks"
        tier_type     = "kubernetes"
    }
}

resource "azurerm_kubernetes_cluster_node_pool" "k8s" {
    name                  = var.agent_pool_name
    kubernetes_cluster_id = azurerm_kubernetes_cluster.k8s.id
    vm_size               = var.vmsize
    mode                  = "User"
    node_labels           = {"app":var.app_name}
    enable_auto_scaling   = true
    max_count             = var.agent_count_max
    min_count             = var.agent_count_min

    tags = {
        app           = var.tagapp
        squad         = var.tagsquad
        tier          = "aks"
        tier_type     = "kubernetes"
    }
}

provider "vsphere" {
  user                 = ""
  password             = ""
  vsphere_server       = "vcenter.dc.nova"
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
 # description = "DC Dentro do VMware"
  name = "EQX"
}

data "vsphere_datastore_cluster" "datastore_cluster" {
 # description   = "Cluster dos discos que será usado para o deploy"
  name          = "DS-CL_A700_LX"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_compute_cluster" "cluster" {
 # description   = "Cluster onde as maquinas serao adicionadas"
  name          = "VM-CL_EQX_OPSHFT"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_network" "network" {
 # description   = "Nome da rede que sera usada no deploy"
  name          = "Kubernetes_Openshift-26"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

data "vsphere_virtual_machine" "template" {
 # description   = "Template usado no deploy"
  name          = "TEMPLATE-OPENSHIFT-V3"
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}

# Variaveis
variable "hosts" {
 # description = "Lista de máquinas para deploy, separado por virgual" 
  default = ["ops-eqx-node461", "ops-eqx-node462", "ops-eqx-node463", "ops-eqx-node464", "ops-eqx-node465", "ops-eqx-node466", "ops-eqx-node467", "ops-eqx-node468", "ops-eqx-node469", "ops-eqx-node470"]
}

variable "ips_disponiveis" {
 # description = "Lista de IP separado por virgual, seguindo a mesma ordem do hostname"
  default = ["10.128.26.112", "10.128.26.113", "10.128.26.114", "10.128.26.115", "10.128.26.116", "10.128.26.117", "10.128.26.118", "10.128.26.119", "10.128.26.120", "10.128.26.121"]
}

variable "dns_servers" {
  default = ["10.128.8.75", "10.128.8.76"]
}

resource "vsphere_virtual_machine" "vm" {
 # description = "Deploy da maquina"
  count = "${length(var.hosts)}"
  name  = "${var.hosts[count.index]}"
  resource_pool_id = "${data.vsphere_compute_cluster.cluster.resource_pool_id}"
  datastore_cluster_id  = "${data.vsphere_datastore_cluster.datastore_cluster.id}"

  num_cpus = 4
  memory   = 16384
  guest_id = "${data.vsphere_virtual_machine.template.guest_id}"

  scsi_type = "${data.vsphere_virtual_machine.template.scsi_type}"

  network_interface {
    network_id   = "${data.vsphere_network.network.id}"
    adapter_type = "${data.vsphere_virtual_machine.template.network_interface_types[0]}"
  }

  disk {
    label            = "disk0"
    size             = "${data.vsphere_virtual_machine.template.disks[0].size}"
    eagerly_scrub    = "${data.vsphere_virtual_machine.template.disks[0].eagerly_scrub}"
    thin_provisioned = "${data.vsphere_virtual_machine.template.disks[0].thin_provisioned}"
  }
  disk {
    label   = "disk1"
    size    = 100
    thin_provisioned = true
    unit_number = 1
  }

  clone {
    template_uuid = "${data.vsphere_virtual_machine.template.id}"

    customize {
      linux_options {
        host_name = "${var.hosts[count.index]}"
        domain    = "dc.nova"
      }
      network_interface{
        ipv4_address = "${var.ips_disponiveis[count.index]}"
        ipv4_netmask = 24
      }
      ipv4_gateway = "10.128.26.1"
      dns_server_list = ["10.128.8.75", "10.128.8.76"]
    }
  }
  provisioner "remote-exec" {
    inline = [
      "hostnamectl set-hostname ${var.hosts[count.index]}.dc.nova",
      "echo tralalala > /root/executado",
    ]
  }
  connection {
    type = "ssh"
    host = "${var.ips_disponiveis[count.index]}"
    user = "root"
    password = "P1Vxroi"
  }
}

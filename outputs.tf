output "webapp_url" {
    value = azurerm_linux_web_app.task-board-web_app.default_hostname
}

output "webapp_ips" {
  value = azurerm_linux_web_app.task-board-web_app.outbound_ip_addresses
}
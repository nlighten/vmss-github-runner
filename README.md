# vmss-github-runner
Pipeline for Github Runner using Azure VMSS:
- Automatically builds lastest Ubuntu 20.04 Github Actions Virtual Images image
- Creates a VM scale with Managed Identity with ephemeral runners
- Some basic autoscaling (needs refactoring)


# Security
Currently the VMSS has a Managed Identity with limited rights to access a storage queue and manage the VMSS itself. It would be better to move this to a separate component (e.g. function).




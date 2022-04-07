# vmss-github-runner
Pipeline for Github Runner using Azure VMSS:
- Automatically builds lastest Ubuntu 20.04 Github Actions Virtual Images image
- Creates a VM scale with Managed Identity with ephemeral runners
- Some basic autoscaling (needs refactoring)


# Security
Currently the VMSS has a Managed Identity with limited rights to access a storage queue and manage the VMSS itself. It would be better to move this to a separate component (e.g. function).



# Workflow parameters

| Parameter | Type | Description|
|-----------|------|------------|
| build-image| boolean | Switch to indicate if virtual actions image should be rebuild (takes approximately 2 hours)|
|vmss-name| string | Name of the VMSS scale set|
|github-repo| string | Github repo name the runners should be registered at (need to look into how to do the same at org level)| 
|runner-labels| string | Comma separated list of labels to put on the runners|
|pool-min-instances| number | Minimum number of runners to maintain (must be > 0)|
|pool-max-instances| number | Maximum number of runners |
|pool-free-target-percentage| number | Percentage of active runner count that the scale set should try to maintain as available|


$ Secrets
| Secret | Description|
|--------|------------|
|AZURE_CREDENTIALS| Azure credentials to use |
|RUNNER_PAT| Github PAT token to register runners| 
|VMSS_PASSWORD| Password set on runners, to be replaces by SSH key|
|VMSS_USER| Username created on the runners |

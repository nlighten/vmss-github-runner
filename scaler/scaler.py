import os, requests, json, math, ipaddress, logging
from datetime import datetime, timezone
from azure.mgmt.storage import StorageManagementClient
from azure.storage.queue import QueueClient
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
from azure.mgmt.compute import ComputeManagementClient

from flask import Flask, abort, request
from werkzeug.exceptions import HTTPException

app = Flask(__name__)
app.logger.info('Init')
runner_token = {}
credential = DefaultAzureCredential()
vault_url = os.environ['KEY_VAULT_URL']
github_pat_secret_name = os.environ.get('GITHUB_PAT_SECRET_NAME', 'github-pat')
github_repo = os.environ['GITHUB_REPO']
subscription_id = os.environ['SUBSCRIPTION_ID']
resource_group = os.environ['RESOURCE_GROUP']
vmss_name = os.environ['VMSS_NAME']
storage_account_name = os.environ['STORAGE_ACCOUNT_NAME']
min_runners = int(os.environ.get('MIN_RUNNERS', '1'))
max_runners = int(os.environ.get('MAX_RUNNERS', '4'))
target_free_runners = int(os.environ.get('TARGET_AVAILABLE_RUNNERS_PERCENT', '25'))

secret_client = SecretClient(vault_url=vault_url, credential=credential)
compute_client = ComputeManagementClient(credential, subscription_id)
storage_client = StorageManagementClient(credential, subscription_id)
queue_client = QueueClient(account_url="https://{0}.queue.core.windows.net/".format(storage_account_name), queue_name = vmss_name, credential=credential)

github_pat = secret_client.get_secret(github_pat_secret_name).value

if __name__ != '__main__':
    gunicorn_logger = logging.getLogger('gunicorn.error')
    app.logger.handlers = gunicorn_logger.handlers
    app.logger.setLevel(gunicorn_logger.level)


@app.errorhandler(HTTPException)
def handle_exception(e):
    response = e.get_response()
    response.data = json.dumps({
        "code": e.code,
        "name": e.name,
        "description": e.description,
    })
    response.content_type = "application/json"
    return response


@app.route('/health', methods=['GET'])
def health():
  return "alive"

@app.route('/runnertoken', methods=['GET'])
def run_post():
    global runner_token
    if not runner_token or runner_token_expired(runner_token, 60):
        app.logger.info('Requesting new runner token through Github API')
        url = "https://api.github.com/repos/{0}/actions/runners/registration-token".format(github_repo)
        headers = {'Authorization': "token {0}".format(github_pat)}
        response = requests.post(url, headers=headers)
        if response.status_code != 201:
            return "Could not retrieve Github Runner token", 500
        runner_token = response.json()
    else:
        app.logger.info('Returning cached runner token')
    return runner_token['token']


@app.route('/start/<runner>', methods=['GET'])
def start(runner):
    vmss = list(compute_client.virtual_machine_scale_set_vms.list(resource_group_name=resource_group,virtual_machine_scale_set_name=vmss_name))
    if sum(vm.os_profile.computer_name == runner for vm in vmss) != 1:
        abort(404, description="Runner with computer name {0} is not found".format(runner))
    response = queue_client.send_message(content=runner, time_to_live=3600, timeout=10)
    total_runners_count = len(vmss)
    queue_properties = queue_client.get_queue_properties(timeout=10)
    active_runners_count = queue_properties.approximate_message_count
    target_runner_count = min(math.ceil(active_runners_count*(100+target_free_runners)/100),max_runners)
    non_failed_runner_count = sum(vm.provisioning_state != 'Failed' for vm in vmss)
    if target_runner_count > non_failed_runner_count:
        app.logger.info("Adding {0} instances to scale set (current={1}, target={2}).".format(target_runner_count-non_failed_runner_count, non_failed_runner_count, target_runner_count))
        scale_set = compute_client.virtual_machine_scale_sets.get(resource_group_name=resource_group,vm_scale_set_name=vmss_name)
        scale_set.sku.capacity = target_runner_count + (total_runners_count - non_failed_runner_count)
        compute_client.virtual_machine_scale_sets.begin_update(resource_group_name=resource_group,vm_scale_set_name=vmss_name,parameters=scale_set)
    else:
        app.logger.info("No need to add capacity (current={1}, target={2}).".format(target_runner_count-non_failed_runner_count, non_failed_runner_count, target_runner_count))
    return "{0}|{1}".format(response.id, response.pop_receipt), 202


@app.route('/stop/<runner>/<receipt_info>', methods=['GET'])
def stop(runner, receipt_info):
    vmss = list(compute_client.virtual_machine_scale_set_vms.list(resource_group_name=resource_group,virtual_machine_scale_set_name=vmss_name))
    if sum(vm.os_profile.computer_name == runner for vm in vmss) != 1:
        abort(404, description="Runner with computer name {0} is not found".format(runner))
    for vm in vmss:
        if vm.os_profile.computer_name == runner:
            instance_id = vm.instance_id
    queue_client.delete_message(receipt_info.split('|')[0], receipt_info.split('|')[1], timeout=10)
    queue_properties = queue_client.get_queue_properties(timeout=10)
    active_runners_count = queue_properties.approximate_message_count
    target_runner_count = max(min(math.ceil(active_runners_count*(100+target_free_runners)/100),max_runners),min_runners)
    non_failed_runner_count = sum(vm.provisioning_state != 'Failed' for vm in vmss)
    if target_runner_count >= non_failed_runner_count:
        app.logger.info("Re-imaging runner {0} to keep capacity (current={1}, target={2}).".format(runner , non_failed_runner_count, target_runner_count))
        compute_client.virtual_machine_scale_set_vms.begin_reimage(resource_group_name=resource_group,vm_scale_set_name=vmss_name, instance_id=instance_id)
    else:
        app.logger.info("Deleting runner {0} to reduce capacity (current={1}, target={2}).".format(runner , non_failed_runner_count, target_runner_count))
        compute_client.virtual_machine_scale_set_vms.begin_delete(resource_group_name=resource_group,vm_scale_set_name=vmss_name, instance_id=instance_id)
    return "Accepted", 202


def runner_token_expired(token, margin_in_seconds):
    expires = datetime.fromisoformat(token['expires_at'])
    return (expires-datetime.now(timezone.utc)).total_seconds() < margin_in_seconds


if __name__ == '__main__':
    app.run(debug=False, host='0.0.0.0', port=8080)
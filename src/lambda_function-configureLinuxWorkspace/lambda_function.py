import logging
import os
import json
import boto3
import paramiko
from datetime import datetime
from dateutil import tz

ssm_client = boto3.client('ssm')
ws_client = boto3.client('workspaces')
logging.basicConfig(format='%(asctime)s [%(levelname)+8s]%(module)s: %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
logger = logging.getLogger(__name__)
logger.setLevel(getattr(logging, os.getenv('LOG_LEVEL', 'DEBUG')))

directoryId = ssm_client.get_parameter(Name='/workspaces/prototype/directory_id')['Parameter']['Value']
workspaceIp = ws_client.describe_workspaces(DirectoryId=directoryId)['Workspaces'][0]['IpAddress']
workspaceUsername = 'PROTOTYPE\\' + ssm_client.get_parameter(Name='/workspaces/prototype/username')['Parameter']['Value']
workspacePassword = ssm_client.get_parameter(Name='/workspaces/prototype/password', WithDecryption=True)['Parameter']['Value']


def get_ssh_connection(ssh_machine, ssh_username, ssh_password):
    """Establishes a ssh connection to execute command.
    :param ssh_machine: IP of the machine to which SSH connection to be established.
    :param ssh_username: User Name of the machine to which SSH connection to be established..
    :param ssh_password: Password of the machine to which SSH connection to be established..
    returns connection Object
    """
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(hostname=ssh_machine, username=ssh_username, password=ssh_password, timeout=10)
    return client
  
def run_sudo_command(jobid, command, ssh_username=workspaceUsername, ssh_password=workspacePassword, ssh_machine=workspaceIp):
    """Executes a command over a established SSH connectio.
    :param ssh_machine: IP of the machine to which SSH connection to be established.
    :param ssh_username: User Name of the machine to which SSH connection to be established..
    :param ssh_password: Password of the machine to which SSH connection to be established..
    returns status of the command executed and Output of the command.
    """
    conn = get_ssh_connection(ssh_machine=ssh_machine, ssh_username=ssh_username, ssh_password=ssh_password)
    command = "sudo -S -p '' sh -c '%s'" % command
    logging.info("Job[%s]: Executing: %s" % (jobid, command))
    stdin, stdout, stderr = conn.exec_command(command=command)
    stdin.write(ssh_password + "\n")
    stdin.flush()
    stdoutput = [line for line in stdout]
    stderroutput = [line for line in stderr]
    for output in stdoutput:
        logging.info("Job[%s]: %s" % (jobid, output.strip()))
    # Check exit code.
    logging.debug("Job[%s]:stdout: %s" % (jobid, stdoutput))
    logging.debug("Job[%s]:stderror: %s" % (jobid, stderroutput))
    logging.info("Job[%s]:Command status: %s" % (jobid, stdout.channel.recv_exit_status()))
    if not stdout.channel.recv_exit_status():
        logging.info("Job[%s]: Command executed." % jobid)
        conn.close()
        if not stdoutput:
            stdoutput = True
        return True, stdoutput
    else:
        logging.info("Job[%s]: Command failed." % jobid)
        for output in stderroutput:
            logging.error("Job[%s]: %s" % (jobid, output))
        conn.close()
        raise RuntimeError("Job[%s] Command execution failed" % jobid)
        return False, stderroutput

def lambda_handler(event, context):
    directoryId = ssm_client.get_parameter(Name='/workspaces/prototype/directory_id')['Parameter']['Value']
    workspaceIp = ws_client.describe_workspaces(DirectoryId=directoryId)['Workspaces'][0]['IpAddress']
    workspaceUsername = ssm_client.get_parameter(Name='/workspaces/prototype/username')['Parameter']['Value']
    workspacePassword = ssm_client.get_parameter(Name='/workspaces/prototype/password')['Parameter']['Value']

    run_sudo_command(1,'yum update -y')
    run_sudo_command(2,'amazon-linux-extras enable epel')
    run_sudo_command(3,'yum install -y epel-release')
    run_sudo_command(4,'yum install -y java-1.8.0-openjdk-devel golang python git postgresql docker terminator')
    run_sudo_command(5,'amazon-linux-extras enable mariadb10.5')
    run_sudo_command(6,'yum clean metadata')
    run_sudo_command(7,'yum install -y mariadb')
    #install kubectl
    run_sudo_command(8,'curl -o kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/kubectl')
    run_sudo_command(9,'install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl')
    run_sudo_command(10,'rm kubectl')
    #install helm
    run_sudo_command(11,'curl -o helm.tgz https://get.helm.sh/helm-v3.6.3-linux-amd64.tar.gz')
    run_sudo_command(12,'tar zxf helm.tgz')
    run_sudo_command(13,'install -o root -g root -m 0755 linux-amd64/helm /usr/local/bin/helm')
    run_sudo_command(14,'rm -r helm.tgz linux-amd64')
    #install terraform 
    run_sudo_command(15,'yum install -y wget unzip')
    run_sudo_command(16,'wget https://releases.hashicorp.com/terraform/0.14.11/terraform_0.14.11_linux_amd64.zip')
    run_sudo_command(17,'unzip terraform_0.14.11_linux_amd64.zip')
    run_sudo_command(17,'mv terraform /usr/local/bin/')
    run_sudo_command(18,'rm terraform_0.14.11_linux_amd64.zip')
    #install vscode
    run_sudo_command(20,'rpm --import https://packages.microsoft.com/keys/microsoft.asc')
    run_sudo_command(21,'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo')
    run_sudo_command(22,'yum check-update')
    run_sudo_command(23,'yum install -y code')
    #install dbeaver
    run_sudo_command(24,'rpm -Uv https://dbeaver.io/files/dbeaver-ce-latest-stable.x86_64.rpm')
    #enable docker daemon
    run_sudo_command(25,'systemctl enable docker')
    #set jdk-11 as default java
    run_sudo_command(26,'alternatives --set java /usr/lib/jvm/java-11-amazon-corretto.x86_64/bin/java')
    #change group of docker.socket after docker.socket service starts
    run_sudo_command(27,'mkdir /etc/systemd/system/rc-local.service.d')
    run_sudo_command(28,'echo -e "[Unit]\nAfter=docker.socket.target" > /etc/systemd/system/rc-local.service.d/override.conf')
    run_sudo_command(29,'echo "chgrp LIVE\\domain\ users /var/run/docker.sock" >> /etc/rc.d/rc.local')
    run_sudo_command(30,'chmod 744 /etc/rc.d/rc.local')
    
    configurationCompletionDateTime = datetime.isoformat(datetime.now(tz=tz.tzlocal()))

    return {
        'statusCode': 200,
        'configurationCompletionDateTime' : configurationCompletionDateTime
    }

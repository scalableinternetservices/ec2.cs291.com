#!/bin/bash

CREDENTIALS_PATH="$(dirname $0)/credentials"


add_files() {
    teamname=$1
    for extension in _api_credentials.txt _web_credentials.txt .pem; do
        filename=$teamname$extension
        source_path="$CREDENTIALS_PATH/$filename"
        destination_path="/home/$teamname/$filename"
        sudo cp $source_path $destination_path
        sudo chown $teamname:$teamname $destination_path
    done
}


create_account() {
    teamname=$1
    id -u $teamname >/dev/null 2>/dev/null
    if [ $? -ne 0 ]; then
        echo -n "Creating user $teamname... "
        sudo useradd $teamname
        echo "success"
    fi
}


set_aws_config() {
    teamname=$1
    aws_config_source="/home/$teamname/${teamname}_api_credentials.txt"
    aws_config_path="/home/$teamname/.aws"
    sudo mkdir -p $aws_config_path
    sudo chown $teamname:$teamname $aws_config_path
    sudo chmod 0700 $aws_config_path
    sudo mv $aws_config_source "$aws_config_path/credentials"
    echo -e "[default]\nregion = us-west-2" | sudo tee "$aws_config_path/config" > /dev/null
}


set_ssh_config() {
    teamname=$1
    ssh_key_path="$CREDENTIALS_PATH/$teamname.pem"
    public_key=$(ssh-keygen -y -f $ssh_key_path)
    ssh_path="/home/$teamname/.ssh"
    authorized_keys_path="$ssh_path/authorized_keys"
    sudo mkdir -p $ssh_path
    sudo chown $teamname:$teamname $ssh_path
    sudo chmod 0700 $ssh_path
    echo $public_key | sudo tee $authorized_keys_path > /dev/null
    sudo chown $teamname:$teamname $authorized_keys_path
    sudo cp $ssh_key_path $ssh_path
    sudo cp $ssh_key_path $ssh_path/id_rsa
    sudo chown $teamname:$teamname $ssh_path/id_rsa
    sudo chown $teamname:$teamname $ssh_path/$teamname.pem
}


for pempath in $(ls $CREDENTIALS_PATH/*.pem); do
    pemfile=$(basename $pempath)
    team="${pemfile%.*}"

    create_account $team
    add_files $team
    set_aws_config $team
    set_ssh_config $team
done

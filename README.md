# ec2.cs291.com

The purpose of this repository is to store the tools necessary to build and configure the ec2.cs291.com SSH jumpbox.

This machine can be used to push elastic beanstalk deployments for the primary project, and is also used to deploy to AWS lambda in project 1.


## Creating the jumpbox

Install terraform to your operating system. The following assumes you have an AWS profile called scalableinternetservices-admin that has a keypair for an account with IAM admin-level permissions.

```sh
cd terraform
terraform init
AWS_PROFILE=scalableinternetservices-admin terraform apply
```

The output of the above command will contain the IP address of the jumpbox. Create or update an `A` record for `ec2.cs291.com` to point to that IP address.


## Copy scripts

```sh
rsync -auv scripts/ ec2-user@ec2.cs291.com:
```

## Make launch_tsung.sh avilable

```sh
scp launch_tsung.sh ec2-user@ec2.cs291.com:
ssh ec2-user@ec2.cs291.com 'sudo mv launch_tsung.sh /usr/bin/'
```

## Create Credential Files

Make a list of teamnames in teams.txt. Then run:

```sh
mkdir credentials
cd credentials
for team in $(cat ../teams.txt); do
    scalable_admin aws $team
done
cd -
```

## Rsync credentials to jumpbox

```sh
rsync -auv credentials ec2-user@ec2.cs291.com:
```

## Run prepare_acounts.sh script

```sh
ssh ec2-user@ec2.cs291.com ./prepare_accounts.sh
```

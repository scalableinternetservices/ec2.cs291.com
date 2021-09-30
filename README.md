# ec2.cs291.com

The purpose of this repository is to store the tools necessary to build and configure the ec2.cs291.com SSH jumpbox.

This machine can be used to push elastic beanstalk deployments for the primary project, and is also used to deploy to AWS lambda in project 1.


## Creating the jumpbox

Install terraform to your operating system (`brew install terraform`). The following assumes you have an AWS profile called scalableinternetservices-admin that has a keypair for an account with IAM admin-level permissions.

```sh
cd terraform
AWS_PROFILE=scalableinternetservices-admin terraform init
AWS_PROFILE=scalableinternetservices-admin terraform apply
```

## Copy scripts

```sh
rsync -auv scripts/ ec2-user@ec2.cs291.com:
```

## Make launch_tsung.sh avilable

```sh
scp launch_tsung.sh ec2-user@ec2.cs291.com:
ssh ec2-user@ec2.cs291.com 'sudo mv launch_tsung.sh /usr/bin/'
```

## Run `aws configure`

Fetch your `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` for your scalableinternetservices-admin user and then run
`aws configure` on the jumpbox. Use `us-west-2` as the default region.


## Set up cleanup crontab

Run `crontab -e` and paste in the following:

```
MAILTO=cs291-aaaaecxj7l46ed6fkmwup2fely@appfolio.slack.com
*/5 * * * * ~/scalable_cleanup.py
```

## Create Credential Files

Make a list of teamnames in `usernames.txt` and then run:

```sh
mkdir credentials
cd credentials
for username in $(cat ../usernames.txt); do
    scalable_admin aws $username
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


## Share Credentials

Follow these instructions to fetch a credentials json file: https://pythonhosted.org/PyDrive/quickstart.html#authentication

Move that file to `$HOME/.config/share_credentials.json`.


```python
cd share_credentials
pip install -r requirements.txt

```

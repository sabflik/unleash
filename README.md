# Unleash Live Coding Challenge

## Deployment Instructions
**1. Configure AWS Credentials**

Configure the following files on your machine, replacing `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` with the access credentials from AWS and `AWS_ACCOUNT` with the AWS account number.

~/.aws/credentials
```
[default]
aws_access_key_id=<AWS_ACCESS_KEY_ID>
aws_secret_access_key=<AWS_SECRET_ACCESS_KEY>
```

~/.aws/config
```
[default]
role_arn=arn:aws:iam::<AWS_ACCOUNT>:role/unleash-challenge
source_profile=default
region=us-east-1
output=json
```

**2. Clone Repository**

`git clone https://github.com/sabflik/unleash.git` (HTTPS)
OR
`git clone git@github.com:sabflik/unleash.git` (SSH)

**3. Run Terraform Apply**

From the project folder, run the make command `make tf-apply` which will initialise the Terraform backend and run Terraform apply to view a plan of the infrastructure to be generated. Review the plan and type `yes` to create the infrastructure.

## Testing Instructions
Run `pip install -r requirements.txt` and `make test` to run the pytest test suite.

## Project Structure
This multi-region Terraform deployment is broken into 2 modules `auth` and `compute`. The `main.tf` file contains the AWS provider in `us-east-1` region, automatically inherited by the modules. The `auth` module contains the cognito config and deploys to this region. The `compute` module which contains the APIs and lambdas also use this default provider. However, the resources all have the `region` property which can be used to specify another region to deploy into. I have used the `for_each` and `region` keywords to achieve multi-region resources without duplicating code.

## Security
This infrastructure has a few security flaws, as noted in the CI/CD pipeline. Apart from the intended use of a public subnet as requested in the technical requirements, the major security flaws are unrestricted security groups and wildcards in some IAM policies. These can be fixed, but I'm leaving them due to time constraints. The ECS ingress should be changed from `0.0.0.0` to the security group of the lambda that's triggering it.
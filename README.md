# terraform-task

to create the vm on azure cloud provide clone this code 


## Get Started

### start running the command below

`terraform init`

### to know the resources that will be provisioned please run 

`terraform plan`

### to apply this changes on the created plan please run 

`terraform apply or terraform apply -y`

#### after applying terraform code u will get luftborn_key.pem private key on terraform-task Dir
#### u can edit its permission by running

`chmod +x luftborn_key.pem`
#### then you need to run 

`ssh -i luftborn_key.pem ubuntu@PUB_IP` 

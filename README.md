# Data Board (Central Heating Dashboard)
## Overview

This repository sets up a complete AWS infrastructure pipeline that ingests IoT data and stores it in an RDS database using Terraform and a Python-based AWS Lambda function. The data is gathered by 4 ESP8266 positioned around the house that send the data to AWS IoT Core. The current Grafana Dashboard can be found [here](https://dash.pavest.click/public-dashboards/2cd730b9b200402bacd01a4fd4330019).

## Infrastructure

* **Lambda Function:** Parses and processes incoming IoT data.
* **RDS:** Stores structured IoT data for long-term access and querying.
* **Terraform:** Manages all infrastructure including networking, security, Lambda, and RDS.
* **Shell Script:** Assist Docker Image used for front-end

## Project Structure

```
data-board-db_create/
├── src/
│   ├── data_board_img.sh            # Docker Image used for front-end
│   └── lambda/
│       ├── iot_to_rds.zip           # Packaged Lambda function ready for deployment
│       └── lambda_build/
│           ├── main.py              # Lambda handler: processes IoT data
│           └── requirements.txt     # Lambda dependencies
├── terraform/
│   ├── main.tf                      # Entry point for Terraform config
│   ├── networking.tf                # VPC, subnets, route tables
│   ├── sec.tf                       # Security groups, IAM roles and policies
│   ├── storage.tf                   # S3 bucket (optional/logs/etc.)
│   ├── iot_to_rds.tf                # Lambda function, trigger, and permissions
│   └── variables.tf                 # Terraform input variables
├── .gitignore
└── README.md
```

## Prerequisites

* [Terraform](https://www.terraform.io/)
* AWS CLI with configured credentials
* Python 3.x and `pip`

## Deployment

### 1. Package the Lambda Function

```bash
cd src/lambda/lambda_build
pip install -r requirements.txt -t .
zip -r ../iot_to_rds.zip .
```

### 2. Deploy the Infrastructure

```bash
cd terraform
terraform init
terraform apply
```

Terraform will provision:

* VPC and subnets
* RDS instance
* IAM roles
* Lambda function and execution permissions

### 3. Post-Deploy

After deployment, IoT data pushed to the relevant trigger (e.g., MQTT topic or API Gateway) will be automatically processed by the Lambda function and inserted into RDS.

## License

MIT

#  Ritual Roast – Production-Grade AWS ECS Web Application (Terraform)

This repository demonstrates how to **provision, deploy, and operate a full-stack production-style web application on AWS using Terraform and GitHub Actions**, replicating a real-world manual setup entirely as Infrastructure as Code (IaC).

The project includes a **frontend UI with a customer form**, **backend application**, **database connectivity**, and **full CRUD operations**, deployed on **AWS ECS (Fargate)** behind an **Application Load Balancer**, secured with **VPC networking**, **IAM**, **Secrets Manager**, **RDS**, and a **custom domain with SSL**.

---
<img width="748" height="689" alt="image" src="https://github.com/user-attachments/assets/12364b72-76b6-45e8-9277-08a6403ad03d" />

##  Architecture Overview

**High-level architecture:**

* Custom VPC across **two Availability Zones (us-east-1a & us-east-1b)**
* Public subnets for ALB
* Private app subnets for ECS tasks
* Private data subnets for RDS
* Application Load Balancer (ALB)
* ECS Cluster (Fargate)
* Amazon RDS (MySQL)
* Amazon ECR for container images
* AWS Secrets Manager for DB credentials
* Auto Scaling based on CPU utilization
* Custom domain (`ritualroast.online`) via Namecheap + Route 53
* SSL/TLS using AWS Certificate Manager (ACM)

---

##  Technology Stack

* **Terraform** – Infrastructure as Code
* **AWS ECS (Fargate)** – Serverless containers
* **Amazon ECR** – Docker image registry
* **Amazon RDS (MySQL)** – Relational database
* **AWS Secrets Manager** – Secure credential management
* **Application Load Balancer (ALB)** – Traffic routing
* **Route 53** – DNS management
* **ACM** – SSL certificates
* **GitHub Actions** – CI/CD automation
* **Docker** – Application containerization

---

##  Networking (VPC)

### VPC

* **Name:** `ritual-roast-vpc`
* **CIDR:** `10.0.0.0/16`
* DNS Hostnames & DNS Resolution: **Enabled**

### Subnets

**Public Subnets (ALB)**

* `rr-public-subnet1` – `10.0.1.0/24` (us-east-1a)
* `rr-public-subnet2` – `10.0.2.0/24` (us-east-1b)

**Private App Subnets (ECS)**

* `rr-app-subnet1` – `10.0.10.0/24` (us-east-1a)
* `rr-app-subnet2` – `10.0.11.0/24` (us-east-1b)

**Private Data Subnets (RDS)**

* `rr-data-subnet1` – `10.0.20.0/24` (us-east-1a)
* `rr-data-subnet2` – `10.0.21.0/24` (us-east-1b)

### NAT Gateways

* **1 NAT Gateway per AZ** for private subnet outbound internet access

### Route Tables (5)

* `rr-public-rt` → Internet Gateway
* `rr-app-subnet1-rt` → NAT Gateway
* `rr-app-subnet2-rt` → NAT Gateway
* `rr-data-subnet1-rt` → NAT Gateway
* `rr-data-subnet2-rt` → NAT Gateway

---

##  Security Groups

### 1️ ALB Security Group (`rr-alb-sg`)

* Inbound: HTTP (80) from `0.0.0.0/0`

### 2️⃣ Application Security Group (`rr-app-sg`)

* Inbound: HTTP (80) from `rr-alb-sg`

### 3️⃣ Database Security Group (`rr-data-sg`)

* Inbound: MySQL (3306) from `rr-app-sg`

---

##  Container Registry (ECR)

* **Repository:** `ritual-roast`
* Docker images are built and pushed via **GitHub Actions** or EC2-based build server

---

## IAM Roles & Policies

### EC2 Build Role

* SSM access
* ECR push/pull permissions
* Secrets Manager read access

### ECS Task Role (`ritual-roast-ecs-task-role`)

* `AmazonECSTaskExecutionRolePolicy`
* Custom policy to allow `secretsmanager:GetSecretValue`

---

##  Database (Amazon RDS)

* **Engine:** MySQL
* **Instance Type:** db.t3.micro
* **Storage:** 20 GB (no autoscaling)
* **Subnet Group:** `ritual-roast-db-subnet-group`
* **Public Access:** Disabled
* **Port:** 3306
* **Initial DB Name:** `ritualroastdb`

---

## Secrets Manager

* Stores RDS credentials securely
* Secret name: `ritual-roast-db-secret`
* Automatic rotation enabled (7 days)
* Accessed by ECS tasks via IAM role

---

## Load Balancing

### Target Group

* Type: IP
* Port: 80
* Health Check Path: `/health.html`

### Application Load Balancer

* Name: `ritual-roast-alb`
* Public-facing
* Deployed in both public subnets

---

## ECS (Elastic Container Service)

### Cluster

* Name: `ritual-roast-ecs-cluster`
* Launch Type: **Fargate**

### Task Definition

* CPU: 0.5 vCPU
* Memory: 1 GB
* Network Mode: `awsvpc`
* Container image from ECR

**Environment Variables:**

* `DB_SERVER` – RDS endpoint
* `DB_DATABASE` – Database name
* `SECRET_NAME` – Secrets Manager secret name
* `AWS_REGION` – us-east-1

### ECS Service

* Desired count: 1–4 (Auto Scaling)
* Load balanced via ALB
* Private subnets only
* Auto Scaling based on CPU (Target: 70%)

---

## Domain & SSL Configuration

* **Domain Registrar:** Namecheap
* **DNS:** Amazon Route 53 (Public Hosted Zone)
* **SSL Certificate:** AWS Certificate Manager (ACM)
* DNS validation using CNAME records

**Domains:**

* `ritualroast.online`
* `www.ritualroast.online`

---

## CI/CD (GitHub Actions)

* Terraform plan & apply automated
* Docker image build & push to ECR
* Infrastructure and application deployments are reproducible

---

## Key Learning Outcomes

* Designing production-ready AWS architecture
* Terraform best practices & modular IaC
* Secure secrets management
* ECS Fargate with ALB integration
* Multi-AZ high availability
* End-to-end CI/CD automation
* Real-world cloud networking and security

---

## Final Result

The application is accessible securely via:

 **[https://ritualroast.online](https://ritualroast.online)**

---

## Author

**Ohia Uche Goewill (Youngyz)**
Cloud / DevOps Engineer

---

If you find this project helpful, feel free to star the repository!

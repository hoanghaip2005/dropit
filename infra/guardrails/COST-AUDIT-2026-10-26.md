# Cost audit 26/10/2026

Read-only through dropit-admin (AdminUser), not root. No resources deleted.

AWS Budgets account-wide actual USD30.167, forecast USD30.594. Budget excludes credits. Cost Explorer October usage breakdown: RDS24.7698602498, CloudWatch2.4, ELB1.8207963218, EC2 compute0.4233067241, EC2 Other0.2312121202, VPC0.509043065. Credits offset almost all usage currently; credits are not a durable cost control.

Cost-bearing usage above attributed to ap-southeast-1. Current inventory there: zero RDS instances/clusters/manual DB snapshots, EC2 instances/EBS volumes/owned snapshots, ELBv2 load balancers, NAT gateways, EIPs, flow logs, metric alarms. Four legacy log groups remain (~10MB total), no deletion performed. This is not a complete all-region inventory.

DropIt Lightsail dropit-beta-sg running micro_3_0. No additional Lightsail disks or instance snapshots. App server and backup bucket remain intentionally active: nominal USD8/month before tax/overage. New Lightsail charges may not yet appear in delayed billing. Deleting them interrupts the application or removes backup data; requires explicit scope confirmation.

Historical accrued usage does not disappear on resource deletion. No evidence of currently running legacy RDS/ELB/EC2 in billed region. No claim that all AWS services are disabled or that budget is a hard cap.

## Authorized cleanup

User explicitly requested deletion of unused legacy logs and CloudFormation S3 bucket. Deleted and verified absent: /QuickStart/rdgateway/SetupConfiguration, /aws/Quick_Start/HybridDNS-RDGWStack-S25XOL8RCJK3, /aws/vpc/flowlogs, RDSOSMetrics; bucket cf-templates-9hmgicf39pt1-ap-southeast-1 including object versions/delete markers. DropIt instance verified running and backup bucket present. No DropIt resources deleted. Historical charges remain.

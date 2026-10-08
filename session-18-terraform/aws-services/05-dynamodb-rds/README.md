# DynamoDB & RDS — database services

**Aman Kumar · Enrollment 10275**

## DynamoDB

DynamoDB is a managed NoSQL database for key-value and document access. A **table** contains **items**; an item contains named **attributes**. A primary key is either a partition key alone or a partition key plus sort key. The partition key determines distribution, and the sort key orders items sharing a partition key.

Example model designed for this coursework:

```json
{
  "student_id": "10275",
  "submission_key": "SESSION#18",
  "status": "local-validation-passed",
  "author": "Aman Kumar"
}
```

Here `student_id` is the partition key and `submission_key` the sort key. Querying one student's submissions is natural; a different access pattern may need an index. Design keys around queries and spread workload to avoid hot partitions. Suitable uses include session stores, device events, carts and high-scale lookups. [AWS DynamoDB core components](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.CoreComponents.html).

## RDS

RDS manages relational databases with tables, SQL and transactions. Engines include PostgreSQL, MySQL, MariaDB, Oracle, SQL Server and Db2; Aurora has its own documentation. A DB instance packages compute and storage configuration. Restrict network access, encrypt storage/connections, protect credentials and choose backup retention with recovery goals in mind. Automated backups and manual snapshots support restoration.

Multi-AZ DB **instance** deployment provides a synchronous standby for availability; that standby does not serve reads. Multi-AZ DB **clusters** can expose readers, so these are distinct deployment types. [AWS RDS overview](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/).

Read replicas generally use asynchronous replication to offload read traffic; readers can lag and applications choose the appropriate endpoint. They serve a different goal from the standby of a Multi-AZ DB instance. [AWS read replicas](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_ReadRepl.html).

## Choosing for an application

| Requirement | Example choice | Reason |
| --- | --- | --- |
| Retrieve one student's session status by a known key | DynamoDB | Predictable key-based lookup |
| Join enrollment, invoices and courses with relational constraints | RDS | SQL and relational modeling |
| Recover a relational writer after an AZ failure | Appropriate RDS Multi-AZ deployment | Managed failover capability |
| Offload relational reporting reads | RDS read replica | Separate read capacity; account for replication lag |

This is a research deliverable. No database is provisioned, and the lab does not incur RDS/DynamoDB deployment costs.

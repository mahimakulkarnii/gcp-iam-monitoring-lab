-- GoogleSQL. Original lab event window in UTC; adjust for a new run.
SELECT timestamp,
  protopayload_auditlog.methodName AS method,
  protopayload_auditlog.authenticationInfo.principalEmail AS actor,
  protopayload_auditlog.resourceName AS resource,
  protopayload_auditlog.serviceName AS service
FROM `gcp-iam-monitoring-lab.iam_monitoring_logs.cloudaudit_googleapis_com_activity`
WHERE timestamp >= TIMESTAMP("2026-10-07T04:21:36Z")
  AND timestamp < TIMESTAMP("2026-10-07T05:22:00Z")
  AND (REGEXP_CONTAINS(protopayload_auditlog.methodName, r"(?i)setiampolicy$")
       OR protopayload_auditlog.methodName = "storage.setIamPermissions")
ORDER BY timestamp DESC;

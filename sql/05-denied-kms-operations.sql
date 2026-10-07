-- GoogleSQL. Original lab event window in UTC; adjust for a new run.
SELECT timestamp,
  protopayload_auditlog.methodName AS method,
  protopayload_auditlog.authenticationInfo.principalEmail AS actor,
  protopayload_auditlog.resourceName AS key_resource,
  protopayload_auditlog.status.code AS status_code
FROM `gcp-iam-monitoring-lab.iam_monitoring_logs.cloudaudit_googleapis_com_data_access`
WHERE timestamp >= TIMESTAMP("2026-10-07T04:21:36Z")
  AND timestamp < TIMESTAMP("2026-10-07T05:22:00Z")
  AND protopayload_auditlog.serviceName = "cloudkms.googleapis.com"
  AND protopayload_auditlog.status.code = 7
ORDER BY timestamp DESC;

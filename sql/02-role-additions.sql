-- GoogleSQL. Original lab event window in UTC; adjust for a new run.
SELECT l.timestamp,
  l.protopayload_auditlog.authenticationInfo.principalEmail AS actor,
  l.protopayload_auditlog.methodName AS method,
  d.action, d.member, d.role,
  l.protopayload_auditlog.resourceName AS resource
FROM `gcp-iam-monitoring-lab.iam_monitoring_logs.cloudaudit_googleapis_com_activity` AS l
CROSS JOIN UNNEST(l.protopayload_auditlog.servicedata_v1_iam.policyDelta.bindingDeltas) AS d
WHERE l.timestamp >= TIMESTAMP("2026-10-07T04:21:36Z")
  AND l.timestamp < TIMESTAMP("2026-10-07T05:22:00Z")
  AND d.action = "ADD"
ORDER BY l.timestamp DESC;

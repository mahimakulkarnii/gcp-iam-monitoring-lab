# Observed results

All timestamps below are UTC on October 7, 2026, copied from the observed audit events. They are event timestamps, not measurements of export latency.

| Time | Event | Interpretation |
| --- | --- | --- |
| 04:25:31 | `google.iam.v1.IAMPolicy.SetIamPolicy` on `iam_monitoring_logs` | Known-benign dataset permission setup |
| 05:00:26 | `Decrypt` by `lab-workload-sa`, successful | Expected workload baseline |
| 05:02:37 | `Encrypt` by `lab-workload-sa`, code `7` | Permission enforcement observed in BigQuery |
| 05:08:12 | `storage.setIamPermissions`; binding delta `ADD` for `lab-test-sa`, `roles/storage.objectViewer` | Controlled IAM detection test |
| 05:17:52 | `Decrypt` by the human administrator, successful | Controlled unexpected-actor comparison event |

## Tuning measurement

The pre-comparison baseline contained one successful workload decrypt. After the human comparison event, the broad decrypt query returned two records. The tuned rule excluded the exact successful workload/key combination and returned only the human comparison record.

| Measure | Count |
| --- | --- |
| Decrypt records before tuning, after comparison event | 2 |
| Known-benign records excluded | 1 |
| Comparison records retained | 1 |
| Records returned by tuned query | 1 |

This demonstrates the filter on a small labeled test set. It does not establish a production false-positive rate, recall, or precision.

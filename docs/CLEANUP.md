# Cleanup

**Last verified state:** VM stopped; temporary `lab-test-sa` bucket binding removed. Full cleanup has not yet been verified.

Before deleting anything, keep the README, SQL, and reviewed screenshots on your computer and GitHub. Export any audit records you want to retain privately. Deleting the cloud project removes access to its BigQuery evidence.

This lab used a dedicated project. After verifying that the project contains only disposable lab resources, its full cleanup command is:

```bash
gcloud projects delete gcp-iam-monitoring-lab
```

Read the confirmation and check the exact project ID before accepting. Do not use this command on a shared or production project. Project shutdown has a recovery period; do not describe all resources as instantly and permanently erased. Check project status and billing after shutdown and record the result.

If keeping the project instead, clean up the VM and disks, bucket contents and any retained object versions/soft-deleted data, sink, BigQuery dataset, test/workload accounts, custom roles, and KMS key versions. KMS destruction scheduling and retained storage require separate review. Do not assume the original guide's individual deletions eliminate every possible charge immediately.

Stopping the VM alone preserves its disk and the other services. No zero-cost claim is made for this lab.

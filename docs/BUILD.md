# Build and test runbook

This documents the completed lab. Commands use the original resource names. Do not rerun creation commands against existing resources. A reproduction needs a dedicated billing-enabled project, unique bucket name, appropriate administrator permissions, and a cost budget. The lab is not guaranteed to be free.

## 1. Enable services and create identities

Run administrator commands in Cloud Shell:

```bash
gcloud config set project gcp-iam-monitoring-lab
gcloud services enable compute.googleapis.com cloudkms.googleapis.com storage.googleapis.com iam.googleapis.com logging.googleapis.com bigquery.googleapis.com cloudresourcemanager.googleapis.com
gcloud iam service-accounts create lab-workload-sa --display-name="Lab Workload Service Account"
gcloud iam roles create labSecretsReader --project=gcp-iam-monitoring-lab --title="Lab Secrets Reader" --permissions=storage.objects.get,storage.objects.list --stage=GA
gcloud iam roles create labKeyDecrypter --project=gcp-iam-monitoring-lab --title="Lab Key Decrypter" --permissions=cloudkms.cryptoKeyVersions.useToDecrypt --stage=GA
```

## 2. Create secured resources and resource-level bindings

The completed bucket was configured in the console with uniform bucket-level access and public access prevention enforced. Verify those settings and bind the storage role specifically on the bucket. Create the KMS key and bind decrypt specifically on the key:

```bash
gcloud storage buckets describe gs://gcp-iam-monitoring-lab-secrets
gcloud storage buckets add-iam-policy-binding gs://gcp-iam-monitoring-lab-secrets --member="serviceAccount:lab-workload-sa@gcp-iam-monitoring-lab.iam.gserviceaccount.com" --role="projects/gcp-iam-monitoring-lab/roles/labSecretsReader"
gcloud kms keyrings create lab-keyring --location=us-central1
gcloud kms keys create lab-secret-key --location=us-central1 --keyring=lab-keyring --purpose=encryption
gcloud kms keys add-iam-policy-binding lab-secret-key --location=us-central1 --keyring=lab-keyring --member="serviceAccount:lab-workload-sa@gcp-iam-monitoring-lab.iam.gserviceaccount.com" --role="projects/gcp-iam-monitoring-lab/roles/labKeyDecrypter"
```

## 3. Configure logging before test events

In IAM & Admin → Audit Logs, enable `ADMIN_READ`, `DATA_READ`, and `DATA_WRITE` for Cloud Storage and Cloud KMS, with no exemptions. Verify:

```bash
gcloud projects get-iam-policy gcp-iam-monitoring-lab --format='json(auditConfigs)'
```

The dataset and sink were configured with these settings:

- Dataset `iam_monitoring_logs`, location `us-central1`.
- Sink `iam-audit-to-bq`, filter `logName:"cloudaudit.googleapis.com"`.
- Destination `bigquery.googleapis.com/projects/gcp-iam-monitoring-lab/datasets/iam_monitoring_logs`.
- Timestamp-partitioned tables enabled.
- Sink writer identity granted BigQuery Data Editor on this dataset.

Verify the sink and writer identity with `gcloud logging sinks describe iam-audit-to-bq`. In the dataset Sharing/Permissions view, verify the writer's dataset-level access. Generate events after this configuration, then verify delivery; the lab did not backfill earlier events.

## 4. Create VM and prove its API identity

```bash
gcloud compute instances create lab-vm --project=gcp-iam-monitoring-lab --zone=us-central1-a --machine-type=e2-micro --image-family=debian-12 --image-project=debian-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --service-account=lab-workload-sa@gcp-iam-monitoring-lab.iam.gserviceaccount.com --scopes=cloud-platform
gcloud compute ssh lab-vm --project=gcp-iam-monitoring-lab --zone=us-central1-a
```

Inside the VM:

```bash
curl -sS -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email"
gcloud auth list
gcloud compute instances list --project=gcp-iam-monitoring-lab
```

The first two showed the attached service account. Instance listing was denied. The broad OAuth scope does not grant IAM permissions; the account's IAM policy still determines allowed operations.

## 5. Create dummy ciphertext as administrator

Run in Cloud Shell, outside the VM:

```bash
echo "lab secret payload - dummy data only" > secret.txt
gcloud kms encrypt --project=gcp-iam-monitoring-lab --location=us-central1 --keyring=lab-keyring --key=lab-secret-key --plaintext-file=secret.txt --ciphertext-file=secret.enc
gcloud storage cp secret.enc gs://gcp-iam-monitoring-lab-secrets/secret.enc
```

Only the ciphertext was uploaded. Human encryption succeeded using the administrator's existing permissions.

## 6. Test workload allow and deny behavior

Inside the VM:

```bash
gcloud storage cp gs://gcp-iam-monitoring-lab-secrets/secret.enc ./secret.enc
gcloud kms decrypt --project=gcp-iam-monitoring-lab --location=us-central1 --keyring=lab-keyring --key=lab-secret-key --ciphertext-file=secret.enc --plaintext-file=decrypted.txt
cat decrypted.txt
gcloud storage cp decrypted.txt gs://gcp-iam-monitoring-lab-secrets/write-test.txt
gcloud kms encrypt --project=gcp-iam-monitoring-lab --location=us-central1 --keyring=lab-keyring --key=lab-secret-key --plaintext-file=decrypted.txt --ciphertext-file=write-test.enc
```

Read and decrypt succeeded, revealing the dummy payload. Upload and encrypt were denied. Exit the VM shell before running administrator changes or BigQuery queries.

## 7. Generate IAM addition and remove it

Run as the administrator in Cloud Shell:

```bash
gcloud iam service-accounts create lab-test-sa --display-name="Lab Detection Test Account"
gcloud storage buckets add-iam-policy-binding gs://gcp-iam-monitoring-lab-secrets --member="serviceAccount:lab-test-sa@gcp-iam-monitoring-lab.iam.gserviceaccount.com" --role="roles/storage.objectViewer"
```

Run SQL 01 and 02 and save their results. Then remove the temporary grant:

```bash
gcloud storage buckets remove-iam-policy-binding gs://gcp-iam-monitoring-lab-secrets --member="serviceAccount:lab-test-sa@gcp-iam-monitoring-lab.iam.gserviceaccount.com" --role="roles/storage.objectViewer"
```

## 8. Validate tuning with a second actor

Record the workload decrypt baseline, then run as the human administrator:

```bash
gcloud kms decrypt --project=gcp-iam-monitoring-lab --location=us-central1 --keyring=lab-keyring --key=lab-secret-key --ciphertext-file=secret.enc --plaintext-file=human-decrypted.txt
```

Run SQL 03 and 04 over the same window. Expected: two decrypt events before tuning and only the human comparison event afterward. SQL 05 verifies the earlier denied VM encryption.

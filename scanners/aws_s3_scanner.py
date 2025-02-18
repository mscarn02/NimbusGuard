import boto3    # type: ignore
import json
from tabulate import tabulate # type: ignore


def check_s3_misconfigurations():
    s3_client = boto3.client("s3")
    buckets = s3_client.list_buckets()["Buckets"]
    #print(buckets)

    results = []

    for bucket in buckets:
        bucket_name = bucket["Name"]

        public_access = "Unknown"
        try:
            acl = s3_client.get_public_access_block(Bucket=bucket_name)
            if not acl["PublicAccessBlockConfiguration"]["BlockPublicAcls"]:
                public_access = "Public"
            else:
                public_access = "Private"
        except:
            public_access = "Public (ACL not found)"

        encryption_enabled = "No"
        try:
            enc = s3_client.get_bucket_encryption(Bucket=bucket_name)
            encryption_enabled = "Yes"
        except:
            encryption_enabled = "No"

        results.append([bucket_name, public_access, encryption_enabled])

    return results


if __name__ == "__main__":
    findings = check_s3_misconfigurations()
    print(tabulate(findings, headers=["Bucket Name", "Public Access", "Encryption"], tablefmt="grid"))
    #print(findings)
    
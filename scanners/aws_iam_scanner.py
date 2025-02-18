import boto3 # type: ignore
import json
from tabulate import tabulate   # type: ignore

def check_iam_misconfigurations():
    iam_client = boto3.client("iam")
    users = iam_client.list_users()["Users"]
    results = []

    for user in users:
        username = user["UserName"]

        mfa = "No"
        mfa_devices = iam_client.list_mfa_devices(UserName=username)
        if mfa_devices["MFADevices"]:
            mfa = "Yes"

        policies = iam_client.list_attached_user_policies(UserName=username)
        is_admin = "No"
        for policy in policies["AttachedPolicies"]:
            if "AdministratorAccess" in policy["PolicyName"]:
                is_admin = "Yes"

        results.append([username, mfa, is_admin])

    return results
    
if __name__ == "__main__":
    findings = check_iam_misconfigurations()
    print(tabulate(findings, headers=["User Name", "MFA", "Admin access"], tablefmt="grid"))


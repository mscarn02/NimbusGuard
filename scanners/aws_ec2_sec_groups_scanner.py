import boto3 # type: ignore
from tabulate import tabulate
import json

CRITICAL_PORTS = [22, 80, 3389, 3306, 5432, 9200, 27017] 

def check_open_ports():
    ec2_client = boto3.client("ec2")
    security_groups = ec2_client.describe_security_groups()["SecurityGroups"]

    #print(json.dumps(security_groups, indent=4))

    results = []
    for sg in security_groups:
        sg_id = sg.get("GroupId")
        sg_name = sg.get("GroupName")
        sg_description = sg.get("Description")

    #print(sg_id, sg_name, sg_description)
        for rule in sg["IpPermissions"]:
            protocol = rule.get("IpProtocol", "All")
            from_port = rule.get("FromPort", "All")
            to_port = rule.get("ToPort", "All")

            for ip in rule.get("IpRanges", []):
                cidr = ip["CidrIp"]     #if 0.0.0./0 (accessible to all via internet)
                
                if cidr == "0.0.0.0/0" and (from_port in CRITICAL_PORTS or from_port == "All") :
                    risk = "HIGH"
                else:
                    risk = "MEDIUM"
                
                results.append([sg_id, sg_name, protocol, from_port, to_port, cidr, risk])

    return results

if __name__ == "__main__":
    findings = check_open_ports()
    print(tabulate(findings, headers=["SG_ID", "SG Name", "Protocol", "From Port", "To port", "CIDR", "Risk"], tablefmt="grid"))

                
                    
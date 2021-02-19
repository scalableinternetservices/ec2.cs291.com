#!/usr/bin/env python3
from datetime import datetime, timedelta, tzinfo
import botocore.session
import pprint
import sys


REGION = "us-west-2"


class UTC(tzinfo):
    dst = lambda x, y: timedelta(0)
    tzname = lambda x, y: "UTC"
    utcoffset = lambda x, y: timedelta(0)


NOW = datetime.now(UTC())


def delete_tsung_ec2_instances(aws):
    ec2 = aws.create_client("ec2", REGION)
    ids = []
    for reservation in ec2.describe_instances()["Reservations"]:
        for instance in reservation["Instances"]:
            if not [x for x in instance["SecurityGroups"] if x["GroupName"] == "allow_http"]:
                break

            duration = NOW - instance["LaunchTime"]
            if instance["State"]["Name"] in {"terminated"} or duration < timedelta(
                minutes=240
            ):
                continue
            if instance["State"]["Name"] not in {"running"}:
                print(f"Unknown state: {instance['State']['Name']}")

            name = next(x["Value"] for x in instance["Tags"] if x["Key"] == "Name")
            print(f"Deleting EC2 instance {name} (Duration: {duration})")
            ids.append(instance["InstanceId"])
    if ids:
        ec2.terminate_instances(InstanceIds=ids)


def delete_inactive_elastic_beanstalk_deployments(aws):
    eb = aws.create_client("elasticbeanstalk", REGION)
    for deployment in eb.describe_environments()["Environments"]:
        if (
            deployment["Status"].startswith("Terminat")
            or deployment["Status"] == "Launching"
            or NOW - deployment["DateUpdated"] < timedelta(minutes=110)
        ):
            continue
        print(
            f"Last Update: {NOW - deployment['DateUpdated']} Terminating {deployment['EnvironmentName']} ({deployment['Status']})"
        )
        eb.terminate_environment(EnvironmentId=deployment["EnvironmentId"])


def delete_inactive_elasticache_instances(aws):
    cache = aws.create_client("elasticache", REGION)
    clusters_to_delete = {}
    replication_groups_to_delete = {}
    for cluster in cache.describe_cache_clusters(ShowCacheNodeInfo=True)[
        "CacheClusters"
    ]:
        if cluster["CacheClusterStatus"] in {"deleting"}:
            continue

        if cluster["Engine"] == "redis":
            assert len(cluster["CacheNodes"]) == 1
            replication_groups_to_delete.setdefault(
                cluster["ReplicationGroupId"], cluster["CacheClusterCreateTime"]
            )
            replication_groups_to_delete[cluster["ReplicationGroupId"]] = max(
                replication_groups_to_delete[cluster["ReplicationGroupId"]],
                cluster["CacheClusterCreateTime"],
            )
        else:
            import pprint

            pprint.pprint(cluster)
            assert len(cluster["CacheNodes"]) == cluster["NumCacheNodes"]
            for node in cluster["CacheNodes"]:
                clusters_to_delete.setdefault(
                    cluster["CacheClusterId"], node["CacheNodeCreateTime"]
                )
                clusters_to_delete[cluster["CacheClusterId"]] = max(
                    clusters_to_delete[cluster["CacheClusterId"]],
                    node["CacheNodeCreateTime"],
                )

    for cluster, last_created in clusters_to_delete.items():
        if NOW - last_created >= timedelta(minutes=110):
            print(f"Deleting memcached cluster {cluster}")
            cache.delete_cache_cluster(CacheClusterId=cluster)

    for replication_group, last_created in replication_groups_to_delete.items():
        if NOW - last_created >= timedelta(minutes=110):
            print(f"Deleting redis cluster {replication_group}")
            cache.delete_replication_group(ReplicationGroupId=replication_group)


def delete_orphaned_databases(rds):
    for instance in rds.describe_db_instances()["DBInstances"]:
        if instance["DBName"] == "ebdb":
            continue

        db = instance["DBInstanceIdentifier"]
        print(f"Deleting database: {db}")
        rds.delete_db_instance(DBInstanceIdentifier=db, SkipFinalSnapshot=True)


def delete_snapshots(rds):
    deleted = 0
    for snapshot in rds.describe_db_snapshots()["DBSnapshots"]:
        if snapshot["Status"] == "creating":
            continue
        elif snapshot["SnapshotType"] == "manual":
            rds.delete_db_snapshot(
                DBSnapshotIdentifier=snapshot["DBSnapshotIdentifier"]
            )
            deleted += 1
        elif snapshot["SnapshotType"] != "automated":
            pprint.pprint(snapshot)
    if deleted > 0:
        print(f"Deleted snapshots: {deleted}")


def main():
    aws = botocore.session.Session(profile="scalableinternetservices-admin")

    delete_tsung_ec2_instances(aws)
    delete_inactive_elasticache_instances(aws)
    delete_inactive_elastic_beanstalk_deployments(aws)

    rds = aws.create_client("rds", REGION)
    delete_orphaned_databases(rds)
    delete_snapshots(rds)
    return 0


if __name__ == "__main__":
    sys.exit(main())

"""
DR Scale-Up Lambda Function
Automatically scales up DR infrastructure when primary region fails
"""

import json
import boto3
import os
from datetime import datetime

def handler(event, context):
    """
    Main handler for DR scale-up operations
    Triggered by CloudWatch alarm when primary region health check fails
    """
    
    print(f"DR Failover triggered at {datetime.utcnow().isoformat()}")
    print(f"Event: {json.dumps(event, indent=2)}")
    
    # Get environment variables
    environment = os.environ.get('ENVIRONMENT')
    dr_region = os.environ.get('DR_REGION')
    workload_account_id = os.environ.get('WORKLOAD_ACCOUNT_ID')
    target_aurora_size = int(os.environ.get('TARGET_AURORA_SIZE', '3'))
    target_aurora_class = os.environ.get('TARGET_AURORA_CLASS', 'db.r6g.xlarge')
    target_eks_nodes = int(os.environ.get('TARGET_EKS_NODES', '6'))
    
    # Initialize AWS clients for DR region
    rds = boto3.client('rds', region_name=dr_region)
    autoscaling = boto3.client('autoscaling', region_name=dr_region)
    cloudfront = boto3.client('cloudfront', region_name='us-east-1')
    route53 = boto3.client('route53')
    sns = boto3.client('sns', region_name=dr_region)
    
    results = {
        'timestamp': datetime.utcnow().isoformat(),
        'environment': environment,
        'dr_region': dr_region,
        'actions': []
    }
    
    try:
        # Step 1: Scale up Aurora cluster
        print("Step 1: Scaling up Aurora DR cluster...")
        aurora_result = scale_up_aurora(
            rds, 
            environment, 
            target_aurora_size, 
            target_aurora_class
        )
        results['actions'].append(aurora_result)
        
        # Step 2: Scale up EKS node groups
        print("Step 2: Scaling up EKS node groups...")
        eks_result = scale_up_eks(
            autoscaling, 
            environment, 
            target_eks_nodes
        )
        results['actions'].append(eks_result)
        
        # Step 3: Enable CloudFront DR distribution
        print("Step 3: Enabling DR CloudFront distribution...")
        cloudfront_result = enable_dr_cloudfront(
            cloudfront, 
            environment
        )
        results['actions'].append(cloudfront_result)
        
        # Step 4: Send notifications
        print("Step 4: Sending DR activation notifications...")
        notification_result = send_notifications(
            sns, 
            environment, 
            results
        )
        results['actions'].append(notification_result)
        
        print(f"DR Failover completed successfully: {json.dumps(results, indent=2)}")
        
        return {
            'statusCode': 200,
            'body': json.dumps(results)
        }
        
    except Exception as e:
        error_msg = f"DR Failover failed: {str(e)}"
        print(error_msg)
        
        # Send failure notification
        send_failure_notification(sns, environment, error_msg)
        
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': error_msg,
                'results': results
            })
        }


def scale_up_aurora(rds, environment, target_count, target_class):
    """Scale up Aurora cluster to production capacity"""
    
    cluster_id = f"example-{environment}-dr-workload-cluster"
    
    try:
        # Get current cluster status
        response = rds.describe_db_clusters(
            DBClusterIdentifier=cluster_id
        )
        cluster = response['DBClusters'][0]
        current_members = len(cluster.get('DBClusterMembers', []))
        
        print(f"Current Aurora instances: {current_members}, Target: {target_count}")
        
        actions = []
        
        # Scale up existing instances
        for member in cluster.get('DBClusterMembers', []):
            instance_id = member['DBInstanceIdentifier']
            
            # Modify instance class
            rds.modify_db_instance(
                DBInstanceIdentifier=instance_id,
                DBInstanceClass=target_class,
                ApplyImmediately=True
            )
            actions.append(f"Upgraded {instance_id} to {target_class}")
        
        # Add additional instances if needed
        for i in range(current_members, target_count):
            new_instance_id = f"{cluster_id}-{i+1}"
            
            rds.create_db_instance(
                DBInstanceIdentifier=new_instance_id,
                DBClusterIdentifier=cluster_id,
                DBInstanceClass=target_class,
                Engine='aurora-postgresql',
                PubliclyAccessible=False,
                Tags=[
                    {'Key': 'Environment', 'Value': environment},
                    {'Key': 'DRScaledUp', 'Value': 'true'},
                    {'Key': 'ScaleUpTime', 'Value': datetime.utcnow().isoformat()}
                ]
            )
            actions.append(f"Created new instance {new_instance_id}")
        
        return {
            'action': 'Aurora Scale-Up',
            'status': 'success',
            'cluster_id': cluster_id,
            'target_count': target_count,
            'target_class': target_class,
            'details': actions
        }
        
    except Exception as e:
        return {
            'action': 'Aurora Scale-Up',
            'status': 'failed',
            'error': str(e)
        }


def scale_up_eks(autoscaling, environment, target_nodes):
    """Scale up EKS node groups"""
    
    try:
        # Find EKS node group auto scaling groups
        asg_prefix = f"eks-example-{environment}-dr"
        
        response = autoscaling.describe_auto_scaling_groups()
        
        actions = []
        
        for asg in response['AutoScalingGroups']:
            if asg['AutoScalingGroupName'].startswith(asg_prefix):
                asg_name = asg['AutoScalingGroupName']
                
                # Scale up to target capacity
                autoscaling.set_desired_capacity(
                    AutoScalingGroupName=asg_name,
                    DesiredCapacity=target_nodes,
                    HonorCooldown=False
                )
                
                # Update max capacity if needed
                if asg['MaxSize'] < target_nodes:
                    autoscaling.update_auto_scaling_group(
                        AutoScalingGroupName=asg_name,
                        MaxSize=target_nodes * 2
                    )
                
                actions.append(f"Scaled {asg_name} to {target_nodes} nodes")
        
        return {
            'action': 'EKS Scale-Up',
            'status': 'success',
            'target_nodes': target_nodes,
            'details': actions
        }
        
    except Exception as e:
        return {
            'action': 'EKS Scale-Up',
            'status': 'failed',
            'error': str(e)
        }


def enable_dr_cloudfront(cloudfront, environment):
    """Enable DR CloudFront distribution"""
    
    try:
        # Find DR CloudFront distribution
        response = cloudfront.list_distributions()
        
        dr_distribution_id = None
        for dist in response.get('DistributionList', {}).get('Items', []):
            if f"example-{environment}-dr-cloudfront" in dist.get('Comment', ''):
                dr_distribution_id = dist['Id']
                break
        
        if not dr_distribution_id:
            return {
                'action': 'CloudFront Enable',
                'status': 'skipped',
                'reason': 'DR distribution not found'
            }
        
        # Get current config
        config_response = cloudfront.get_distribution_config(
            Id=dr_distribution_id
        )
        
        config = config_response['DistributionConfig']
        etag = config_response['ETag']
        
        # Enable distribution if disabled
        if not config['Enabled']:
            config['Enabled'] = True
            
            cloudfront.update_distribution(
                Id=dr_distribution_id,
                DistributionConfig=config,
                IfMatch=etag
            )
            
            return {
                'action': 'CloudFront Enable',
                'status': 'success',
                'distribution_id': dr_distribution_id
            }
        else:
            return {
                'action': 'CloudFront Enable',
                'status': 'already_enabled',
                'distribution_id': dr_distribution_id
            }
        
    except Exception as e:
        return {
            'action': 'CloudFront Enable',
            'status': 'failed',
            'error': str(e)
        }


def send_notifications(sns, environment, results):
    """Send DR activation notifications"""
    
    try:
        topic_arn = f"arn:aws:sns:eu-west-2:{results.get('workload_account_id', '*')}:example-{environment}-dr-failover-notifications"
        
        message = f"""
DISASTER RECOVERY FAILOVER ACTIVATED

Environment: {environment}
Timestamp: {results['timestamp']}
DR Region: {results['dr_region']}

Actions Completed:
"""
        
        for action in results['actions']:
            message += f"\n- {action['action']}: {action['status']}"
            if 'details' in action:
                for detail in action['details']:
                    message += f"\n  * {detail}"
        
        message += "\n\nPlease verify DR infrastructure and application functionality."
        
        sns.publish(
            TopicArn=topic_arn,
            Subject=f"[CRITICAL] DR Failover Activated - {environment}",
            Message=message
        )
        
        return {
            'action': 'Notifications',
            'status': 'success'
        }
        
    except Exception as e:
        return {
            'action': 'Notifications',
            'status': 'failed',
            'error': str(e)
        }


def send_failure_notification(sns, environment, error_msg):
    """Send failure notification"""
    
    try:
        topic_arn = f"arn:aws:sns:eu-west-2:*:example-{environment}-dr-failover-notifications"
        
        sns.publish(
            TopicArn=topic_arn,
            Subject=f"[CRITICAL] DR Failover FAILED - {environment}",
            Message=f"""
DISASTER RECOVERY FAILOVER FAILED

Environment: {environment}
Timestamp: {datetime.utcnow().isoformat()}
Error: {error_msg}

MANUAL INTERVENTION REQUIRED!

Please:
1. Check Lambda logs for details
2. Manually verify primary region status
3. Manually activate DR infrastructure if needed
4. Contact on-call engineering team immediately
"""
        )
        
    except Exception as e:
        print(f"Failed to send failure notification: {str(e)}")

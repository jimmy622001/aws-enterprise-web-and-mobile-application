#====================================================================
# CLOUDFRONT & WAF MODULE - OUTPUTS
#====================================================================

# CloudFront Web Distribution
output "cloudfront_web_distribution_id" {
  description = "CloudFront Web distribution ID"
  value       = aws_cloudfront_distribution.web.id
}

output "cloudfront_web_distribution_arn" {
  description = "CloudFront Web distribution ARN"
  value       = aws_cloudfront_distribution.web.arn
}

output "cloudfront_web_distribution_domain_name" {
  description = "CloudFront Web distribution domain name"
  value       = aws_cloudfront_distribution.web.domain_name
}

output "cloudfront_web_distribution_hosted_zone_id" {
  description = "CloudFront Web distribution hosted zone ID"
  value       = aws_cloudfront_distribution.web.hosted_zone_id
}

# CloudFront CMS Distribution
output "cloudfront_cms_distribution_id" {
  description = "CloudFront CMS distribution ID"
  value       = aws_cloudfront_distribution.cms.id
}

output "cloudfront_cms_distribution_arn" {
  description = "CloudFront CMS distribution ARN"
  value       = aws_cloudfront_distribution.cms.arn
}

output "cloudfront_cms_distribution_domain_name" {
  description = "CloudFront CMS distribution domain name"
  value       = aws_cloudfront_distribution.cms.domain_name
}

output "cloudfront_cms_distribution_hosted_zone_id" {
  description = "CloudFront CMS distribution hosted zone ID"
  value       = aws_cloudfront_distribution.cms.hosted_zone_id
}

# WAF
output "waf_cloudfront_web_acl_arn" {
  description = "WAF CloudFront Web ACL ARN"
  value       = aws_wafv2_web_acl.cloudfront.arn
}

output "waf_cloudfront_web_acl_id" {
  description = "WAF CloudFront Web ACL ID"
  value       = aws_wafv2_web_acl.cloudfront.id
}

output "waf_regional_web_acl_arn" {
  description = "WAF Regional Web ACL ARN"
  value       = aws_wafv2_web_acl.regional.arn
}

output "waf_regional_web_acl_id" {
  description = "WAF Regional Web ACL ID"
  value       = aws_wafv2_web_acl.regional.id
}

# Shield Advanced
output "shield_protection_group_id" {
  description = "Shield Advanced protection group ID"
  value       = aws_shield_protection_group.main.id
}

output "shield_cloudfront_web_protection_id" {
  description = "Shield protection ID for CloudFront Web"
  value       = aws_shield_protection.cloudfront_web.id
}

output "shield_cloudfront_cms_protection_id" {
  description = "Shield protection ID for CloudFront CMS"
  value       = aws_shield_protection.cloudfront_cms.id
}

output "shield_api_gateway_protection_id" {
  description = "Shield protection ID for API Gateway"
  value       = aws_shield_protection.api_gateway.id
}

# API Gateway
output "api_gateway_rest_api_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.main.id
}

output "api_gateway_rest_api_arn" {
  description = "API Gateway REST API ARN"
  value       = aws_api_gateway_rest_api.main.arn
}

output "api_gateway_stage_arn" {
  description = "API Gateway Stage ARN"
  value       = aws_api_gateway_stage.main.arn
}

output "api_gateway_invoke_url" {
  description = "API Gateway invoke URL"
  value       = aws_api_gateway_stage.main.invoke_url
}

output "api_gateway_vpc_link_id" {
  description = "API Gateway VPC Link ID"
  value       = aws_api_gateway_vpc_link.main.id
}

# S3 Buckets
output "web_assets_bucket_arn" {
  description = "Web assets S3 bucket ARN"
  value       = aws_s3_bucket.web_assets.arn
}

output "web_assets_bucket_name" {
  description = "Web assets S3 bucket name"
  value       = aws_s3_bucket.web_assets.id
}

output "cms_assets_bucket_arn" {
  description = "CMS assets S3 bucket ARN"
  value       = aws_s3_bucket.cms_assets.arn
}

output "cms_assets_bucket_name" {
  description = "CMS assets S3 bucket name"
  value       = aws_s3_bucket.cms_assets.id
}

output "cloudfront_logs_bucket_name" {
  description = "CloudFront logs S3 bucket name"
  value       = aws_s3_bucket.cloudfront_logs.id
}
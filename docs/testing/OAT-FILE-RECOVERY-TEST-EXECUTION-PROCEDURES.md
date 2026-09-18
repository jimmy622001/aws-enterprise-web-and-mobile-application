# OAT File Recovery Test Execution Procedures

## Document Information
- **Document Title**: OAT File Recovery Test Execution Procedures
- **Version**: 1.0
- **Last Updated**: January 2025
- **Purpose**: Step-by-step procedures for executing file recovery tests during AWS migration OAT phase

---

## Table of Contents

1. [Test Preparation](#test-preparation)
2. [Test Scenarios](#test-scenarios)
3. [Verification Procedures](#verification-procedures)
4. [Rollback Procedures](#rollback-procedures)
5. [Success Criteria](#success-criteria)
6. [Test Execution Timeline](#test-execution-timeline)

---

## Test Preparation

### 1.1 Test Environment Setup

**Required Access:**
- AWS Console access (S3, CloudWatch, Lambda)
- Go Anywhere MFT Platform web console access
- On-premise server access (<MFT_AGENT_01> and <MFT_AGENT_02>)
- BMC Control-M console access
- SolarWinds monitoring console (read-only minimum)
- File server access (\\<FILE_SERVER>\file_transfer\NBS)
- Staging area access (<STAGING_DRIVE>:\AgressoMIFeed\Staging)

**Required Tools:**
- PowerShell 5.1 or higher
- AWS CLI configured with appropriate credentials
- GPG/PGP encryption tools
- Text editor for file creation
- Network monitoring tools

**Teams to Notify:**
- AWS Platform Team
- On-Premise Infrastructure Team
- MFT Team
- BMC Control-M Administrators
- Network Operations Team
- Security Team (for virus scanning tests)

---

### 1.2 Creating Dummy Test Files

#### 1.2.1 Customer Information Feed (CIF) Test File

**File Format**: XML
**File Name Convention**: `CIF_TEST_YYYYMMDD.xml`

**Sample CIF File Structure:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomerInformationFeed>
  <Header>
    <FileDate>2025-01-15</FileDate>
    <FileType>CIF</FileType>
    <RecordCount>5</RecordCount>
    <TestMode>TRUE</TestMode>
  </Header>
  <Customers>
    <Customer>
      <CustomerID>TEST00001</CustomerID>
      <FirstName>John</FirstName>
      <LastName>TestCustomer</LastName>
      <AccountNumber>ACC-TEST-001</AccountNumber>
      <Email>john.test@example.com</Email>
      <Status>Active</Status>
      <CreatedDate>2025-01-15</CreatedDate>
    </Customer>
    <Customer>
      <CustomerID>TEST00002</CustomerID>
      <FirstName>Jane</FirstName>
      <LastName>TestCustomer</LastName>
      <AccountNumber>ACC-TEST-002</AccountNumber>
      <Email>jane.test@example.com</Email>
      <Status>Active</Status>
      <CreatedDate>2025-01-15</CreatedDate>
    </Customer>
    <Customer>
      <CustomerID>TEST00003</CustomerID>
      <FirstName>Bob</FirstName>
      <LastName>TestCustomer</LastName>
      <AccountNumber>ACC-TEST-003</AccountNumber>
      <Email>bob.test@example.com</Email>
      <Status>Inactive</Status>
      <CreatedDate>2025-01-15</CreatedDate>
    </Customer>
    <Customer>
      <CustomerID>TEST00004</CustomerID>
      <FirstName>Alice</FirstName>
      <LastName>TestCustomer</LastName>
      <AccountNumber>ACC-TEST-004</AccountNumber>
      <Email>alice.test@example.com</Email>
      <Status>Active</Status>
      <CreatedDate>2025-01-15</CreatedDate>
    </Customer>
    <Customer>
      <CustomerID>TEST00005</CustomerID>
      <FirstName>Charlie</FirstName>
      <LastName>TestCustomer</LastName>
      <AccountNumber>ACC-TEST-005</AccountNumber>
      <Email>charlie.test@example.com</Email>
      <Status>Active</Status>
      <CreatedDate>2025-01-15</CreatedDate>
    </Customer>
  </Customers>
  <Footer>
    <TotalRecords>5</TotalRecords>
    <FileGenerated>2025-01-15T06:00:00Z</FileGenerated>
  </Footer>
</CustomerInformationFeed>
```

**PowerShell Script to Generate CIF Test File:**
```powershell
# Create CIF test file
$date = Get-Date -Format "yyyyMMdd"
$timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
$fileName = "CIF_TEST_$date.xml"

$cifContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<CustomerInformationFeed>
  <Header>
    <FileDate>$date</FileDate>
    <FileType>CIF</FileType>
    <RecordCount>5</RecordCount>
    <TestMode>TRUE</TestMode>
  </Header>
  <Customers>
    <Customer>
      <CustomerID>TEST00001</CustomerID>
      <FirstName>John</FirstName>
      <LastName>TestCustomer</LastName>
      <AccountNumber>ACC-TEST-001</AccountNumber>
      <Email>john.test@example.com</Email>
      <Status>Active</Status>
      <CreatedDate>$date</CreatedDate>
    </Customer>
    <Customer>
      <CustomerID>TEST00002</CustomerID>
      <FirstName>Jane</FirstName>
      <LastName>TestCustomer</LastName>
      <AccountNumber>ACC-TEST-002</AccountNumber>
      <Email>jane.test@example.com</Email>
      <Status>Active</Status>
      <CreatedDate>$date</CreatedDate>
    </Customer>
    <Customer>
      <CustomerID>TEST00003</CustomerID>
      <FirstName>Bob</FirstName>
      <LastName>TestCustomer</LastName>
      <AccountNumber>ACC-TEST-003</AccountNumber>
      <Email>bob.test@example.com</Email>
      <Status>Inactive</Status>
      <CreatedDate>$date</CreatedDate>
    </Customer>
    <Customer>
      <CustomerID>TEST00004</CustomerID>
      <FirstName>Alice</FirstName>
      <LastName>TestCustomer</LastName>
      <AccountNumber>ACC-TEST-004</AccountNumber>
      <Email>alice.test@example.com</Email>
      <Status>Active</Status>
      <CreatedDate>$date</CreatedDate>
    </Customer>
    <Customer>
      <CustomerID>TEST00005</CustomerID>
      <FirstName>Charlie</FirstName>
      <LastName>TestCustomer</LastName>
      <AccountNumber>ACC-TEST-005</AccountNumber>
      <Email>charlie.test@example.com</Email>
      <Status>Active</Status>
      <CreatedDate>$date</CreatedDate>
    </Customer>
  </Customers>
  <Footer>
    <TotalRecords>5</TotalRecords>
    <FileGenerated>$timestamp</FileGenerated>
  </Footer>
</CustomerInformationFeed>
"@

# Save to file
$cifContent | Out-File -FilePath $fileName -Encoding UTF8
Write-Host "Created CIF test file: $fileName"

# Calculate MD5 checksum
$md5 = Get-FileHash -Path $fileName -Algorithm MD5
Write-Host "MD5 Checksum: $($md5.Hash)"
```

---

#### 1.2.2 Deposits + Withdrawals Test File

**File Format**: CSV
**File Name Convention**: `Deposits_Withdrawals_TEST_YYYYMMDD.csv`

**Sample CSV Structure:**
```csv
TransactionID,AccountNumber,TransactionType,Amount,Currency,TransactionDate,Status,Reference
TXN-TEST-00001,ACC-TEST-001,DEPOSIT,1000.00,GBP,2025-01-15,COMPLETED,DEP-TEST-001
TXN-TEST-00002,ACC-TEST-002,WITHDRAWAL,500.00,GBP,2025-01-15,COMPLETED,WTH-TEST-001
TXN-TEST-00003,ACC-TEST-003,DEPOSIT,2500.00,GBP,2025-01-15,COMPLETED,DEP-TEST-002
TXN-TEST-00004,ACC-TEST-004,WITHDRAWAL,750.00,GBP,2025-01-15,COMPLETED,WTH-TEST-002
TXN-TEST-00005,ACC-TEST-005,DEPOSIT,3000.00,GBP,2025-01-15,PENDING,DEP-TEST-003
TXN-TEST-00006,ACC-TEST-001,WITHDRAWAL,200.00,GBP,2025-01-15,COMPLETED,WTH-TEST-003
TXN-TEST-00007,ACC-TEST-002,DEPOSIT,1500.00,GBP,2025-01-15,COMPLETED,DEP-TEST-004
TXN-TEST-00008,ACC-TEST-003,WITHDRAWAL,1000.00,GBP,2025-01-15,FAILED,WTH-TEST-004
TXN-TEST-00009,ACC-TEST-004,DEPOSIT,5000.00,GBP,2025-01-15,COMPLETED,DEP-TEST-005
TXN-TEST-00010,ACC-TEST-005,WITHDRAWAL,100.00,GBP,2025-01-15,COMPLETED,WTH-TEST-005
```

**PowerShell Script to Generate Deposits + Withdrawals Test File:**
```powershell
# Create Deposits + Withdrawals test file
$date = Get-Date -Format "yyyyMMdd"
$dateFormatted = Get-Date -Format "yyyy-MM-dd"
$fileName = "Deposits_Withdrawals_TEST_$date.csv"

$csvContent = @"
TransactionID,AccountNumber,TransactionType,Amount,Currency,TransactionDate,Status,Reference
TXN-TEST-00001,ACC-TEST-001,DEPOSIT,1000.00,GBP,$dateFormatted,COMPLETED,DEP-TEST-001
TXN-TEST-00002,ACC-TEST-002,WITHDRAWAL,500.00,GBP,$dateFormatted,COMPLETED,WTH-TEST-001
TXN-TEST-00003,ACC-TEST-003,DEPOSIT,2500.00,GBP,$dateFormatted,COMPLETED,DEP-TEST-002
TXN-TEST-00004,ACC-TEST-004,WITHDRAWAL,750.00,GBP,$dateFormatted,COMPLETED,WTH-TEST-002
TXN-TEST-00005,ACC-TEST-005,DEPOSIT,3000.00,GBP,$dateFormatted,PENDING,DEP-TEST-003
TXN-TEST-00006,ACC-TEST-001,WITHDRAWAL,200.00,GBP,$dateFormatted,COMPLETED,WTH-TEST-003
TXN-TEST-00007,ACC-TEST-002,DEPOSIT,1500.00,GBP,$dateFormatted,COMPLETED,DEP-TEST-004
TXN-TEST-00008,ACC-TEST-003,WITHDRAWAL,1000.00,GBP,$dateFormatted,FAILED,WTH-TEST-004
TXN-TEST-00009,ACC-TEST-004,DEPOSIT,5000.00,GBP,$dateFormatted,COMPLETED,DEP-TEST-005
TXN-TEST-00010,ACC-TEST-005,WITHDRAWAL,100.00,GBP,$dateFormatted,COMPLETED,WTH-TEST-005
"@

# Save to file
$csvContent | Out-File -FilePath $fileName -Encoding UTF8
Write-Host "Created Deposits+Withdrawals test file: $fileName"

# Calculate MD5 checksum
$md5 = Get-FileHash -Path $fileName -Algorithm MD5
Write-Host "MD5 Checksum: $($md5.Hash)"
```

---

#### 1.2.3 Daily MI (Management Information) Test File

**File Format**: XLSX (Excel)
**File Name Convention**: `Daily_MI_TEST_YYYYMMDD.xlsx`

**Manual Creation Steps:**
1. Open Excel
2. Create a new workbook
3. Add the following columns in Sheet1:
   - Date | Department | Revenue | Expenses | Profit | Status
4. Add test data (5-10 rows with fictitious data)
5. Add "TEST" watermark or header row indicating this is test data
6. Save as `Daily_MI_TEST_YYYYMMDD.xlsx`

**Sample Data for Excel:**
```
Date          | Department  | Revenue   | Expenses  | Profit    | Status
2025-01-15    | Retail      | 50000.00  | 30000.00  | 20000.00  | TEST
2025-01-15    | Corporate   | 75000.00  | 40000.00  | 35000.00  | TEST
2025-01-15    | Investment  | 100000.00 | 60000.00  | 40000.00  | TEST
2025-01-15    | Operations  | 30000.00  | 25000.00  | 5000.00   | TEST
2025-01-15    | Marketing   | 20000.00  | 18000.00  | 2000.00   | TEST
```

---

#### 1.2.4 HTML Report Test File

**File Format**: HTML
**File Name Convention**: `Report_TEST_YYYYMMDD.html`

**Sample HTML File:**
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Test Report - 2025-01-15</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 10px; border: 1px solid #ccc; }
        .watermark { color: red; font-weight: bold; font-size: 24px; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Daily Banking Report</h1>
        <p class="watermark">*** TEST DATA ONLY ***</p>
        <p>Report Date: 2025-01-15</p>
        <p>Generated: 06:00:00 UTC</p>
    </div>
    
    <h2>Transaction Summary</h2>
    <table>
        <tr>
            <th>Transaction Type</th>
            <th>Count</th>
            <th>Total Amount</th>
        </tr>
        <tr>
            <td>Deposits</td>
            <td>5</td>
            <td>£12,000.00</td>
        </tr>
        <tr>
            <td>Withdrawals</td>
            <td>5</td>
            <td>£2,550.00</td>
        </tr>
        <tr>
            <td>Transfers</td>
            <td>3</td>
            <td>£5,000.00</td>
        </tr>
    </table>
    
    <h2>Account Summary</h2>
    <table>
        <tr>
            <th>Account Number</th>
            <th>Customer Name</th>
            <th>Balance</th>
            <th>Status</th>
        </tr>
        <tr>
            <td>ACC-TEST-001</td>
            <td>John TestCustomer</td>
            <td>£25,800.00</td>
            <td>Active</td>
        </tr>
        <tr>
            <td>ACC-TEST-002</td>
            <td>Jane TestCustomer</td>
            <td>£32,500.00</td>
            <td>Active</td>
        </tr>
        <tr>
            <td>ACC-TEST-003</td>
            <td>Bob TestCustomer</td>
            <td>£15,500.00</td>
            <td>Inactive</td>
        </tr>
        <tr>
            <td>ACC-TEST-004</td>
            <td>Alice TestCustomer</td>
            <td>£45,250.00</td>
            <td>Active</td>
        </tr>
        <tr>
            <td>ACC-TEST-005</td>
            <td>Charlie TestCustomer</td>
            <td>£62,900.00</td>
            <td>Active</td>
        </tr>
    </table>
    
    <div style="margin-top: 30px; border-top: 1px solid #ccc; padding-top: 10px;">
        <p style="font-size: 12px; color: #666;">
            This is a TEST report generated for OAT file recovery testing purposes only.
            Do not use for production reporting.
        </p>
    </div>
</body>
</html>
```

---

#### 1.2.5 Fixed-Width DAT File (webtrans.dat format)

**File Format**: DAT (Fixed-width, no delimiters)
**File Name Convention**: `webtrans_TEST.dat`

**Sample Fixed-Width Format:**
```
# Fixed-width format (no headers, specific column positions)
# Positions: TransactionID(1-15), Date(16-25), Type(26-35), Amount(36-50), Account(51-65)
TXN-TEST-000012025-01-15DEPOSIT      00000001000.00ACC-TEST-001  
TXN-TEST-000022025-01-15WITHDRAWAL   00000000500.00ACC-TEST-002  
TXN-TEST-000032025-01-15DEPOSIT      00000002500.00ACC-TEST-003  
TXN-TEST-000042025-01-15WITHDRAWAL   00000000750.00ACC-TEST-004  
TXN-TEST-000052025-01-15DEPOSIT      00000003000.00ACC-TEST-005  
```

**PowerShell Script to Generate Fixed-Width DAT File:**
```powershell
# Create fixed-width webtrans.dat test file
$date = Get-Date -Format "yyyy-MM-dd"
$fileName = "webtrans_TEST.dat"

# Define fixed-width records (each field has specific width)
$records = @(
    "TXN-TEST-00001$date" + "DEPOSIT    " + "00000001000.00" + "ACC-TEST-001  ",
    "TXN-TEST-00002$date" + "WITHDRAWAL " + "00000000500.00" + "ACC-TEST-002  ",
    "TXN-TEST-00003$date" + "DEPOSIT    " + "00000002500.00" + "ACC-TEST-003  ",
    "TXN-TEST-00004$date" + "WITHDRAWAL " + "00000000750.00" + "ACC-TEST-004  ",
    "TXN-TEST-00005$date" + "DEPOSIT    " + "00000003000.00" + "ACC-TEST-005  "
)

# Write to file (no BOM, ASCII encoding)
$records | Out-File -FilePath $fileName -Encoding ASCII -NoNewline
Write-Host "Created webtrans.dat test file: $fileName"

# Verify file size
$fileInfo = Get-Item $fileName
Write-Host "File size: $($fileInfo.Length) bytes"
```

---

### 1.3 Test Data Identification

**To ensure test files are easily identifiable:**

1. **Naming Convention:**
   - All test files MUST contain `TEST` in the filename
   - Use date suffix: `_YYYYMMDD`
   - Examples: `CIF_TEST_20250115.xml`, `Deposits_Withdrawals_TEST_20250115.csv`

2. **Content Markers:**
   - Include `<TestMode>TRUE</TestMode>` in XML files
   - Include "TEST" in status fields or dedicated columns in CSV files
   - Add "*** TEST DATA ONLY ***" watermarks in HTML/Excel files

3. **Metadata Tags:**
   - Add test identifiers in file headers
   - Use fictitious customer names with "TestCustomer" surname
   - Use account numbers starting with "ACC-TEST-"

4. **Test Data Cleanup:**
   - Document all test file locations
   - Schedule cleanup after OAT completion
   - Verify test data doesn't enter production systems

---

## Test Scenarios

### TEST 1: File Not Transferred to MFT/Parity

**Test ID**: OAT-FR-001
**Objective**: Verify detection and recovery when a file fails to transfer from AWS to on-premise MFT agents
**Duration**: 30 minutes
**RTO Target**: 15 minutes

---

#### Prerequisites
- [ ] CIF test file created in AWS S3
- [ ] Go Anywhere MFT agents (<MFT_AGENT_01> and <MFT_AGENT_02>) are operational
- [ ] Network connectivity verified
- [ ] SolarWinds monitoring active
- [ ] AWS CloudWatch logs enabled
- [ ] Firewall access to temporarily block traffic

---

#### Test Procedure

**Step 1: Create and Upload Test File to AWS**
```bash
# On AWS (using AWS CLI or Lambda)
# Assuming test file already created locally

# Upload to S3 staging area
aws s3 cp CIF_TEST_20250115.xml s3://<AWS_BUCKET>/outbound/CIF_TEST_20250115.xml

# Verify upload
aws s3 ls s3://<AWS_BUCKET>/outbound/ | grep CIF_TEST

# Expected Output:
# 2025-01-15 06:00:00    5242 CIF_TEST_20250115.xml
```

**Step 2: Simulate Network Failure (Block AWS → MFT Traffic)**

**Option A: Block at AWS Security Group Level**
```bash
# Identify security group for AWS outbound traffic
aws ec2 describe-security-groups --group-ids <SG_ID>

# Add temporary deny rule for MFT agent IPs
aws ec2 revoke-security-group-egress \
  --group-id <SG_ID> \
  --ip-permissions IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges='[{CidrIp=<MFT_AGENT_IP>/32}]'

# Expected Output:
# Successfully removed egress rule
```

**Option B: Block at On-Premise Firewall Level**
```powershell
# On on-premise firewall or <MFT_AGENT_01>
# Block incoming traffic from AWS on SFTP port (22 or 2222)

New-NetFirewallRule -DisplayName "TEST_BLOCK_AWS_MFT" `
  -Direction Inbound `
  -Action Block `
  -Protocol TCP `
  -LocalPort 22 `
  -RemoteAddress <AWS_PUBLIC_IP>

# Expected Output:
# Name                  : TEST_BLOCK_AWS_MFT
# DisplayName           : TEST_BLOCK_AWS_MFT
# Enabled               : True
```

**Step 3: Trigger File Transfer from AWS**
```bash
# Trigger Go Anywhere workflow or Lambda function to transfer file
# This could be via scheduled job or manual trigger

# Example: Invoke Lambda function
aws lambda invoke \
  --function-name FileTransferToOnPremise \
  --payload '{"fileName":"CIF_TEST_20250115.xml"}' \
  response.json

# Check response
cat response.json
```

**Step 4: Verify Transfer Failure**

**On AWS Side:**
```bash
# Check CloudWatch logs for transfer errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/FileTransferToOnPremise \
  --filter-pattern "ERROR" \
  --start-time $(date -d '5 minutes ago' +%s)000

# Expected Output:
# ERROR: Connection timeout to <MFT_AGENT_01>
# ERROR: Failed to transfer CIF_TEST_20250115.xml
# RETRY: Attempt 1 of 3
```

**On Go Anywhere MFT Console:**
1. Login to Go Anywhere web console
2. Navigate to: **Logs > Transfer Logs**
3. Filter by: Last 10 minutes, Status: Failed
4. Verify entry:
   ```
   Time: 06:05:00
   File: CIF_TEST_20250115.xml
   Source: AWS_S3
   Destination: <MFT_AGENT_01>
   Status: FAILED
   Error: Connection refused / Timeout
   ```

**Step 5: Verify SolarWinds Alert**

**Expected SolarWinds Alert (within 2 minutes):**
```
⚠️ Subject: File Transfer Failure - AWS to MFT
Priority: HIGH
Body:
  Alert Type: File Transfer Failure
  Source: AWS S3 Bucket <AWS_BUCKET>
  Destination: <MFT_AGENT_01>
  File: CIF_TEST_20250115.xml
  Error: Connection timeout
  Retry Status: In Progress (Attempt 1 of 3)
  Time: 2025-01-15 06:05:15
  Action Required: Check network connectivity between AWS and on-premise
  
  Troubleshooting Steps:
  1. Verify VPN connectivity
  2. Check firewall rules
  3. Verify MFT agent status
  4. Check AWS security groups
```

**Verification in SolarWinds:**
1. Login to SolarWinds console
2. Navigate to: **Alerts > Active Alerts**
3. Filter by: MFT, Last 5 minutes
4. Verify alert appears with correct details

**Step 6: Verify Retry Logic**

```bash
# Monitor AWS CloudWatch for retry attempts
aws logs tail /aws/lambda/FileTransferToOnPremise --follow

# Expected Output:
# 06:05:00 - ERROR: Transfer failed, attempt 1 of 3
# 06:07:00 - RETRY: Attempting transfer, attempt 2 of 3
# 06:09:00 - RETRY: Attempting transfer, attempt 3 of 3
# 06:11:00 - FAILED: All retry attempts exhausted
```

**Check Go Anywhere MFT Retry Queue:**
1. Go Anywhere Console: **Workflows > Retry Queue**
2. Verify `CIF_TEST_20250115.xml` is queued
3. Check retry count: 3/3
4. Status: Pending Manual Intervention

**Step 7: Restore Network Connectivity**

**Remove Firewall Block:**
```powershell
# On on-premise firewall or <MFT_AGENT_01>
Remove-NetFirewallRule -DisplayName "TEST_BLOCK_AWS_MFT"

# Expected Output:
# Successfully removed firewall rule
```

**Or restore AWS Security Group:**
```bash
# Restore egress rule
aws ec2 authorize-security-group-egress \
  --group-id <SG_ID> \
  --ip-permissions IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges='[{CidrIp=<MFT_AGENT_IP>/32}]'
```

**Verify Connectivity:**
```powershell
# From AWS or local machine with AWS access
Test-NetConnection -ComputerName <MFT_AGENT_01> -Port 22

# Expected Output:
# ComputerName     : <MFT_AGENT_01>
# RemoteAddress    : <IP_ADDRESS>
# TcpTestSucceeded : True
```

**Step 8: Manually Retry File Transfer**

**Option A: Retry from Go Anywhere Console**
1. Go Anywhere Console: **Workflows > Retry Queue**
2. Select `CIF_TEST_20250115.xml`
3. Click **"Retry Now"**
4. Monitor transfer status

**Option B: Retry from AWS**
```bash
# Re-invoke Lambda function
aws lambda invoke \
  --function-name FileTransferToOnPremise \
  --payload '{"fileName":"CIF_TEST_20250115.xml","manualRetry":true}' \
  response.json

# Check response
cat response.json
# Expected: {"status":"success","transferred":true}
```

**Step 9: Verify Successful Transfer**

**On <MFT_AGENT_01>:**
```powershell
# Check if file arrived in landing zone
Test-Path "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml"

# Expected Output: True

# Verify file size and timestamp
Get-Item "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml" | Select Name, Length, LastWriteTime

# Expected Output:
# Name                       Length LastWriteTime
# ----                       ------ -------------
# CIF_TEST_20250115.xml      5242   1/15/2025 6:12:00 AM
```

**Verify in Go Anywhere Console:**
1. **Logs > Transfer Logs**
2. Filter: Last 10 minutes, Status: Success
3. Verify entry:
   ```
   Time: 06:12:00
   File: CIF_TEST_20250115.xml
   Source: AWS_S3
   Destination: <MFT_AGENT_01>
   Status: SUCCESS
   Transfer Time: 2.3 seconds
   ```

**Step 10: Verify File Integrity**

```powershell
# Calculate MD5 checksum of received file
$receivedFile = "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml"
$receivedMD5 = Get-FileHash -Path $receivedFile -Algorithm MD5
Write-Host "Received MD5: $($receivedMD5.Hash)"

# Compare with original AWS S3 file checksum
# (Original MD5 should be logged during file creation in Step 1)
```

**AWS S3 ETag verification:**
```bash
aws s3api head-object \
  --bucket <AWS_BUCKET> \
  --key outbound/CIF_TEST_20250115.xml \
  --query 'ETag' --output text

# Compare with received file MD5
```

**Step 11: Verify SolarWinds Recovery Alert**

**Expected SolarWinds Alert:**
```
✅ Subject: File Transfer Recovered - AWS to MFT
Priority: INFO
Body:
  Alert Type: File Transfer Success (Recovery)
  Source: AWS S3 Bucket <AWS_BUCKET>
  Destination: <MFT_AGENT_01>
  File: CIF_TEST_20250115.xml
  Status: Successfully transferred after manual retry
  Original Failure Time: 2025-01-15 06:05:00
  Recovery Time: 2025-01-15 06:12:00
  Downtime Duration: 7 minutes
  File Integrity: Verified (MD5 match)
  Time: 2025-01-15 06:12:15
```

---

#### Success Criteria

- [ ] File transfer initially failed due to network block
- [ ] AWS CloudWatch logged connection errors
- [ ] Go Anywhere MFT detected transfer failure
- [ ] SolarWinds alert triggered within 2 minutes
- [ ] Retry logic executed 3 attempts
- [ ] File queued for manual intervention after retries exhausted
- [ ] Network connectivity successfully restored
- [ ] Manual retry successfully transferred file
- [ ] File arrived at \\<FILE_SERVER>\file_transfer\NBS
- [ ] File integrity verified (MD5 checksum match)
- [ ] SolarWinds recovery alert triggered
- [ ] **Total recovery time: < 15 minutes (RTO met)**

---

#### Rollback/Cleanup

```powershell
# Remove test file from all locations
Remove-Item "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml" -Force

# On AWS
aws s3 rm s3://<AWS_BUCKET>/outbound/CIF_TEST_20250115.xml

# Verify firewall rules removed
Get-NetFirewallRule -DisplayName "TEST_BLOCK_AWS_MFT"
# Expected: No results

# Clear Go Anywhere retry queue (if any pending)
# Via Go Anywhere Console: Workflows > Retry Queue > Clear Completed

# Document results in test log
```

---

#### Troubleshooting

**Issue: SolarWinds alert not triggered**
- Verify SolarWinds monitoring rules are active
- Check alert notification channels (email, SMS)
- Verify MFT integration with SolarWinds

**Issue: File transfer doesn't retry automatically**
- Check Go Anywhere workflow retry configuration
- Verify AWS Lambda retry logic
- Check Go Anywhere agent connection to platform

**Issue: File integrity check fails**
- Compare file sizes
- Check for corruption during transfer
- Verify encryption/decryption if applicable
- Re-transfer file

---

### TEST 2: Dependent File Processing Failure

**Test ID**: OAT-FR-002
**Objective**: Verify handling when one file processes successfully but a dependent file fails
**Duration**: 45 minutes
**RTO Target**: 20 minutes

---

#### Prerequisites
- [ ] Two test files created: CIF and Deposits+Withdrawals
- [ ] BMC Control-M jobs configured with dependencies
- [ ] Go Anywhere MFT agents operational
- [ ] SolarWinds monitoring active
- [ ] Access to Control-M console

---

#### Test Procedure

**Step 1: Create Two Dependent Test Files**

```powershell
# Create first file (CIF - will succeed)
$date = Get-Date -Format "yyyyMMdd"
.\Generate-CIF-TestFile.ps1
# Output: CIF_TEST_20250115.xml

# Create second file (Deposits+Withdrawals - will be corrupted)
.\Generate-DepositsWithdrawals-TestFile.ps1
# Output: Deposits_Withdrawals_TEST_20250115.csv
```

**Step 2: Upload First File to AWS (Success Path)**

```bash
# Upload CIF file normally
aws s3 cp CIF_TEST_20250115.xml s3://<AWS_BUCKET>/outbound/

# Trigger transfer to on-premise
aws lambda invoke \
  --function-name FileTransferToOnPremise \
  --payload '{"fileName":"CIF_TEST_20250115.xml"}' \
  response.json

# Verify successful transfer
aws logs tail /aws/lambda/FileTransferToOnPremise --follow
# Expected: Transfer successful
```

**Step 3: Verify First File Processing**

```powershell
# Check file arrived at landing zone
Test-Path "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml"
# Expected: True

# Wait for Control-M job to process
# Job: P_MIS5_Agresso_MI_Staging_Copy
# Should copy to staging area

Start-Sleep -Seconds 60

# Verify in staging
Test-Path "<STAGING_DRIVE>:\AgressoMIFeed\Staging\CIF_TEST_20250115.xml"
# Expected: True
```

**Step 4: Corrupt Second File and Upload**

```powershell
# Create corrupted version of Deposits+Withdrawals file
$originalFile = "Deposits_Withdrawals_TEST_20250115.csv"
$corruptedFile = "Deposits_Withdrawals_TEST_20250115_CORRUPT.csv"

# Read first half of file only (simulate corruption)
$content = Get-Content $originalFile
$halfContent = $content[0..([Math]::Floor($content.Count / 2))]
$halfContent | Out-File $corruptedFile -Encoding UTF8

Write-Host "Created corrupted file: $corruptedFile"
Write-Host "Original size: $(Get-Item $originalFile).Length bytes"
Write-Host "Corrupted size: $(Get-Item $corruptedFile).Length bytes"
```

```bash
# Upload corrupted file to AWS
aws s3 cp Deposits_Withdrawals_TEST_20250115_CORRUPT.csv \
  s3://<AWS_BUCKET>/outbound/Deposits_Withdrawals_TEST_20250115.csv

# Trigger transfer
aws lambda invoke \
  --function-name FileTransferToOnPremise \
  --payload '{"fileName":"Deposits_Withdrawals_TEST_20250115.csv"}' \
  response.json
```

**Step 5: Monitor Control-M Job Failure**

**Access Control-M Console:**
1. Login to BMC Control-M
2. Navigate to **Monitoring > Job Status**
3. Filter by: Date=Today, Job Name contains "Websave"

**Expected Job Flow:**
```
Job: P_MIS5_Transfer_WebSave_Sun_To_Fri
Status: SUCCESS (CIF file processed)
↓
Job: P_MIS5_Agresso_MI_Staging_Copy
Status: SUCCESS (CIF copied to staging)
↓
Job: P_COPY_WEBSAVE_FILES_TEMP
Status: PARTIAL SUCCESS (CIF processed, Deposits+Withdrawals failed)
↓
Job: P_Websave_Agresso_Post_Cloud
Status: WAITING (Dependency not met - missing Deposits+Withdrawals)
↓
Job: P_Websave_Agresso_SFTP_Send
Status: NOT STARTED (Upstream failure)
```

**Step 6: Verify Control-M Error Logs**

```powershell
# Check Control-M output logs (location varies by installation)
# Example path: <CONTROLM_LOGS>\P_COPY_WEBSAVE_FILES_TEMP_20250115.log

Get-Content "<CONTROLM_LOGS>\P_COPY_WEBSAVE_FILES_TEMP_20250115.log" -Tail 50

# Expected errors:
# ERROR: Invalid CSV format in Deposits_Withdrawals_TEST_20250115.csv
# ERROR: Unexpected end of file at line 6
# ERROR: Record count mismatch - Expected 10, Found 5
# WARNING: CIF_TEST_20250115.xml processed successfully
# ERROR: Processing failed for 1 of 2 files
```

**Step 7: Verify SolarWinds Alert**

**Expected SolarWinds Alert:**
```
⚠️ Subject: Control-M Job Partial Failure - File Processing
Priority: HIGH
Body:
  Alert Type: Control-M Job Error
  Job Name: P_COPY_WEBSAVE_FILES_TEMP
  Status: Partial Failure
  Files Processed Successfully: 1
    - CIF_TEST_20250115.xml (SUCCESS)
  Files Failed: 1
    - Deposits_Withdrawals_TEST_20250115.csv (FAILED - Corrupt/Incomplete)
  Error: CSV validation failed - unexpected end of file
  Dependent Jobs Blocked: 2
    - P_Websave_Agresso_Post_Cloud (WAITING)
    - P_Websave_Agresso_SFTP_Send (NOT STARTED)
  Time: 2025-01-15 06:20:00
  Action Required: 
    1. Investigate Deposits_Withdrawals_TEST_20250115.csv
    2. Request re-transfer from AWS
    3. Re-run failed processing job
```

**Step 8: Investigate File Corruption**

```powershell
# Check file on landing zone
$file = "\\<FILE_SERVER>\file_transfer\NBS\Deposits_Withdrawals_TEST_20250115.csv"

# Verify file exists
Test-Path $file
# Expected: True

# Check file size (should be smaller than expected)
$fileInfo = Get-Item $file
Write-Host "File size: $($fileInfo.Length) bytes"
Write-Host "Last modified: $($fileInfo.LastWriteTime)"

# Count lines
$lineCount = (Get-Content $file).Count
Write-Host "Line count: $lineCount"
# Expected: ~6 lines (header + 5 records) instead of 11 (header + 10 records)

# View file content
Get-Content $file
# Verify it's truncated
```

**Step 9: Request and Restore Correct File**

**Option A: Restore from AWS S3 Backup**
```bash
# Check if uncorrupted version exists in AWS
aws s3 ls s3://<AWS_BUCKET>/backup/ | grep Deposits_Withdrawals

# If backup exists, copy to outbound
aws s3 cp s3://<AWS_BUCKET>/backup/Deposits_Withdrawals_TEST_20250115.csv \
  s3://<AWS_BUCKET>/outbound/Deposits_Withdrawals_TEST_20250115.csv --force

# Re-trigger transfer
aws lambda invoke \
  --function-name FileTransferToOnPremise \
  --payload '{"fileName":"Deposits_Withdrawals_TEST_20250115.csv","forceRetransfer":true}' \
  response.json
```

**Option B: Generate Fresh File**
```powershell
# Regenerate uncorrupted file
.\Generate-DepositsWithdrawals-TestFile.ps1

# Upload to AWS
aws s3 cp Deposits_Withdrawals_TEST_20250115.csv s3://<AWS_BUCKET>/outbound/ --force

# Trigger transfer
aws lambda invoke \
  --function-name FileTransferToOnPremise \
  --payload '{"fileName":"Deposits_Withdrawals_TEST_20250115.csv"}' \
  response.json
```

**Step 10: Verify Corrected File Transfer**

```powershell
# Wait for file to arrive
Start-Sleep -Seconds 30

# Check file on landing zone
$file = "\\<FILE_SERVER>\file_transfer\NBS\Deposits_Withdrawals_TEST_20250115.csv"
$fileInfo = Get-Item $file

# Verify timestamp is recent (just transferred)
Write-Host "Last modified: $($fileInfo.LastWriteTime)"

# Verify line count is correct
$lineCount = (Get-Content $file).Count
Write-Host "Line count: $lineCount"
# Expected: 11 lines (header + 10 records)

# Verify file size is reasonable
Write-Host "File size: $($fileInfo.Length) bytes"
# Should be ~double the corrupted file size
```

**Step 11: Re-run Failed Control-M Jobs**

**In Control-M Console:**
1. Navigate to **Monitoring > Job Status**
2. Find job: `P_COPY_WEBSAVE_FILES_TEMP`
3. Right-click > **Rerun**
4. Confirm rerun

**Monitor Job Execution:**
```
Job: P_COPY_WEBSAVE_FILES_TEMP
Status: RUNNING → SUCCESS
↓
Job: P_Websave_Agresso_Post_Cloud
Status: RUNNING (dependency met) → SUCCESS
Output: webtrans_TEST.dat created
↓
Job: P_Websave_Agresso_SFTP_Send
Status: RUNNING → SUCCESS
File transferred to Go Anywhere Cloud
```

**Step 12: Verify Complete Processing**

```powershell
# Verify both files in staging
Test-Path "<STAGING_DRIVE>:\AgressoMIFeed\Staging\CIF_TEST_20250115.xml"
Test-Path "<STAGING_DRIVE>:\AgressoMIFeed\Staging\Deposits_Withdrawals_TEST_20250115.csv"
# Expected: Both True

# Verify webtrans.dat created (output of reformatting job)
Test-Path "<STAGING_DRIVE>:\AgressoMIFeed\Output\webtrans_TEST.dat"
# Expected: True

# Check file was uploaded to Go Anywhere Cloud (check Go Anywhere console)
```

**Go Anywhere Cloud Verification:**
1. Login to Go Anywhere Cloud console (RevX hosted)
2. Navigate to **Files > Received Files**
3. Filter by: Today, Filename contains "webtrans"
4. Verify: `webtrans_TEST.dat` present with correct timestamp

**Step 13: Verify SolarWinds Recovery Alert**

**Expected SolarWinds Alert:**
```
✅ Subject: Control-M Job Recovery Complete
Priority: INFO
Body:
  Alert Type: Control-M Job Success (Recovery)
  Job Name: P_COPY_WEBSAVE_FILES_TEMP
  Status: SUCCESS (All files processed)
  Previous Status: Partial Failure
  Files Processed Successfully: 2
    - CIF_TEST_20250115.xml (SUCCESS)
    - Deposits_Withdrawals_TEST_20250115.csv (SUCCESS - Retransferred)
  Dependent Jobs Completed: 2
    - P_Websave_Agresso_Post_Cloud (SUCCESS)
    - P_Websave_Agresso_SFTP_Send (SUCCESS)
  Output File: webtrans_TEST.dat (Transferred to Go Anywhere Cloud)
  Original Failure Time: 2025-01-15 06:20:00
  Recovery Time: 2025-01-15 06:35:00
  Total Recovery Duration: 15 minutes
  Time: 2025-01-15 06:35:15
```

---

#### Success Criteria

- [ ] First file (CIF) processed successfully
- [ ] Second file (Deposits+Withdrawals) initially failed due to corruption
- [ ] Control-M detected partial processing failure
- [ ] Dependent jobs (P_Websave_Agresso_Post_Cloud, P_Websave_Agresso_SFTP_Send) blocked
- [ ] SolarWinds alert triggered for partial failure
- [ ] Corrupted file identified and investigated
- [ ] Corrected file successfully retransferred from AWS
- [ ] Control-M jobs rerun successfully
- [ ] All files processed completely
- [ ] webtrans.dat created and uploaded to Go Anywhere Cloud
- [ ] SolarWinds recovery alert triggered
- [ ] **Total recovery time: < 20 minutes (RTO met)**

---

#### Rollback/Cleanup

```powershell
# Remove test files from all locations
Remove-Item "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml" -Force
Remove-Item "\\<FILE_SERVER>\file_transfer\NBS\Deposits_Withdrawals_TEST_20250115.csv" -Force
Remove-Item "<STAGING_DRIVE>:\AgressoMIFeed\Staging\CIF_TEST_20250115.xml" -Force
Remove-Item "<STAGING_DRIVE>:\AgressoMIFeed\Staging\Deposits_Withdrawals_TEST_20250115.csv" -Force
Remove-Item "<STAGING_DRIVE>:\AgressoMIFeed\Output\webtrans_TEST.dat" -Force

# Remove from AWS S3
aws s3 rm s3://<AWS_BUCKET>/outbound/CIF_TEST_20250115.xml
aws s3 rm s3://<AWS_BUCKET>/outbound/Deposits_Withdrawals_TEST_20250115.csv

# Remove from Go Anywhere Cloud (via console or API)
# Login to Go Anywhere Cloud > Files > Delete webtrans_TEST.dat

# Reset Control-M jobs if needed (mark as completed)
# Control-M Console > Job Status > Mark Complete

# Document results
```

---

#### Troubleshooting

**Issue: Control-M doesn't detect dependency**
- Verify job dependency configuration in Control-M
- Check Control-M scheduling conditions
- Verify file naming conventions match expected patterns

**Issue: Corrupted file not rejected**
- Check validation rules in P_COPY_WEBSAVE_FILES_TEMP job
- Verify CSV parsing logic
- Add stricter validation if needed

**Issue: Rerun doesn't trigger dependent jobs**
- Manually trigger dependent jobs
- Check Control-M condition codes
- Verify dependencies are configured correctly

---

### TEST 3: File Decryption Failure

**Test ID**: OAT-FR-003
**Objective**: Verify handling when a file cannot be decrypted properly
**Duration**: 30 minutes
**RTO Target**: 10 minutes

---

#### Prerequisites
- [ ] Test file created (CIF or Deposits+Withdrawals)
- [ ] GPG/PGP encryption tools installed
- [ ] Go Anywhere MFT configured with decryption workflow
- [ ] Correct and incorrect encryption keys available
- [ ] SolarWinds monitoring active

---

#### Test Procedure

**Step 1: Create Test File**
```powershell
.\Generate-CIF-TestFile.ps1
# Output: CIF_TEST_20250115.xml
```

**Step 2: Encrypt File with WRONG Key**

```powershell
# Generate a temporary wrong key pair
gpg --batch --gen-key <<EOF
Key-Type: RSA
Key-Length: 2048
Name-Real: Wrong Test Key
Name-Email: wrongkey@test.local
Expire-Date: 1d
%no-protection
%commit
EOF

# Export wrong public key
gpg --export --armor "Wrong Test Key" > wrong_public_key.asc

# Encrypt file with wrong key
gpg --encrypt --recipient "Wrong Test Key" --output CIF_TEST_20250115.xml.gpg CIF_TEST_20250115.xml

Write-Host "File encrypted with WRONG key: CIF_TEST_20250115.xml.gpg"
```

**Step 3: Upload Encrypted File to AWS**

```bash
# Upload encrypted file to AWS S3
aws s3 cp CIF_TEST_20250115.xml.gpg s3://<AWS_BUCKET>/outbound/

# Trigger transfer to on-premise
aws lambda invoke \
  --function-name FileTransferToOnPremise \
  --payload '{"fileName":"CIF_TEST_20250115.xml.gpg"}' \
  response.json
```

**Step 4: Verify File Transfer to On-Premise**

```powershell
# Check file arrived at landing zone
Start-Sleep -Seconds 30
Test-Path "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml.gpg"
# Expected: True

$fileInfo = Get-Item "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml.gpg"
Write-Host "File transferred: $($fileInfo.Name)"
Write-Host "Size: $($fileInfo.Length) bytes"
```

**Step 5: Attempt Decryption (Will Fail)**

**In Go Anywhere MFT Console:**
1. Navigate to **Workflows > Active Workflows**
2. Find workflow: "Decrypt Incoming Files"
3. Workflow should automatically trigger on file arrival
4. Monitor execution

**Expected Workflow Failure:**
```
Workflow: Decrypt_Incoming_Files
Step 1: Detect File - SUCCESS (CIF_TEST_20250115.xml.gpg found)
Step 2: Decrypt File - FAILED
Error: gpg: decryption failed: No secret key
Error Details: The file was encrypted with a key not available in keyring
Step 3: Move to Processed - SKIPPED
Status: FAILED
```

**Or via Command Line (if Go Anywhere uses gpg):**
```powershell
# On <MFT_AGENT_01> or decryption server
gpg --decrypt "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml.gpg"

# Expected Output:
# gpg: encrypted with 2048-bit RSA key, ID XXXXXXXX, created 2025-01-15
#      "Wrong Test Key <wrongkey@test.local>"
# gpg: decryption failed: No secret key
```

**Step 6: Verify Error Logging**

```powershell
# Check Go Anywhere MFT logs
# Log location varies - check Go Anywhere installation directory
Get-Content "<GOANYWHERE_LOGS>\workflow_execution.log" -Tail 50

# Expected log entries:
# [2025-01-15 06:40:00] INFO - Workflow Decrypt_Incoming_Files started
# [2025-01-15 06:40:01] INFO - File detected: CIF_TEST_20250115.xml.gpg
# [2025-01-15 06:40:02] ERROR - Decryption failed: No secret key available
# [2025-01-15 06:40:02] ERROR - Key ID: XXXXXXXX not found in keyring
# [2025-01-15 06:40:02] ERROR - File: CIF_TEST_20250115.xml.gpg
# [2025-01-15 06:40:03] INFO - Workflow Decrypt_Incoming_Files failed
```

**Step 7: Verify SolarWinds Alert**

**Expected SolarWinds Alert:**
```
⚠️ Subject: File Decryption Failure - MFT
Priority: HIGH
Body:
  Alert Type: File Decryption Error
  File: CIF_TEST_20250115.xml.gpg
  Location: \\<FILE_SERVER>\file_transfer\NBS
  Workflow: Decrypt_Incoming_Files
  Status: FAILED
  Error: GPG decryption failed - No secret key
  Key ID Required: XXXXXXXX
  Key ID Available: YYYYYYYY (Production Key)
  Time: 2025-01-15 06:40:05
  Action Required:
    1. Verify file was encrypted with correct public key
    2. Request re-encryption with correct key from sender
    3. Import correct private key if missing
    4. Retry decryption after correction
```

**Step 8: Diagnose Decryption Issue**

```powershell
# Check which keys are available in keyring
gpg --list-keys

# Expected Output (should NOT include wrong key):
# pub   rsa2048 2024-01-01 [SC]
#       YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY
# uid           [ultimate] Production Key <prod@company.com>
# sub   rsa2048 2024-01-01 [E]

# Check encrypted file metadata
gpg --list-packets "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml.gpg"

# Expected Output:
# :pubkey enc packet: version 3, algo 1, keyid XXXXXXXXXXXXXXXX
# ...
# (Shows the file is encrypted for key XXXXXXXX which is NOT in our keyring)
```

**Step 9: Re-encrypt with Correct Key**

**Get correct production public key:**
```powershell
# Export correct public key (should already exist)
gpg --export --armor "Production Key" > production_public_key.asc

# Verify key
gpg --import --dry-run production_public_key.asc
```

**Re-encrypt original file:**
```powershell
# Delete wrongly encrypted file
Remove-Item CIF_TEST_20250115.xml.gpg -Force

# Encrypt with CORRECT key
gpg --encrypt --recipient "Production Key" --output CIF_TEST_20250115.xml.gpg CIF_TEST_20250115.xml

Write-Host "File re-encrypted with CORRECT key: CIF_TEST_20250115.xml.gpg"

# Verify encryption recipient
gpg --list-packets CIF_TEST_20250115.xml.gpg
# Should show correct Key ID (YYYYYYYY)
```

**Step 10: Re-upload Correctly Encrypted File**

```bash
# Remove old file from AWS
aws s3 rm s3://<AWS_BUCKET>/outbound/CIF_TEST_20250115.xml.gpg

# Upload re-encrypted file
aws s3 cp CIF_TEST_20250115.xml.gpg s3://<AWS_BUCKET>/outbound/

# Trigger transfer
aws lambda invoke \
  --function-name FileTransferToOnPremise \
  --payload '{"fileName":"CIF_TEST_20250115.xml.gpg","forceRetransfer":true}' \
  response.json
```

**Step 11: Verify Successful Decryption**

```powershell
# Wait for file transfer
Start-Sleep -Seconds 30

# Check file arrival
Test-Path "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml.gpg"
# Expected: True (file re-arrived with newer timestamp)

# Verify file timestamp (should be recent)
$fileInfo = Get-Item "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml.gpg"
Write-Host "File timestamp: $($fileInfo.LastWriteTime)"
```

**Monitor Go Anywhere Workflow:**
1. Go Anywhere Console > Workflows > Recent Executions
2. Find: Decrypt_Incoming_Files (latest execution)
3. Verify status:

```
Workflow: Decrypt_Incoming_Files
Step 1: Detect File - SUCCESS
Step 2: Decrypt File - SUCCESS
  Output: CIF_TEST_20250115.xml (decrypted)
  Location: \\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml
Step 3: Move Encrypted to Processed - SUCCESS
  Moved: CIF_TEST_20250115.xml.gpg → \\<FILE_SERVER>\file_transfer\NBS\Processed\
Step 4: Virus Scan Decrypted File - SUCCESS
Status: COMPLETED
```

**Verify decrypted file exists:**
```powershell
# Check decrypted file
Test-Path "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml"
# Expected: True

# Verify file integrity (compare with original)
$originalMD5 = Get-FileHash -Path "CIF_TEST_20250115.xml" -Algorithm MD5
$decryptedMD5 = Get-FileHash -Path "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml" -Algorithm MD5

Write-Host "Original MD5:  $($originalMD5.Hash)"
Write-Host "Decrypted MD5: $($decryptedMD5.Hash)"
# Expected: Both MD5 hashes match
```

**Step 12: Verify SolarWinds Recovery Alert**

**Expected SolarWinds Alert:**
```
✅ Subject: File Decryption Success (Recovery)
Priority: INFO
Body:
  Alert Type: File Decryption Success
  File: CIF_TEST_20250115.xml.gpg → CIF_TEST_20250115.xml
  Location: \\<FILE_SERVER>\file_transfer\NBS
  Workflow: Decrypt_Incoming_Files
  Status: SUCCESS
  Previous Failure Time: 2025-01-15 06:40:00
  Recovery Time: 2025-01-15 06:45:00
  Recovery Duration: 5 minutes
  File Integrity: Verified (MD5 match with original)
  Next Step: File ready for Control-M processing
  Time: 2025-01-15 06:45:10
```

---

#### Success Criteria

- [ ] File encrypted with wrong key initially
- [ ] File transferred successfully to on-premise
- [ ] Go Anywhere decryption workflow failed with clear error
- [ ] SolarWinds alert triggered within 1 minute
- [ ] Error logs clearly identified missing key
- [ ] File re-encrypted with correct production key
- [ ] File re-uploaded and transferred successfully
- [ ] Go Anywhere decryption workflow succeeded
- [ ] Decrypted file integrity verified (MD5 match)
- [ ] Encrypted file moved to Processed folder
- [ ] SolarWinds recovery alert triggered
- [ ] **Total recovery time: < 10 minutes (RTO met)**

---

#### Rollback/Cleanup

```powershell
# Remove test files
Remove-Item "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml" -Force
Remove-Item "\\<FILE_SERVER>\file_transfer\NBS\Processed\CIF_TEST_20250115.xml.gpg" -Force -ErrorAction SilentlyContinue

# Remove from AWS
aws s3 rm s3://<AWS_BUCKET>/outbound/CIF_TEST_20250115.xml.gpg

# Remove wrong test key from keyring
gpg --delete-secret-keys "Wrong Test Key"
gpg --delete-keys "Wrong Test Key"

# Remove local test files
Remove-Item CIF_TEST_20250115.xml -Force
Remove-Item CIF_TEST_20250115.xml.gpg -Force
Remove-Item wrong_public_key.asc -Force

# Document results
```

---

#### Troubleshooting

**Issue: Cannot import production key**
- Verify key file format (ASCII armored .asc or binary .gpg)
- Check file permissions
- Verify key is not expired
- Try: `gpg --import --verbose production_public_key.asc`

**Issue: Decryption succeeds even with wrong key**
- Verify Go Anywhere is using correct keyring
- Check if multiple keys are configured
- Verify key ID in encrypted file matches available key

**Issue: File not automatically decrypted**
- Verify Go Anywhere workflow is enabled
- Check workflow trigger conditions (file pattern, location)
- Manually trigger workflow from console
- Check Go Anywhere agent connection to platform

---

### TEST 4: Virus Scanning Failure

**Test ID**: OAT-FR-004
**Objective**: Verify handling when a file fails virus scanning
**Duration**: 30 minutes
**RTO Target**: 5 minutes

---

#### Prerequisites
- [ ] Test file created (CIF or Deposits+Withdrawals)
- [ ] Antivirus software installed and active on \\<FILE_SERVER> or <MFT_AGENT_01>
- [ ] EICAR test virus string available (safe test virus)
- [ ] Go Anywhere MFT configured with virus scanning workflow
- [ ] SolarWinds monitoring active
- [ ] Quarantine location configured

---

#### Test Procedure

**Step 1: Create Test File with EICAR Test Virus**

**What is EICAR?**
EICAR (European Institute for Computer Antivirus Research) test file is a safe, industry-standard file used to test antivirus software. It is NOT a real virus but will be detected by all antivirus software.

**EICAR Test String:**
```
X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*
```

**Create Infected Test File:**
```powershell
# Create EICAR test virus file
$eicarString = 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*'
$eicarString | Out-File -FilePath "EICAR_TEST.txt" -Encoding ASCII -NoNewline

Write-Host "EICAR test virus file created: EICAR_TEST.txt"
Write-Host "WARNING: This will be detected as a virus by antivirus software (safe for testing)"
```

**Embed EICAR in Test Excel File:**
```powershell
# Create Excel file with EICAR embedded
# Note: This requires Excel to be installed
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$workbook = $excel.Workbooks.Add()
$worksheet = $workbook.Worksheets.Item(1)

# Add test data
$worksheet.Cells.Item(1,1) = "Date"
$worksheet.Cells.Item(1,2) = "Department"
$worksheet.Cells.Item(1,3) = "Revenue"
$worksheet.Cells.Item(2,1) = "2025-01-15"
$worksheet.Cells.Item(2,2) = "Retail"
$worksheet.Cells.Item(2,3) = "50000.00"

# Add EICAR string (hidden in a cell)
$worksheet.Cells.Item(100,100) = $eicarString

# Save file
$fileName = "Daily_MI_TEST_INFECTED_$(Get-Date -Format 'yyyyMMdd').xlsx"
$workbook.SaveAs("$(Get-Location)\$fileName")
$workbook.Close()
$excel.Quit()

[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null

Write-Host "Infected Excel file created: $fileName"
Write-Host "CAUTION: This file will trigger antivirus alerts"
```

**Alternative: Embed EICAR in CSV:**
```powershell
# Simpler method - CSV with EICAR string
$csvContent = @"
TransactionID,AccountNumber,Amount,Note
TXN-001,ACC-001,1000.00,Normal transaction
TXN-002,ACC-002,500.00,Test data
TXN-003,ACC-003,750.00,X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*
"@

$fileName = "Deposits_Withdrawals_TEST_INFECTED_$(Get-Date -Format 'yyyyMMdd').csv"
$csvContent | Out-File -FilePath $fileName -Encoding ASCII

Write-Host "Infected CSV file created: $fileName"
```

**Step 2: Upload Infected File to AWS**

**⚠️ WARNING: Disable local antivirus temporarily or exclude folder**
```powershell
# Add exclusion to Windows Defender (requires admin)
Add-MpPreference -ExclusionPath "$(Get-Location)"

# Upload to AWS
aws s3 cp $fileName s3://<AWS_BUCKET>/outbound/

# Remove local exclusion after upload
Remove-MpPreference -ExclusionPath "$(Get-Location)"
```

**Step 3: Trigger File Transfer**

```bash
# Trigger transfer to on-premise
aws lambda invoke \
  --function-name FileTransferToOnPremise \
  --payload "{\"fileName\":\"$fileName\"}" \
  response.json

# Monitor CloudWatch logs
aws logs tail /aws/lambda/FileTransferToOnPremise --follow
```

**Step 4: Monitor File Transfer and Virus Scan**

**Expected Behavior at Landing Zone:**
```
1. File arrives at \\<FILE_SERVER>\file_transfer\NBS\
2. Antivirus software scans file automatically (real-time protection)
3. Antivirus detects EICAR test virus
4. File is QUARANTINED immediately
5. Alert is generated
```

**Check Antivirus Logs (Windows Defender example):**
```powershell
# Check Windows Defender detection logs
Get-WinEvent -FilterHashtable @{LogName='Microsoft-Windows-Windows Defender/Operational'; ID=1116} -MaxEvents 10

# Expected Event:
# Event ID: 1116 (Malware detected)
# Message: 
#   Threat Name: EICAR_Test_File
#   File: \\<FILE_SERVER>\file_transfer\NBS\Daily_MI_TEST_INFECTED_20250115.xlsx
#   Action: Quarantine
#   Status: Success

# Check quarantine location
Get-MpThreatDetection | Where-Object {$_.ThreatName -like "*EICAR*"}
```

**Or check Go Anywhere MFT virus scan workflow:**
1. Go Anywhere Console > Workflows > Recent Executions
2. Find: Virus_Scan_Incoming_Files
3. Expected status:

```
Workflow: Virus_Scan_Incoming_Files
Step 1: Detect File - SUCCESS
  File: Daily_MI_TEST_INFECTED_20250115.xlsx
Step 2: Virus Scan - THREAT DETECTED
  Scanner: Windows Defender / ClamAV
  Threat: EICAR_Test_File
  Action: Quarantine
Step 3: Quarantine File - SUCCESS
  Source: \\<FILE_SERVER>\file_transfer\NBS\
  Destination: \\<FILE_SERVER>\file_transfer\Quarantine\
Step 4: Send Alert - SUCCESS
Status: COMPLETED (Threat quarantined)
```

**Step 5: Verify File Quarantine**

```powershell
# Check if file was removed from landing zone
Test-Path "\\<FILE_SERVER>\file_transfer\NBS\$fileName"
# Expected: False (file removed/quarantined)

# Check quarantine location
$quarantinePath = "\\<FILE_SERVER>\file_transfer\Quarantine\"
Get-ChildItem $quarantinePath | Where-Object {$_.Name -like "*INFECTED*"}

# Expected Output:
# Name                                                    Length LastWriteTime
# ----                                                    ------ -------------
# Daily_MI_TEST_INFECTED_20250115.xlsx.quarantine        15234  1/15/2025 6:50:00 AM

# Check Windows Defender quarantine (if using Defender)
Get-MpThreat
```

**Step 6: Verify SolarWinds Alert**

**Expected SolarWinds Alert:**
```
🚨 Subject: VIRUS DETECTED - File Quarantined
Priority: CRITICAL
Body:
  Alert Type: Security - Virus Detected
  File: Daily_MI_TEST_INFECTED_20250115.xlsx
  Original Location: \\<FILE_SERVER>\file_transfer\NBS\
  Quarantine Location: \\<FILE_SERVER>\file_transfer\Quarantine\
  Threat Name: EICAR_Test_File
  Threat Type: Test Virus (Safe for testing)
  Scanner: Windows Defender / ClamAV
  Action Taken: File quarantined automatically
  Processing Status: BLOCKED
  Dependent Jobs: STOPPED (file not available for processing)
  Time: 2025-01-15 06:50:05
  Action Required:
    1. Verify file source (AWS)
    2. Investigate why infected file was sent
    3. Request clean file from sender
    4. Do NOT release from quarantine until verified clean
    5. Update sender security procedures
  Security Team Notified: Yes
```

**Step 7: Verify Control-M Processing Blocked**

```powershell
# Check Control-M console
# Job: P_MIS5_Transfer_WebSave_Sun_To_Fri should NOT process quarantined file

# Expected: Job runs but reports missing file
```

**Control-M Console:**
1. Navigate to **Monitoring > Job Status**
2. Find: P_MIS5_Transfer_WebSave_Sun_To_Fri
3. Expected status:

```
Job: P_MIS5_Transfer_WebSave_Sun_To_Fri
Status: FAILED or COMPLETED WITH WARNINGS
Message: Expected file not found: Daily_MI_TEST_INFECTED_20250115.xlsx
Reason: File quarantined due to virus detection
```

**Step 8: Create and Upload Clean File**

```powershell
# Create CLEAN version of the file (without EICAR)
$excel = New-Object -ComObject Excel.Application
$excel.Visible = $false
$workbook = $excel.Workbooks.Add()
$worksheet = $workbook.Worksheets.Item(1)

# Add test data (NO EICAR STRING)
$worksheet.Cells.Item(1,1) = "Date"
$worksheet.Cells.Item(1,2) = "Department"
$worksheet.Cells.Item(1,3) = "Revenue"
$worksheet.Cells.Item(2,1) = "2025-01-15"
$worksheet.Cells.Item(2,2) = "Retail"
$worksheet.Cells.Item(2,3) = "50000.00"

# Save CLEAN file
$cleanFileName = "Daily_MI_TEST_CLEAN_$(Get-Date -Format 'yyyyMMdd').xlsx"
$workbook.SaveAs("$(Get-Location)\$cleanFileName")
$workbook.Close()
$excel.Quit()

Write-Host "Clean file created: $cleanFileName"
```

**Upload clean file:**
```bash
# Remove infected file from AWS
aws s3 rm s3://<AWS_BUCKET>/outbound/$fileName

# Upload clean file
aws s3 cp $cleanFileName s3://<AWS_BUCKET>/outbound/

# Trigger transfer
aws lambda invoke \
  --function-name FileTransferToOnPremise \
  --payload "{\"fileName\":\"$cleanFileName\"}" \
  response.json
```

**Step 9: Verify Clean File Processing**

```powershell
# Wait for file transfer
Start-Sleep -Seconds 30

# Check file arrival
Test-Path "\\<FILE_SERVER>\file_transfer\NBS\$cleanFileName"
# Expected: True

# Verify virus scan passes
Start-Sleep -Seconds 10

# File should still be present (not quarantined)
Test-Path "\\<FILE_SERVER>\file_transfer\NBS\$cleanFileName"
# Expected: True

# Check Go Anywhere workflow
```

**Go Anywhere Workflow (Clean File):**
```
Workflow: Virus_Scan_Incoming_Files
Step 1: Detect File - SUCCESS
  File: Daily_MI_TEST_CLEAN_20250115.xlsx
Step 2: Virus Scan - CLEAN
  Scanner: Windows Defender / ClamAV
  Threat: None detected
  Result: PASSED
Step 3: Move to Staging - SUCCESS
  Destination: <STAGING_DRIVE>:\AgressoMIFeed\Staging\
Status: COMPLETED (File clean and ready for processing)
```

**Verify file in staging:**
```powershell
Test-Path "<STAGING_DRIVE>:\AgressoMIFeed\Staging\$cleanFileName"
# Expected: True
```

**Step 10: Verify SolarWinds Recovery Alert**

**Expected SolarWinds Alert:**
```
✅ Subject: Clean File Received - Processing Resumed
Priority: INFO
Body:
  Alert Type: File Processing Resumed
  File: Daily_MI_TEST_CLEAN_20250115.xlsx
  Location: <STAGING_DRIVE>:\AgressoMIFeed\Staging\
  Previous Status: Infected file quarantined
  Current Status: Clean file received and scanned
  Virus Scan Result: PASSED (No threats detected)
  Scanner: Windows Defender / ClamAV
  Previous Infected File: Daily_MI_TEST_INFECTED_20250115.xlsx (Quarantined)
  Original Failure Time: 2025-01-15 06:50:00
  Recovery Time: 2025-01-15 06:55:00
  Recovery Duration: 5 minutes
  Next Step: File ready for Control-M processing
  Time: 2025-01-15 06:55:10
```

---

#### Success Criteria

- [ ] Infected test file (with EICAR) created successfully
- [ ] File transferred from AWS to on-premise
- [ ] Antivirus software detected EICAR test virus immediately
- [ ] File automatically quarantined
- [ ] SolarWinds CRITICAL alert triggered within 1 minute
- [ ] File NOT available for Control-M processing
- [ ] Clean file created and uploaded
- [ ] Clean file passed virus scan
- [ ] Clean file moved to staging area
- [ ] SolarWinds recovery alert triggered
- [ ] **Total recovery time: < 5 minutes (RTO met)**

---

#### Rollback/Cleanup

```powershell
# IMPORTANT: Clean up quarantined files carefully

# Remove quarantined file (requires admin)
# Windows Defender:
Remove-MpThreat -ThreatID <ID> # Get ID from Get-MpThreat

# Or manually from quarantine folder:
Remove-Item "\\<FILE_SERVER>\file_transfer\Quarantine\*INFECTED*" -Force

# Remove clean test file
Remove-Item "\\<FILE_SERVER>\file_transfer\NBS\$cleanFileName" -Force -ErrorAction SilentlyContinue
Remove-Item "<STAGING_DRIVE>:\AgressoMIFeed\Staging\$cleanFileName" -Force -ErrorAction SilentlyContinue

# Remove from AWS
aws s3 rm s3://<AWS_BUCKET>/outbound/$cleanFileName

# Remove local test files
Remove-Item "EICAR_TEST.txt" -Force -ErrorAction SilentlyContinue
Remove-Item "*INFECTED*.xlsx" -Force -ErrorAction SilentlyContinue
Remove-Item "*CLEAN*.xlsx" -Force -ErrorAction SilentlyContinue

# Document results
```

---

#### Troubleshooting

**Issue: EICAR not detected by antivirus**
- Verify antivirus is active and up-to-date
- Check real-time protection is enabled
- Verify EICAR string is exactly correct (case-sensitive)
- Test with standalone EICAR.txt file first

**Issue: File not quarantined automatically**
- Check antivirus action configuration (should be set to Quarantine, not just Alert)
- Verify Go Anywhere virus scan workflow is configured
- Check folder permissions (antivirus needs access)

**Issue: Cannot create Excel file with EICAR**
- Use CSV method instead (simpler)
- Verify Excel is installed
- Check macro/security settings in Excel

**Issue: Clean file also quarantined**
- Verify EICAR string was completely removed
- Scan clean file manually before upload
- Check antivirus definition version

---

### TEST 5: MFT Agent/Platform Down

**Test ID**: OAT-FR-005
**Objective**: Verify failover and recovery when MFT agent server fails
**Duration**: 45 minutes
**RTO Target**: 5 minutes (for failover)

---

#### Prerequisites
- [ ] Two MFT agent servers operational (<MFT_AGENT_01> and <MFT_AGENT_02>)
- [ ] Go Anywhere Pro2Col agents installed on both servers
- [ ] Failover configuration verified
- [ ] Test file created (CIF or Deposits+Withdrawals)
- [ ] SolarWinds monitoring active
- [ ] Access to stop/start services on agent servers

---

#### Test Procedure

**Step 1: Verify Both Agents Operational**

```powershell
# Check Go Anywhere Agent service status on both servers

# On <MFT_AGENT_01>:
Get-Service -Name "GoAnywhereAgent" | Select-Object Name, Status, StartType

# Expected Output:
# Name              Status StartType
# ----              ------ ---------
# GoAnywhereAgent   Running Automatic

# On <MFT_AGENT_02>:
Get-Service -Name "GoAnywhereAgent" | Select-Object Name, Status, StartType

# Expected Output:
# Name              Status StartType
# ----              ------ ---------
# GoAnywhereAgent   Running Automatic
```

**Verify in Go Anywhere Console:**
1. Login to Go Anywhere web console
2. Navigate to **Agents > Agent Status**
3. Verify:
   ```
   Agent: <MFT_AGENT_01>
   Status: ONLINE
   Last Heartbeat: < 1 minute ago
   
   Agent: <MFT_AGENT_02>
   Status: ONLINE
   Last Heartbeat: < 1 minute ago
   ```

**Step 2: Create and Upload Test File**

```powershell
# Create test file
.\Generate-CIF-TestFile.ps1
# Output: CIF_TEST_20250115.xml
```

```bash
# Upload to AWS
aws s3 cp CIF_TEST_20250115.xml s3://<AWS_BUCKET>/outbound/

# Trigger transfer (should go to primary agent <MFT_AGENT_01>)
aws lambda invoke \
  --function-name FileTransferToOnPremise \
  --payload '{"fileName":"CIF_TEST_20250115.xml"}' \
  response.json
```

**Step 3: Verify Normal Transfer to Primary Agent**

```powershell
# Wait for transfer
Start-Sleep -Seconds 30

# Verify file received on primary
Invoke-Command -ComputerName <MFT_AGENT_01> -ScriptBlock {
    Test-Path "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml"
}
# Expected: True

# Check Go Anywhere logs
```

**Go Anywhere Console - Transfer Log:**
```
Time: 06:55:00
File: CIF_TEST_20250115.xml
Source: AWS_S3
Destination Agent: <MFT_AGENT_01>
Status: SUCCESS
Transfer Time: 2.1 seconds
```

**Step 4: Stop Primary MFT Agent (<MFT_AGENT_01>)**

```powershell
# On <MFT_AGENT_01> (or remotely with admin access):
Stop-Service -Name "GoAnywhereAgent" -Force

# Verify service stopped
Get-Service -Name "GoAnywhereAgent"

# Expected Output:
# Name              Status StartType
# ----              ------ ---------
# GoAnywhereAgent   Stopped Automatic

Write-Host "Primary MFT Agent (<MFT_AGENT_01>) stopped at $(Get-Date)"
```

**Alternative: Simulate server crash**
```powershell
# Disable network adapter (simulates network failure)
Disable-NetAdapter -Name "Ethernet" -Confirm:$false

# Or stop multiple related services
Stop-Service -Name "GoAnywhereAgent", "W3SVC" -Force
```

**Step 5: Monitor SolarWinds Detection**

**Expected SolarWinds Alert (within 2 minutes):**
```
🚨 Subject: MFT Agent Down - <MFT_AGENT_01>
Priority: CRITICAL
Body:
  Alert Type: Agent Failure
  Agent Server: <MFT_AGENT_01>
  Agent Status: OFFLINE / UNREACHABLE
  Last Heartbeat: 2025-01-15 06:55:30
  Service Status: Stopped
  Failover Agent: <MFT_AGENT_02>
  Failover Status: Activating
  Time Detected: 2025-01-15 06:56:45
  Downtime: 1 minute 15 seconds
  Action Required:
    1. Investigate <MFT_AGENT_01> service failure
    2. Verify automatic failover to <MFT_AGENT_02>
    3. Monitor file transfers on secondary agent
    4. Restore primary agent service
  Automatic Actions Triggered:
    - Failover to <MFT_AGENT_02> initiated
    - All incoming transfers redirected
    - On-call team notified
```

**Verify in SolarWinds:**
1. SolarWinds Console > Alerts > Active
2. Filter: Priority=Critical, Last 5 minutes
3. Verify alert present with correct details

**Step 6: Verify Automatic Failover**

**Go Anywhere Console:**
1. Navigate to **Agents > Agent Status**
2. Verify:
   ```
   Agent: <MFT_AGENT_01>
   Status: OFFLINE
   Last Heartbeat: 06:55:30 (2 minutes ago)
   Error: Heartbeat timeout
   
   Agent: <MFT_AGENT_02>
   Status: ONLINE (PRIMARY)
   Last Heartbeat: < 30 seconds ago
   Note: Promoted to primary due to <MFT_AGENT_01> failure
   ```

3. Navigate to **System > Configuration > Agent Groups**
4. Verify failover group shows:
   ```
   Agent Group: OnPremise_MFT_Agents
   Primary Agent: <MFT_AGENT_02> (Failover activated)
   Secondary Agent: <MFT_AGENT_01> (OFFLINE)
   Failover Mode: ACTIVE
   ```

**Step 7: Upload New Test File (Should Go to Secondary)**

```bash
# Create second test file
.\Generate-DepositsWithdrawals-TestFile.ps1
# Output: Deposits_Withdrawals_TEST_20250115.csv

# Upload to AWS
aws s3 cp Deposits_Withdrawals_TEST_20250115.csv s3://<AWS_BUCKET>/outbound/

# Trigger transfer
aws lambda invoke \
  --function-name FileTransferToOnPremise \
  --payload '{"fileName":"Deposits_Withdrawals_TEST_20250115.csv"}' \
  response.json

# Monitor CloudWatch
aws logs tail /aws/lambda/FileTransferToOnPremise --follow
# Expected: Transfer successful (automatically routed to <MFT_AGENT_02>)
```

**Step 8: Verify File Received by Secondary Agent**

```powershell
# Check file on secondary agent
Invoke-Command -ComputerName <MFT_AGENT_02> -ScriptBlock {
    Test-Path "\\<FILE_SERVER>\file_transfer\NBS\Deposits_Withdrawals_TEST_20250115.csv"
}
# Expected: True

# Verify timestamp (should be recent)
$fileInfo = Get-Item "\\<FILE_SERVER>\file_transfer\NBS\Deposits_Withdrawals_TEST_20250115.csv"
Write-Host "File received at: $($fileInfo.LastWriteTime)"
Write-Host "Received by: <MFT_AGENT_02> (Secondary/Failover agent)"
```

**Go Anywhere Console - Transfer Log:**
```
Time: 06:58:00
File: Deposits_Withdrawals_TEST_20250115.csv
Source: AWS_S3
Destination Agent: <MFT_AGENT_02> (Failover)
Status: SUCCESS
Transfer Time: 2.3 seconds
Note: Primary agent <MFT_AGENT_01> unavailable - failover successful
```

**Step 9: Restart Primary Agent (<MFT_AGENT_01>)**

```powershell
# On <MFT_AGENT_01>:
Start-Service -Name "GoAnywhereAgent"

# Verify service started
Get-Service -Name "GoAnywhereAgent"

# Expected Output:
# Name              Status StartType
# ----              ------ ---------
# GoAnywhereAgent   Running Automatic

Write-Host "Primary MFT Agent (<MFT_AGENT_01>) restarted at $(Get-Date)"

# Wait for agent to reconnect
Start-Sleep -Seconds 30
```

**If network was disabled:**
```powershell
# Re-enable network adapter
Enable-NetAdapter -Name "Ethernet"

# Verify connectivity
Test-NetConnection -ComputerName "<GOANYWHERE_PLATFORM>" -Port 443
# Expected: TcpTestSucceeded = True
```

**Step 10: Verify Agent Rejoins Cluster**

**Go Anywhere Console:**
1. Navigate to **Agents > Agent Status**
2. Wait 1-2 minutes for heartbeat
3. Verify:
   ```
   Agent: <MFT_AGENT_01>
   Status: ONLINE (Recovered)
   Last Heartbeat: < 30 seconds ago
   Note: Agent reconnected after downtime
   
   Agent: <MFT_AGENT_02>
   Status: ONLINE
   Last Heartbeat: < 30 seconds ago
   Note: Still serving as primary until manual failback
   ```

**Check Agent Group:**
```
Agent Group: OnPremise_MFT_Agents
Primary Agent: <MFT_AGENT_02> (Currently active)
Secondary Agent: <MFT_AGENT_01> (ONLINE - Ready for failback)
Failover Mode: ACTIVE (Manual failback required)
```

**Step 11: Perform Failback to Primary (Optional)**

**Option A: Manual Failback via Console**
1. Go Anywhere Console > **Agents > Agent Groups**
2. Select: OnPremise_MFT_Agents
3. Click: **"Failback to Primary"**
4. Confirm: Yes
5. Verify:
   ```
   Primary Agent: <MFT_AGENT_01> (Restored)
   Secondary Agent: <MFT_AGENT_02> (Standby)
   Failover Mode: NORMAL
   ```

**Option B: Let Auto-Failback Occur**
```
# If configured for auto-failback after X minutes:
# Wait for configured period (e.g., 10 minutes)
# System will automatically fail back to <MFT_AGENT_01>
```

**Step 12: Test Transfer After Failback**

```bash
# Create third test file
$fileName = "Daily_MI_TEST_$(Get-Date -Format 'yyyyMMdd').xlsx"
# (Create manually or use script)

# Upload to AWS
aws s3 cp $fileName s3://<AWS_BUCKET>/outbound/

# Trigger transfer
aws lambda invoke \
  --function-name FileTransferToOnPremise \
  --payload "{\"fileName\":\"$fileName\"}" \
  response.json
```

**Verify transfer goes to primary (<MFT_AGENT_01>):**
```powershell
Start-Sleep -Seconds 30

Test-Path "\\<FILE_SERVER>\file_transfer\NBS\$fileName"
# Expected: True
```

**Go Anywhere Console - Transfer Log:**
```
Time: 07:05:00
File: Daily_MI_TEST_20250115.xlsx
Source: AWS_S3
Destination Agent: <MFT_AGENT_01> (Primary - Restored)
Status: SUCCESS
Transfer Time: 2.2 seconds
Note: Normal operations resumed on primary agent
```

**Step 13: Verify SolarWinds Recovery Alert**

**Expected SolarWinds Alert:**
```
✅ Subject: MFT Agent Recovered - <MFT_AGENT_01>
Priority: INFO
Body:
  Alert Type: Agent Recovery
  Agent Server: <MFT_AGENT_01>
  Agent Status: ONLINE (Restored)
  Service Status: Running
  Heartbeat: Normal (< 30 seconds)
  Previous Status: OFFLINE
  Outage Start: 2025-01-15 06:55:00
  Recovery Time: 2025-01-15 07:02:00
  Total Downtime: 7 minutes
  Failover Performance:
    - Failover Activation: 1 minute 45 seconds (Within SLA)
    - Files Transferred During Outage: 1 (via <MFT_AGENT_02>)
    - Files Lost: 0
    - Failback Completed: 07:03:00
  Current Status:
    - Primary Agent: <MFT_AGENT_01> (Active)
    - Secondary Agent: <MFT_AGENT_02> (Standby)
    - Failover Mode: NORMAL
  Next Steps:
    - Review root cause of service failure
    - Update runbook if needed
    - Monitor for recurring issues
  Time: 2025-01-15 07:05:00
```

---

#### Success Criteria

- [ ] Both MFT agents initially operational
- [ ] Primary agent (<MFT_AGENT_01>) stopped/failed
- [ ] SolarWinds detected failure within 2 minutes
- [ ] Automatic failover to secondary agent (<MFT_AGENT_02>) activated
- [ ] **Failover time: < 5 minutes (RTO met)**
- [ ] New file successfully transferred via secondary agent
- [ ] File arrived at landing zone with correct integrity
- [ ] Primary agent successfully restarted
- [ ] Primary agent rejoined cluster
- [ ] Failback to primary agent completed (manual or automatic)
- [ ] Post-failback transfer successful via primary agent
- [ ] SolarWinds recovery alert triggered
- [ ] Zero files lost during failover
- [ ] **Total recovery time: < 10 minutes**

---

#### Rollback/Cleanup

```powershell
# Remove all test files
Remove-Item "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml" -Force -ErrorAction SilentlyContinue
Remove-Item "\\<FILE_SERVER>\file_transfer\NBS\Deposits_Withdrawals_TEST_20250115.csv" -Force -ErrorAction SilentlyContinue
Remove-Item "\\<FILE_SERVER>\file_transfer\NBS\Daily_MI_TEST_*.xlsx" -Force -ErrorAction SilentlyContinue

# Remove from AWS
aws s3 rm s3://<AWS_BUCKET>/outbound/CIF_TEST_20250115.xml
aws s3 rm s3://<AWS_BUCKET>/outbound/Deposits_Withdrawals_TEST_20250115.csv
aws s3 rm s3://<AWS_BUCKET>/outbound/ --recursive --exclude "*" --include "Daily_MI_TEST_*.xlsx"

# Verify both agents are running
Get-Service -Name "GoAnywhereAgent" -ComputerName <MFT_AGENT_01>
Get-Service -Name "GoAnywhereAgent" -ComputerName <MFT_AGENT_02>
# Expected: Both Running

# Verify agent group configuration reset to normal
# Go Anywhere Console > Agents > Agent Groups > Verify Primary = <MFT_AGENT_01>

# Document results
```

---

#### Troubleshooting

**Issue: Failover doesn't activate automatically**
- Verify agent group failover configuration in Go Anywhere
- Check heartbeat timeout settings (may be too long)
- Verify both agents are in same agent group
- Manually trigger failover from console

**Issue: Secondary agent unreachable**
- Check <MFT_AGENT_02> service status
- Verify network connectivity
- Check firewall rules
- Restart agent service

**Issue: Failback doesn't occur**
- Check if auto-failback is configured
- Manually trigger failback from console
- Verify primary agent fully recovered
- Check agent health status

**Issue: Files lost during failover**
- Check Go Anywhere retry queue
- Verify AWS S3 outbound folder for pending files
- Check CloudWatch logs for transfer errors
- Re-trigger failed transfers manually

---

### TEST 6: Internet/Network Outage

**Test ID**: OAT-FR-006
**Objective**: Verify handling when network connectivity between AWS and on-premise fails
**Duration**: 60 minutes
**RTO Target**: 30 minutes

---

#### Prerequisites
- [ ] Test file created
- [ ] Access to network/firewall to simulate outage
- [ ] VPN connection details
- [ ] AWS monitoring configured
- [ ] SolarWinds monitoring active
- [ ] Go Anywhere retry configuration documented

---

#### Test Procedure

**Step 1: Verify Normal Network Connectivity**

```powershell
# From on-premise network, test connectivity to AWS
Test-NetConnection -ComputerName <AWS_PUBLIC_IP> -Port 443

# Expected Output:
# ComputerName     : <AWS_PUBLIC_IP>
# RemoteAddress    : <AWS_PUBLIC_IP>
# TcpTestSucceeded : True

# Test VPN status (if applicable)
Get-VpnConnection

# Verify DNS resolution
Resolve-DnsName <AWS_ENDPOINT>
```

```bash
# From AWS, test connectivity to on-premise
# (Via Lambda function or EC2 instance)
nc -zv <MFT_AGENT_IP> 22
# Expected: Connection succeeded
```

**Step 2: Create and Stage Test File**

```powershell
.\Generate-CIF-TestFile.ps1
# Output: CIF_TEST_20250115.xml
```

```bash
# Upload to AWS S3
aws s3 cp CIF_TEST_20250115.xml s3://<AWS_BUCKET>/outbound/

# Verify upload
aws s3 ls s3://<AWS_BUCKET>/outbound/ | grep CIF_TEST
# Expected: File listed
```

**Step 3: Simulate Network Outage**

**Option A: Disable VPN Connection**
```powershell
# If using site-to-site VPN
# On VPN gateway or firewall:
# Navigate to VPN configuration and temporarily disable tunnel

# Or via command line (example for AWS VPN):
aws ec2 modify-vpn-connection \
  --vpn-connection-id <VPN_CONNECTION_ID> \
  --options TunnelOptions=[{OutsideIpAddress=<IP>,Phase1LifetimeSeconds=0}]
```

**Option B: Block Traffic at Firewall**
```powershell
# On on-premise firewall:
# Block all traffic from/to AWS IP ranges

New-NetFirewallRule -DisplayName "TEST_BLOCK_AWS_ALL" `
  -Direction Inbound `
  -Action Block `
  -RemoteAddress <AWS_IP_RANGE>

New-NetFirewallRule -DisplayName "TEST_BLOCK_AWS_ALL_OUT" `
  -Direction Outbound `
  -Action Block `
  -RemoteAddress <AWS_IP_RANGE>
```

**Option C: Disable Network Interface (Simulates ISP outage)**
```powershell
# On <MFT_AGENT_01> and <MFT_AGENT_02>:
Disable-NetAdapter -Name "Ethernet" -Confirm:$false

# Verify disabled
Get-NetAdapter | Where-Object {$_.Status -eq "Disabled"}
```

**Log the outage start time:**
```powershell
$outageStart = Get-Date
Write-Host "Network outage simulated at: $outageStart"
```

**Step 4: Attempt File Transfer from AWS**

```bash
# Trigger file transfer (will fail)
aws lambda invoke \
  --function-name FileTransferToOnPremise \
  --payload '{"fileName":"CIF_TEST_20250115.xml"}' \
  response.json

# Check response
cat response.json
# Expected: Error or timeout
```

**Monitor CloudWatch Logs:**
```bash
aws logs tail /aws/lambda/FileTransferToOnPremise --follow

# Expected Output:
# 07:10:00 - INFO: Starting file transfer for CIF_TEST_20250115.xml
# 07:10:05 - ERROR: Connection timeout to <MFT_AGENT_01>
# 07:10:05 - ERROR: Network unreachable
# 07:10:05 - RETRY: Scheduling retry attempt 1 of 5
# 07:10:35 - RETRY: Attempt 1 - Connection timeout
# 07:11:05 - RETRY: Attempt 2 - Connection timeout
# ...
# 07:15:05 - ERROR: All retry attempts failed
# 07:15:05 - INFO: File queued for later transmission
# 07:15:05 - INFO: File remains in S3 bucket: s3://<AWS_BUCKET>/outbound/
```

**Step 5: Verify File Queued in AWS**

```bash
# Check S3 bucket - file should still be present
aws s3 ls s3://<AWS_BUCKET>/outbound/ | grep CIF_TEST
# Expected: File still present

# Check SQS queue (if using queue for retry)
aws sqs get-queue-attributes \
  --queue-url <QUEUE_URL> \
  --attribute-names ApproximateNumberOfMessages

# Expected: Messages queued for retry
```

**Step 6: Verify On-Premise Detection**

```powershell
# Check Go Anywhere logs
# File should NOT have arrived
Test-Path "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml"
# Expected: False
```

**Go Anywhere Console:**
1. Navigate to **Logs > Transfer Logs**
2. Filter: Last 10 minutes, Status: Failed
3. Expected: No entries (transfer never reached on-premise)

**Step 7: Verify SolarWinds Alerts**

**Expected Alert 1: Network Connectivity Failure**
```
🚨 Subject: Network Connectivity Lost - AWS to On-Premise
Priority: CRITICAL
Body:
  Alert Type: Network Outage
  Source: AWS VPC <VPC_ID>
  Destination: On-Premise Network
  Connection Type: VPN / Direct Connect
  Status: DOWN
  Last Successful Heartbeat: 2025-01-15 07:09:45
  Outage Detected: 2025-01-15 07:10:15
  Affected Services:
    - File transfers from AWS to MFT agents
    - MFT agent heartbeats
    - All AWS → On-Premise communications
  Impact:
    - File transfers queued in AWS
    - MFT agents unreachable from AWS
    - Dependent Control-M jobs may be delayed
  Time: 2025-01-15 07:10:30
  Action Required:
    1. Investigate VPN/network connectivity
    2. Check ISP status
    3. Verify firewall rules
    4. Check on-premise network equipment
    5. Contact network team and AWS support if needed
```

**Expected Alert 2: MFT Agents Unreachable**
```
⚠️ Subject: MFT Agents Unreachable from AWS
Priority: HIGH
Body:
  Alert Type: Agent Connectivity Failure
  Agents Affected: <MFT_AGENT_01>, <MFT_AGENT_02>
  Status: UNREACHABLE from AWS
  Local Status: ONLINE (agents functional locally)
  Last Contact from AWS: 2025-01-15 07:09:45
  Time: 2025-01-15 07:11:00
  Note: Agents are operational but cannot be reached from AWS
  Root Cause: Network connectivity issue (see related alert)
```

**Expected Alert 3: File Transfer Failures**
```
⚠️ Subject: Multiple File Transfer Failures - AWS to MFT
Priority: HIGH
Body:
  Alert Type: File Transfer Failure (Multiple)
  Files Affected: 1 (CIF_TEST_20250115.xml)
  Error: Network timeout / Unreachable
  Retry Status: In Progress (5 attempts remaining)
  Files Queued: 1 (in AWS S3)
  Time: 2025-01-15 07:12:00
  Action: Will auto-retry when connectivity restored
```

**Step 8: Monitor Retry Attempts**

```bash
# Continue monitoring CloudWatch
aws logs tail /aws/lambda/FileTransferToOnPremise --follow

# Expected: Retry attempts every 5 minutes
# 07:15:00 - RETRY: Attempt 3 - Connection timeout
# 07:20:00 - RETRY: Attempt 4 - Connection timeout
# 07:25:00 - RETRY: Attempt 5 - Connection timeout
# 07:30:00 - ERROR: Maximum retries exceeded
# 07:30:00 - INFO: File will remain queued for manual intervention
```

**Check retry queue:**
```bash
# If using SQS for retry management
aws sqs receive-message \
  --queue-url <QUEUE_URL> \
  --max-number-of-messages 10

# Expected: Messages with file transfer details and retry count
```

**Step 9: Restore Network Connectivity**

**Log restoration start:**
```powershell
$restoreStart = Get-Date
Write-Host "Network restoration started at: $restoreStart"
```

**Option A: Re-enable VPN**
```powershell
# Re-enable VPN tunnel
# Via AWS console or CLI:
aws ec2 modify-vpn-connection \
  --vpn-connection-id <VPN_CONNECTION_ID> \
  --options TunnelOptions=[{OutsideIpAddress=<IP>,Phase1LifetimeSeconds=28800}]
```

**Option B: Remove Firewall Block**
```powershell
# Remove test firewall rules
Remove-NetFirewallRule -DisplayName "TEST_BLOCK_AWS_ALL"
Remove-NetFirewallRule -DisplayName "TEST_BLOCK_AWS_ALL_OUT"
```

**Option C: Re-enable Network Interface**
```powershell
# On <MFT_AGENT_01> and <MFT_AGENT_02>:
Enable-NetAdapter -Name "Ethernet"

# Verify enabled
Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
```

**Step 10: Verify Connectivity Restored**

```powershell
# Test connectivity from on-premise to AWS
Test-NetConnection -ComputerName <AWS_PUBLIC_IP> -Port 443

# Expected Output:
# TcpTestSucceeded : True

# Verify VPN status
Get-VpnConnection
# Expected: Connected
```

```bash
# Test from AWS to on-premise
nc -zv <MFT_AGENT_IP> 22
# Expected: Connection succeeded
```

**Log restoration complete:**
```powershell
$restoreEnd = Get-Date
$outageDuration = $restoreEnd - $outageStart
Write-Host "Network restored at: $restoreEnd"
Write-Host "Total outage duration: $($outageDuration.TotalMinutes) minutes"
```

**Step 11: Verify Automatic File Transfer Retry**

**Wait for next retry attempt (within 5 minutes):**
```bash
# Monitor CloudWatch logs
aws logs tail /aws/lambda/FileTransferToOnPremise --follow

# Expected Output:
# 07:35:00 - INFO: Network connectivity restored
# 07:35:00 - RETRY: Attempting queued file transfer
# 07:35:00 - INFO: Connecting to <MFT_AGENT_01>
# 07:35:02 - INFO: Connection successful
# 07:35:02 - INFO: Transferring CIF_TEST_20250115.xml
# 07:35:05 - INFO: Transfer successful (3.2 seconds)
# 07:35:05 - INFO: File removed from retry queue
```

**Or manually trigger retry:**
```bash
# Re-invoke Lambda function
aws lambda invoke \
  --function-name FileTransferToOnPremise \
  --payload '{"fileName":"CIF_TEST_20250115.xml","forceRetry":true}' \
  response.json

cat response.json
# Expected: {"status":"success","transferred":true}
```

**Step 12: Verify File Received**

```powershell
# Check file arrival
Test-Path "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml"
# Expected: True

# Verify timestamp (should be recent)
$fileInfo = Get-Item "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml"
Write-Host "File received at: $($fileInfo.LastWriteTime)"
Write-Host "Transfer latency: $(($fileInfo.LastWriteTime - $restoreEnd).TotalMinutes) minutes"
```

**Go Anywhere Console - Transfer Log:**
```
Time: 07:35:05
File: CIF_TEST_20250115.xml
Source: AWS_S3
Destination Agent: <MFT_AGENT_01>
Status: SUCCESS
Transfer Time: 3.2 seconds
Note: Successful after network restoration
```

**Step 13: Verify File Integrity**

```powershell
# Calculate MD5 checksum of received file
$receivedMD5 = Get-FileHash -Path "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml" -Algorithm MD5

# Compare with original (from AWS S3 ETag or local copy)
$originalMD5 = Get-FileHash -Path "CIF_TEST_20250115.xml" -Algorithm MD5

Write-Host "Original MD5:  $($originalMD5.Hash)"
Write-Host "Received MD5:  $($receivedMD5.Hash)"

if ($originalMD5.Hash -eq $receivedMD5.Hash) {
    Write-Host "✓ File integrity verified - MD5 checksums match"
} else {
    Write-Host "✗ WARNING: File corruption detected - MD5 mismatch"
}
```

**Step 14: Verify SolarWinds Recovery Alerts**

**Expected Alert 1: Network Connectivity Restored**
```
✅ Subject: Network Connectivity Restored - AWS to On-Premise
Priority: INFO
Body:
  Alert Type: Network Recovery
  Source: AWS VPC <VPC_ID>
  Destination: On-Premise Network
  Connection Type: VPN / Direct Connect
  Status: UP (Restored)
  Outage Start: 2025-01-15 07:10:00
  Restoration Time: 2025-01-15 07:33:00
  Total Outage Duration: 23 minutes
  Services Restored:
    - File transfers from AWS to MFT agents
    - MFT agent heartbeats
    - All AWS → On-Premise communications
  Queued File Transfers: 1 (Processing)
  Time: 2025-01-15 07:33:15
```

**Expected Alert 2: MFT Agents Reachable**
```
✅ Subject: MFT Agents Reachable from AWS
Priority: INFO
Body:
  Alert Type: Agent Connectivity Restored
  Agents Restored: <MFT_AGENT_01>, <MFT_AGENT_02>
  Status: ONLINE and REACHABLE from AWS
  Heartbeat: Normal (< 30 seconds)
  Time: 2025-01-15 07:33:30
```

**Expected Alert 3: File Transfer Success**
```
✅ Subject: Queued File Transfers Completed
Priority: INFO
Body:
  Alert Type: File Transfer Success (Recovery)
  Files Successfully Transferred: 1
    - CIF_TEST_20250115.xml (SUCCESS)
  Transfer Time: 3.2 seconds
  File Integrity: Verified (MD5 match)
  Original Transfer Attempt: 2025-01-15 07:10:00
  Successful Transfer: 2025-01-15 07:35:05
  Total Delay: 25 minutes
  Status: All queued files processed
  Time: 2025-01-15 07:35:10
```

---

#### Success Criteria

- [ ] Network connectivity initially verified
- [ ] Test file uploaded to AWS S3
- [ ] Network outage simulated (VPN/firewall/network disabled)
- [ ] File transfer attempts failed with timeout errors
- [ ] File remained queued in AWS S3 (not lost)
- [ ] SolarWinds detected network outage within 2 minutes
- [ ] Multiple retry attempts logged in CloudWatch
- [ ] Network connectivity manually restored
- [ ] Automatic retry successful after restoration
- [ ] File received at on-premise landing zone
- [ ] File integrity verified (MD5 checksum match)
- [ ] SolarWinds recovery alerts triggered
- [ ] Zero files lost during outage
- [ ] **Total recovery time after restoration: < 30 minutes (RTO met)**
- [ ] **File transfer delay: ~25 minutes (within acceptable range)**

---

#### Rollback/Cleanup

```powershell
# Remove test file from all locations
Remove-Item "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml" -Force

# Remove from AWS S3
aws s3 rm s3://<AWS_BUCKET>/outbound/CIF_TEST_20250115.xml

# Verify network connectivity fully restored
Test-NetConnection -ComputerName <AWS_PUBLIC_IP> -Port 443
# Expected: TcpTestSucceeded = True

# Verify VPN status
Get-VpnConnection
# Expected: Connected

# Verify firewall rules removed
Get-NetFirewallRule -DisplayName "TEST_BLOCK_AWS*"
# Expected: No results

# Verify all network adapters enabled
Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
# Expected: All adapters listed

# Clear retry queues
aws sqs purge-queue --queue-url <QUEUE_URL>

# Verify MFT agents online
# Go Anywhere Console > Agents > Verify both agents ONLINE

# Document results including:
# - Outage duration
# - Retry attempts count
# - Recovery time
# - File integrity verification results
```

---

#### Troubleshooting

**Issue: Network doesn't restore properly**
- Reboot network equipment (router, firewall)
- Check VPN configuration
- Verify firewall rules completely removed
- Check with ISP if using external connectivity

**Issue: File transfer doesn't auto-retry**
- Manually trigger Lambda function
- Check SQS queue for pending messages
- Verify retry logic in Lambda function code
- Check CloudWatch Events / EventBridge rules

**Issue: File integrity check fails**
- Compare file sizes
- Re-transfer file
- Check for proxy/firewall interference
- Verify encryption/decryption if applicable

**Issue: Multiple files queued**
- Process queue in order
- Monitor S3 bucket for pending files
- Manually trigger transfers for each file
- Document any files that require special handling

---

### TEST 7: File Recovery from Backup

**Test ID**: OAT-FR-007
**Objective**: Measure backup recovery time and verify file integrity after recovery
**Duration**: 60 minutes
**RTO Target**: 30 minutes

---

#### Prerequisites
- [ ] Test file created and processed through complete workflow
- [ ] Backup procedures documented
- [ ] Access to AWS S3 backup buckets
- [ ] Access to on-premise backup locations
- [ ] Access to Go Anywhere Cloud backup
- [ ] BMC Control-M access to reprocess jobs

---

#### Test Procedure

**Step 1: Create and Process Test File Through Complete Workflow**

```powershell
# Create test file
.\Generate-CIF-TestFile.ps1
# Output: CIF_TEST_20250115.xml

# Calculate and log original MD5
$originalMD5 = Get-FileHash -Path "CIF_TEST_20250115.xml" -Algorithm MD5
Write-Host "Original MD5: $($originalMD5.Hash)"

# Store MD5 for later verification
$originalMD5.Hash | Out-File "CIF_TEST_20250115.xml.md5"
```

```bash
# Upload to AWS S3
aws s3 cp CIF_TEST_20250115.xml s3://<AWS_BUCKET>/outbound/

# Also backup to S3 backup bucket
aws s3 cp CIF_TEST_20250115.xml s3://<AWS_BUCKET>/backup/

# Verify both copies
aws s3 ls s3://<AWS_BUCKET>/outbound/ | grep CIF_TEST
aws s3 ls s3://<AWS_BUCKET>/backup/ | grep CIF_TEST
```

**Trigger transfer and processing:**
```bash
aws lambda invoke \
  --function-name FileTransferToOnPremise \
  --payload '{"fileName":"CIF_TEST_20250115.xml"}' \
  response.json
```

**Wait for complete processing:**
```powershell
# Monitor file through all stages:
# 1. Landing zone
Start-Sleep -Seconds 30
Test-Path "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml"
# Expected: True

# 2. Staging (after P_MIS5_Agresso_MI_Staging_Copy)
Start-Sleep -Seconds 60
Test-Path "<STAGING_DRIVE>:\AgressoMIFeed\Staging\CIF_TEST_20250115.xml"
# Expected: True

# 3. Processed (after P_Websave_Agresso_Post_Cloud creates webtrans.dat)
Start-Sleep -Seconds 120
Test-Path "<STAGING_DRIVE>:\AgressoMIFeed\Output\webtrans.dat"
# Expected: True

# 4. Uploaded to Go Anywhere Cloud (after P_Websave_Agresso_SFTP_Send)
# Verify in Go Anywhere Cloud console
```

**Backup on-premise files:**
```powershell
# Create on-premise backup directory (if doesn't exist)
$backupDir = "\\<FILE_SERVER>\file_transfer\Backup\$(Get-Date -Format 'yyyyMMdd')"
New-Item -ItemType Directory -Path $backupDir -Force

# Backup landing zone file
Copy-Item "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml" `
          "$backupDir\CIF_TEST_20250115.xml"

# Backup staging file
Copy-Item "<STAGING_DRIVE>:\AgressoMIFeed\Staging\CIF_TEST_20250115.xml" `
          "$backupDir\CIF_TEST_20250115_STAGING.xml"

# Backup output file
Copy-Item "<STAGING_DRIVE>:\AgressoMIFeed\Output\webtrans.dat" `
          "$backupDir\webtrans.dat"

Write-Host "On-premise backup completed: $backupDir"
```

**Step 2: Document All File Locations**

```powershell
# Create location inventory
$fileInventory = @"
FILE RECOVERY TEST - File Locations for CIF_TEST_20250115.xml
================================================================
Test Date: $(Get-Date)
Original MD5: $($originalMD5.Hash)

LOCATIONS:
1. AWS S3 Outbound:  s3://<AWS_BUCKET>/outbound/CIF_TEST_20250115.xml
2. AWS S3 Backup:    s3://<AWS_BUCKET>/backup/CIF_TEST_20250115.xml
3. Landing Zone:     \\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml
4. Staging Area:     <STAGING_DRIVE>:\AgressoMIFeed\Staging\CIF_TEST_20250115.xml
5. On-Prem Backup:   $backupDir\CIF_TEST_20250115.xml
6. Output File:      <STAGING_DRIVE>:\AgressoMIFeed\Output\webtrans.dat
7. On-Prem Backup:   $backupDir\webtrans.dat
8. Go Anywhere Cloud: webtrans.dat (uploaded via SFTP)
"@

$fileInventory | Out-File "FILE_LOCATIONS_LOG.txt"
Write-Host $fileInventory
```

**Step 3: Delete Files from All Locations (Simulate Loss)**

**⚠️ WARNING: This simulates a disaster scenario - files will be deleted**

```powershell
# Start recovery timer
$recoveryStartTime = Get-Date
Write-Host "FILE DELETION STARTED: $recoveryStartTime"
Write-Host "Simulating file loss/corruption scenario..."

# Delete from landing zone
Remove-Item "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml" -Force -ErrorAction SilentlyContinue
Write-Host "✓ Deleted from landing zone"

# Delete from staging
Remove-Item "<STAGING_DRIVE>:\AgressoMIFeed\Staging\CIF_TEST_20250115.xml" -Force -ErrorAction SilentlyContinue
Write-Host "✓ Deleted from staging"

# Delete output file
Remove-Item "<STAGING_DRIVE>:\AgressoMIFeed\Output\webtrans.dat" -Force -ErrorAction SilentlyContinue
Write-Host "✓ Deleted output file"

# Verify deletion
$filesRemaining = @(
    Test-Path "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml"
    Test-Path "<STAGING_DRIVE>:\AgressoMIFeed\Staging\CIF_TEST_20250115.xml"
    Test-Path "<STAGING_DRIVE>:\AgressoMIFeed\Output\webtrans.dat"
)

if ($filesRemaining -contains $true) {
    Write-Host "⚠️ WARNING: Some files not deleted successfully"
} else {
    Write-Host "✓ All operational files deleted - recovery test can begin"
}
```

**Note about Go Anywhere Cloud:** 
Don't delete from cloud yet - will simulate manual deletion if needed

**Step 4: Recovery Option 1 - Restore from AWS S3 Backup**

**⏱️ Start Timer for AWS S3 Recovery:**
```powershell
$awsRecoveryStart = Get-Date
Write-Host "`n=== AWS S3 BACKUP RECOVERY STARTED: $awsRecoveryStart ==="
```

**Download from S3 backup bucket:**
```bash
# Check if file exists in backup
aws s3 ls s3://<AWS_BUCKET>/backup/ | grep CIF_TEST

# Download to local/temp location first
aws s3 cp s3://<AWS_BUCKET>/backup/CIF_TEST_20250115.xml ./CIF_TEST_20250115_RECOVERED.xml

# Verify download
ls -lh CIF_TEST_20250115_RECOVERED.xml
```

**Verify integrity:**
```powershell
# Calculate MD5 of recovered file
$recoveredMD5 = Get-FileHash -Path "CIF_TEST_20250115_RECOVERED.xml" -Algorithm MD5
$expectedMD5 = Get-Content "CIF_TEST_20250115.xml.md5"

Write-Host "Expected MD5:  $expectedMD5"
Write-Host "Recovered MD5: $($recoveredMD5.Hash)"

if ($recoveredMD5.Hash -eq $expectedMD5) {
    Write-Host "✓ File integrity verified - MD5 match"
} else {
    Write-Host "✗ ERROR: File corruption detected - MD5 mismatch"
    exit 1
}
```

**Restore to landing zone:**
```powershell
# Copy recovered file to landing zone
Copy-Item "CIF_TEST_20250115_RECOVERED.xml" `
          "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml"

# Verify
Test-Path "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml"
# Expected: True

$awsRecoveryEnd = Get-Date
$awsRecoveryDuration = $awsRecoveryEnd - $awsRecoveryStart
Write-Host "=== AWS S3 RECOVERY COMPLETED in $($awsRecoveryDuration.TotalMinutes) minutes ==="
```

**Step 5: Recovery Option 2 - Restore from On-Premise Backup**

**⏱️ Start Timer for On-Premise Recovery:**
```powershell
$onpremRecoveryStart = Get-Date
Write-Host "`n=== ON-PREMISE BACKUP RECOVERY STARTED: $onpremRecoveryStart ==="

# Check backup exists
$backupFile = "$backupDir\CIF_TEST_20250115.xml"
Test-Path $backupFile
# Expected: True

# Calculate MD5 of backup
$backupMD5 = Get-FileHash -Path $backupFile -Algorithm MD5
$expectedMD5 = Get-Content "CIF_TEST_20250115.xml.md5"

Write-Host "Expected MD5: $expectedMD5"
Write-Host "Backup MD5:   $($backupMD5.Hash)"

if ($backupMD5.Hash -eq $expectedMD5) {
    Write-Host "✓ Backup integrity verified"
} else {
    Write-Host "✗ ERROR: Backup file corrupted"
}

# Restore from backup to landing zone
Copy-Item $backupFile "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml"

# Restore staging file
Copy-Item "$backupDir\CIF_TEST_20250115_STAGING.xml" `
          "<STAGING_DRIVE>:\AgressoMIFeed\Staging\CIF_TEST_20250115.xml"

$onpremRecoveryEnd = Get-Date
$onpremRecoveryDuration = $onpremRecoveryEnd - $onpremRecoveryStart
Write-Host "=== ON-PREMISE RECOVERY COMPLETED in $($onpremRecoveryDuration.TotalMinutes) minutes ==="
```

**Step 6: Recovery Option 3 - Restore from Go Anywhere Cloud**

**⏱️ Start Timer for Go Anywhere Cloud Recovery:**
```powershell
$cloudRecoveryStart = Get-Date
Write-Host "`n=== GO ANYWHERE CLOUD RECOVERY STARTED: $cloudRecoveryStart ==="
```

**Via Go Anywhere Cloud Console:**
1. Login to Go Anywhere Cloud (RevX hosted)
2. Navigate to **Files > Archived Files** or **Backup**
3. Search for: `webtrans.dat` or `CIF_TEST_20250115.xml`
4. Select file and click **Download** or **Restore**
5. Save to local location

**Or via SFTP/API (if available):**
```bash
# Connect to Go Anywhere Cloud via SFTP
sftp <USERNAME>@<GOANYWHERE_CLOUD_HOST>

# Navigate to backup/archive folder
cd /backup

# List files
ls -lh | grep TEST

# Download file
get webtrans.dat webtrans_RECOVERED.dat

# Exit SFTP
bye
```

**Verify and restore:**
```powershell
# Copy recovered file to output location
Copy-Item "webtrans_RECOVERED.dat" "<STAGING_DRIVE>:\AgressoMIFeed\Output\webtrans.dat"

$cloudRecoveryEnd = Get-Date
$cloudRecoveryDuration = $cloudRecoveryEnd - $cloudRecoveryStart
Write-Host "=== GO ANYWHERE CLOUD RECOVERY COMPLETED in $($cloudRecoveryDuration.TotalMinutes) minutes ==="
```

**Step 7: Reprocess Through Control-M**

```powershell
Write-Host "`n=== CONTROL-M REPROCESSING STARTED ==="
$reprocessStart = Get-Date
```

**Access BMC Control-M Console:**
1. Login to Control-M
2. Navigate to **Monitoring > Job Status**
3. Locate jobs that processed the file:
   - P_MIS5_Transfer_WebSave_Sun_To_Fri
   - P_MIS5_Agresso_MI_Staging_Copy
   - P_COPY_WEBSAVE_FILES_TEMP
   - P_Websave_Agresso_Post_Cloud
   - P_Websave_Agresso_SFTP_Send

**Option A: Rerun Entire Workflow**
1. Select: P_MIS5_Transfer_WebSave_Sun_To_Fri
2. Right-click > **Rerun**
3. Confirm: Yes
4. Monitor execution

**Option B: Rerun from Specific Step**
1. If only need to regenerate webtrans.dat:
2. Select: P_Websave_Agresso_Post_Cloud
3. Right-click > **Force Run**
4. Confirm: Yes

**Monitor job execution:**
```
Job: P_MIS5_Transfer_WebSave_Sun_To_Fri
Status: RUNNING → SUCCESS
↓
Job: P_MIS5_Agresso_MI_Staging_Copy
Status: RUNNING → SUCCESS
↓
Job: P_COPY_WEBSAVE_FILES_TEMP
Status: RUNNING → SUCCESS
↓
Job: P_Websave_Agresso_Post_Cloud
Status: RUNNING → SUCCESS
Output: webtrans.dat recreated
↓
Job: P_Websave_Agresso_SFTP_Send
Status: RUNNING → SUCCESS
File uploaded to Go Anywhere Cloud
```

**Step 8: Verify Complete Recovery**

```powershell
# Verify all files restored
$verificationResults = @{
    "Landing Zone" = Test-Path "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml"
    "Staging" = Test-Path "<STAGING_DRIVE>:\AgressoMIFeed\Staging\CIF_TEST_20250115.xml"
    "Output File" = Test-Path "<STAGING_DRIVE>:\AgressoMIFeed\Output\webtrans.dat"
}

Write-Host "`n=== VERIFICATION RESULTS ==="
foreach ($location in $verificationResults.Keys) {
    $status = if ($verificationResults[$location]) { "✓ PRESENT" } else { "✗ MISSING" }
    Write-Host "$location : $status"
}
```

**Verify file integrity for all restored files:**
```powershell
$expectedMD5 = Get-Content "CIF_TEST_20250115.xml.md5"

# Check landing zone file
$landingMD5 = Get-FileHash -Path "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml" -Algorithm MD5
Write-Host "`nLanding Zone File:"
Write-Host "  Expected: $expectedMD5"
Write-Host "  Actual:   $($landingMD5.Hash)"
Write-Host "  Match:    $(if ($landingMD5.Hash -eq $expectedMD5) {'✓ YES'} else {'✗ NO'})"

# Check staging file
$stagingMD5 = Get-FileHash -Path "<STAGING_DRIVE>:\AgressoMIFeed\Staging\CIF_TEST_20250115.xml" -Algorithm MD5
Write-Host "`nStaging File:"
Write-Host "  Expected: $expectedMD5"
Write-Host "  Actual:   $($stagingMD5.Hash)"
Write-Host "  Match:    $(if ($stagingMD5.Hash -eq $expectedMD5) {'✓ YES'} else {'✗ NO'})"
```

**Verify Go Anywhere Cloud:**
1. Go Anywhere Cloud Console > **Files > Received Files**
2. Filter: Today, Filename: webtrans
3. Verify: webtrans.dat present with recent timestamp

**Step 9: Calculate Total Recovery Time**

```powershell
$recoveryEndTime = Get-Date
$totalRecoveryDuration = $recoveryEndTime - $recoveryStartTime

Write-Host "`n============================================"
Write-Host "RECOVERY TIME ANALYSIS"
Write-Host "============================================"
Write-Host "File Deletion Started:     $recoveryStartTime"
Write-Host "Recovery Completed:        $recoveryEndTime"
Write-Host "Total Recovery Duration:   $($totalRecoveryDuration.TotalMinutes) minutes"
Write-Host ""
Write-Host "Breakdown by Recovery Method:"
Write-Host "  AWS S3 Recovery:         $($awsRecoveryDuration.TotalMinutes) minutes"
Write-Host "  On-Premise Recovery:     $($onpremRecoveryDuration.TotalMinutes) minutes"
Write-Host "  Go Anywhere Cloud:       $($cloudRecoveryDuration.TotalMinutes) minutes"
Write-Host ""
Write-Host "RTO Target:                30 minutes"
Write-Host "RTO Status:                $(if ($totalRecoveryDuration.TotalMinutes -le 30) {'✓ MET'} else {'✗ EXCEEDED'})"
Write-Host "============================================"

# Save results to log
$recoveryReport = @"
============================================
FILE RECOVERY TEST REPORT
============================================
Test Date: $(Get-Date)
File: CIF_TEST_20250115.xml

RECOVERY TIMELINE:
------------------
Deletion Started:          $recoveryStartTime
AWS S3 Recovery:           $($awsRecoveryDuration.TotalMinutes) min
On-Premise Recovery:       $($onpremRecoveryDuration.TotalMinutes) min
Go Anywhere Cloud Recovery: $($cloudRecoveryDuration.TotalMinutes) min
Control-M Reprocessing:    $(($recoveryEndTime - $reprocessStart).TotalMinutes) min
Total Duration:            $($totalRecoveryDuration.TotalMinutes) min

RTO Target:                30 minutes
RTO Status:                $(if ($totalRecoveryDuration.TotalMinutes -le 30) {'✓ MET'} else {'✗ EXCEEDED'})

INTEGRITY VERIFICATION:
----------------------
Original MD5:              $expectedMD5
Landing Zone MD5:          $($landingMD5.Hash) $(if ($landingMD5.Hash -eq $expectedMD5) {'✓'} else {'✗'})
Staging MD5:               $($stagingMD5.Hash) $(if ($stagingMD5.Hash -eq $expectedMD5) {'✓'} else {'✗'})

RECOVERY SOURCES TESTED:
-----------------------
✓ AWS S3 Backup Bucket
✓ On-Premise Backup Directory
✓ Go Anywhere Cloud Archive

RECOMMENDATION:
--------------
Fastest Recovery Method:   $(if ($awsRecoveryDuration -lt $onpremRecoveryDuration -and $awsRecoveryDuration -lt $cloudRecoveryDuration) {'AWS S3'} elseif ($onpremRecoveryDuration -lt $cloudRecoveryDuration) {'On-Premise'} else {'Go Anywhere Cloud'})
Recovery Method Time:      $(($awsRecoveryDuration, $onpremRecoveryDuration, $cloudRecoveryDuration | Measure-Object -Minimum).Minimum) minutes

============================================
"@

$recoveryReport | Out-File "RECOVERY_TEST_REPORT_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
Write-Host "`nReport saved to: RECOVERY_TEST_REPORT_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
```

**Step 10: Verify SolarWinds Monitoring**

**Expected Alerts During Recovery:**
```
⚠️ Alert 1: File Missing Detection
Subject: Expected File Not Found - Processing Failed
Time: Shortly after deletion
Priority: HIGH

✅ Alert 2: File Restored Notification
Subject: File Recovery Completed
Time: After restoration from backup
Priority: INFO

✅ Alert 3: Processing Resumed
Subject: Control-M Jobs Completed Successfully
Time: After reprocessing
Priority: INFO
```

---

#### Success Criteria

- [ ] Test file created and processed through complete workflow
- [ ] File backed up to multiple locations (AWS S3, on-premise, Go Anywhere Cloud)
- [ ] All operational copies deleted successfully (simulating loss)
- [ ] **AWS S3 backup recovery completed in < 10 minutes**
- [ ] **On-premise backup recovery completed in < 5 minutes**
- [ ] **Go Anywhere Cloud recovery completed in < 15 minutes**
- [ ] All recovered files verified with MD5 checksum (integrity confirmed)
- [ ] Control-M jobs rerun successfully
- [ ] All workflow stages completed (landing zone → staging → output → cloud)
- [ ] SolarWinds alerts appropriate for each stage
- [ ] **Total recovery time: < 30 minutes (RTO met)**
- [ ] Fastest recovery method identified and documented

---

#### Rollback/Cleanup

```powershell
# Remove all test files
Remove-Item "\\<FILE_SERVER>\file_transfer\NBS\CIF_TEST_20250115.xml" -Force -ErrorAction SilentlyContinue
Remove-Item "<STAGING_DRIVE>:\AgressoMIFeed\Staging\CIF_TEST_20250115.xml" -Force -ErrorAction SilentlyContinue
Remove-Item "<STAGING_DRIVE>:\AgressoMIFeed\Output\webtrans.dat" -Force -ErrorAction SilentlyContinue

# Remove backup files
Remove-Item "$backupDir\*" -Force -ErrorAction SilentlyContinue
Remove-Item $backupDir -Force -ErrorAction SilentlyContinue

# Remove from AWS S3
aws s3 rm s3://<AWS_BUCKET>/outbound/CIF_TEST_20250115.xml
aws s3 rm s3://<AWS_BUCKET>/backup/CIF_TEST_20250115.xml

# Remove from Go Anywhere Cloud (via console)
# Login > Files > Delete webtrans.dat (test file)

# Remove local test files
Remove-Item "CIF_TEST_20250115*.xml" -Force -ErrorAction SilentlyContinue
Remove-Item "webtrans*.dat" -Force -ErrorAction SilentlyContinue
Remove-Item "*.md5" -Force -ErrorAction SilentlyContinue
Remove-Item "FILE_LOCATIONS_LOG.txt" -Force -ErrorAction SilentlyContinue

# Archive recovery report
Move-Item "RECOVERY_TEST_REPORT_*.txt" "\\<FILE_SERVER>\Test_Reports\" -Force

Write-Host "`nCleanup completed. Recovery test report archived."
```

---

#### Troubleshooting

**Issue: AWS S3 recovery slow**
- Check internet bandwidth
- Use AWS CLI with increased concurrency: `--cli-connect-timeout 60`
- Consider using AWS DataSync or Transfer Family for large files

**Issue: On-premise backup not found**
- Verify backup schedule and retention policy
- Check backup directory permissions
- Verify backup job completed successfully

**Issue: Go Anywhere Cloud file not available**
- Check retention policy (files may be archived/deleted)
- Verify backup was enabled for this workflow
- Contact RevX support if needed

**Issue: Control-M reprocessing fails**
- Verify all input files are restored
- Check job dependencies
- Manually trigger each job in sequence
- Review Control-M job logs for specific errors

**Issue: File integrity check fails after recovery**
- Compare file sizes
- Check for partial downloads
- Re-download/restore from different backup source
- Verify backup wasn't corrupted before test

---

## Verification Procedures

### General Verification Checklist

After each test, verify:

1. **File Transfer Verification:**
   - [ ] File arrived at expected location
   - [ ] File size matches source
   - [ ] File timestamp is recent (within test window)
   - [ ] MD5/SHA checksum matches original

2. **System Status Verification:**
   - [ ] Go Anywhere MFT platform operational
   - [ ] Both MFT agents (<MFT_AGENT_01> and <MFT_AGENT_02>) online
   - [ ] BMC Control-M jobs in expected state
   - [ ] Network connectivity confirmed

3. **Alert Verification:**
   - [ ] SolarWinds alert triggered (for failures)
   - [ ] Alert contains correct details
   - [ ] Alert timestamp appropriate
   - [ ] Recovery alert sent (for successes)

4. **Logging Verification:**
   - [ ] AWS CloudWatch logs captured events
   - [ ] Go Anywhere workflow logs present
   - [ ] Control-M job logs available
   - [ ] SolarWinds event history recorded

### Log File Locations

**AWS:**
- CloudWatch Logs: `/aws/lambda/FileTransferToOnPremise`
- S3 Access Logs: `s3://<AWS_BUCKET>/logs/`

**Go Anywhere MFT:**
- Workflow Logs: `<GOANYWHERE_INSTALL>\logs\workflow_execution.log`
- Transfer Logs: Via Go Anywhere web console
- Agent Logs: `<GOANYWHERE_INSTALL>\logs\agent_<AGENT_NAME>.log`

**On-Premise:**
- BMC Control-M Logs: `<CONTROLM_INSTALL>\logs\`
- Windows Event Logs: Application, System, Security
- Antivirus Logs: Varies by product (Windows Defender: Event Viewer)

**SolarWinds:**
- Alert History: SolarWinds Console > Alerts > History
- Event Logs: SolarWinds Console > Events

---

## Rollback Procedures

### General Rollback Steps

1. **Stop Active Tests:**
   ```powershell
   # If test is in progress, document current state
   $testState = "Test stopped at $(Get-Date)"
   $testState | Out-File "TEST_STATE_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
   ```

2. **Restore Services:**
   ```powershell
   # Restart any stopped services
   Start-Service -Name "GoAnywhereAgent"
   
   # Re-enable network adapters
   Enable-NetAdapter -Name "Ethernet"
   
   # Remove test firewall rules
   Get-NetFirewallRule -DisplayName "TEST_*" | Remove-NetFirewallRule
   ```

3. **Clean Up Test Files:**
   ```powershell
   # Remove from all locations
   Remove-Item "\\<FILE_SERVER>\file_transfer\NBS\*TEST*.xml" -Force
   Remove-Item "<STAGING_DRIVE>:\AgressoMIFeed\Staging\*TEST*.csv" -Force
   Remove-Item "<STAGING_DRIVE>:\AgressoMIFeed\Output\webtrans_TEST.dat" -Force
   
   # Remove from AWS
   aws s3 rm s3://<AWS_BUCKET>/outbound/ --recursive --exclude "*" --include "*TEST*"
   ```

4. **Reset Control-M Jobs:**
   ```
   # Via Control-M Console:
   # 1. Navigate to failed jobs
   # 2. Right-click > Set to OK or Mark Completed
   # 3. Reset dependencies if needed
   ```

5. **Clear Alerts:**
   ```
   # In SolarWinds Console:
   # 1. Navigate to Active Alerts
   # 2. Acknowledge test-related alerts
   # 3. Add notes: "Test alert - can be ignored"
   ```

6. **Verify System State:**
   ```powershell
   # Verify all systems operational
   Get-Service -Name "GoAnywhereAgent" | Where-Object {$_.Status -ne "Running"}
   Test-NetConnection -ComputerName <AWS_PUBLIC_IP> -Port 443
   # Expected: All services running, connectivity successful
   ```

---

## Success Criteria

### Overall Test Success Criteria

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Recovery Time Objective (RTO)** | < 30 minutes | Time from failure detection to full recovery |
| **Recovery Point Objective (RPO)** | < 24 hours | Maximum acceptable data loss (for backups) |
| **Failover Time** | < 5 minutes | Time for MFT agent failover |
| **Alert Response Time** | < 2 minutes | SolarWinds alert generation time |
| **File Integrity** | 100% | MD5 checksum match rate |
| **Zero Data Loss** | 100% | All files recovered or queued |

### Individual Test Criteria

| Test | RTO Target | Success Criteria |
|------|------------|------------------|
| **TEST 1: Transfer Failure** | 15 min | File detected, queued, manually recovered |
| **TEST 2: Dependent File Failure** | 20 min | Second file recovered, both processed |
| **TEST 3: Decryption Failure** | 10 min | Re-encrypted file processed successfully |
| **TEST 4: Virus Scan Failure** | 5 min | Infected file quarantined, clean file accepted |
| **TEST 5: Agent Down** | 5 min | Automatic failover, zero files lost |
| **TEST 6: Network Outage** | 30 min | Files queued, auto-retry after restoration |
| **TEST 7: Backup Recovery** | 30 min | All files restored with integrity verified |

---

## Test Execution Timeline

### Recommended Test Schedule

**Day 1: Preparation and Setup (4 hours)**
- 09:00-10:00: Environment verification and access confirmation
- 10:00-11:00: Create all test files and documentation
- 11:00-12:00: Verify monitoring and alerting
- 12:00-13:00: Lunch break
- 13:00-15:00: Conduct dry run of TEST 1 and TEST 2
- 15:00-17:00: Review results, adjust procedures

**Day 2: Execute Tests 1-4 (8 hours)**
- 09:00-09:30: TEST 1 - Transfer Failure (30 min)
- 09:30-10:15: TEST 2 - Dependent File Failure (45 min)
- 10:15-10:45: TEST 3 - Decryption Failure (30 min)
- 10:45-11:00: Break
- 11:00-11:30: TEST 4 - Virus Scanning Failure (30 min)
- 11:30-13:00: Lunch break and result documentation
- 13:00-17:00: Review results, troubleshoot issues, document findings

**Day 3: Execute Tests 5-7 (8 hours)**
- 09:00-09:45: TEST 5 - Agent Down (45 min)
- 09:45-11:00: TEST 6 - Network Outage (60 min + wait time)
- 11:00-12:00: TEST 7 - Backup Recovery (60 min)
- 12:00-13:00: Lunch break
- 13:00-15:00: Retest any failed scenarios
- 15:00-17:00: Final documentation and report generation

**Total Testing Time: ~20 hours over 3 days**

---

## Test Results Documentation

### Test Results Template

```
============================================
OAT FILE RECOVERY TEST RESULTS
============================================
Test ID: OAT-FR-XXX
Test Name: [Test Name]
Test Date: [Date]
Tester: [Name]
Environment: [Production/UAT]

TEST EXECUTION:
--------------
Start Time: [Time]
End Time: [Time]
Duration: [Minutes]

RESULTS:
--------
Status: [PASS / FAIL / PARTIAL]
RTO Target: [X minutes]
Actual RTO: [X minutes]
RTO Met: [YES / NO]

FILES TESTED:
------------
- [Filename 1]: [Result]
- [Filename 2]: [Result]

ALERTS GENERATED:
----------------
- [Alert 1]: [Time] - [Details]
- [Alert 2]: [Time] - [Details]

ISSUES ENCOUNTERED:
------------------
[List any issues or unexpected behaviors]

REMEDIATION ACTIONS:
-------------------
[Steps taken to resolve issues]

VERIFICATION:
------------
File Integrity: [VERIFIED / FAILED]
MD5 Checksum: [Match / Mismatch]
System Status: [Operational / Degraded]

RECOMMENDATIONS:
---------------
[Any recommendations for process improvement]

ATTACHMENTS:
-----------
- Screenshots: [Location]
- Log files: [Location]
- Error messages: [Location]

SIGN-OFF:
--------
Tester: [Name] [Date]
Reviewer: [Name] [Date]
============================================
```

---

## Appendix

### A. Contact Information

| Role | Contact | Phone | Email |
|------|---------|-------|-------|
| AWS Platform Team Lead | [Name] | [Phone] | [Email] |
| MFT Team Lead | [Name] | [Phone] | [Email] |
| On-Premise Infrastructure Lead | [Name] | [Phone] | [Email] |
| BMC Control-M Admin | [Name] | [Phone] | [Email] |
| Network Operations | [Name] | [Phone] | [Email] |
| Security Team | [Name] | [Phone] | [Email] |
| SolarWinds Admin | [Name] | [Phone] | [Email] |

### B. Escalation Procedures

**Level 1 (0-15 minutes):**
- Tester investigates and attempts resolution
- Consult runbooks and documentation

**Level 2 (15-30 minutes):**
- Escalate to team lead
- Engage relevant support team (AWS, MFT, On-Premise)

**Level 3 (30-60 minutes):**
- Escalate to management
- Consider engaging vendor support (Go Anywhere/RevX, BMC, AWS)

**Level 4 (> 60 minutes):**
- Activate disaster recovery procedures
- Engage business continuity team
- Communicate with stakeholders

### C. Reference Documentation

- Go Anywhere MFT Administration Guide
- BMC Control-M Documentation
- AWS Lambda and S3 Best Practices
- SolarWinds Monitoring Configuration
- Network Architecture Diagrams
- File Transfer Workflow Diagrams
- Backup and Recovery Procedures
- Security and Compliance Guidelines

### D. Tools and Scripts

**PowerShell Scripts:**
- `Generate-CIF-TestFile.ps1` - Creates CIF test file
- `Generate-DepositsWithdrawals-TestFile.ps1` - Creates transaction test file
- `Verify-FileIntegrity.ps1` - MD5 checksum verification
- `Cleanup-TestFiles.ps1` - Removes all test files

**Bash/AWS CLI Scripts:**
- `upload-to-s3.sh` - Uploads files to AWS S3
- `trigger-lambda.sh` - Invokes file transfer Lambda
- `check-cloudwatch-logs.sh` - Retrieves CloudWatch logs

**Available in:** `\\<FILE_SERVER>\Scripts\OAT_FileRecovery\`

---

## Document Control

**Version History:**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-01-15 | [Author] | Initial document creation |

**Review Schedule:**
- Next Review: [Date + 3 months]
- Review Owner: [Name/Role]

**Distribution List:**
- AWS Platform Team
- MFT Team
- On-Premise Infrastructure Team
- Control-M Administrators
- QA/Testing Team
- Project Management

---

**END OF DOCUMENT**







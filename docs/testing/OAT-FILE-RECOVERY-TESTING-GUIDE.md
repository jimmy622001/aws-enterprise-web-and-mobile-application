# OAT File Recovery Testing Guide
## Comprehensive Testing Strategy: AWS to On-Premise File Transfer

---

## 📋 Document Overview

**Purpose:** This document outlines the complete file recovery testing strategy for the AWS Banking Application to On-Premise file transfer process, covering testing on both AWS side and On-Premise side.

**Scope:** Operational Acceptance Testing (OAT) for file recovery from loss or corruption within Parity and MFT solutions.

**Primary Test Files:**
- **Customer Information Feed (CIF)** - Priority 1
- **Deposits + Withdrawals files** - Priority 1
- Additional files of each type (.xls, .html, .csv) to ensure coverage

**Reference Document:** TS1 OAT - Failover and Recovery Testing details v0.1.docx

---

## 🏗️ Architecture Overview

```
┌───────────────────────────────────────────────────────────────────┐
│                      AWS BANKING APPLICATION                       │
│                           (SOURCE SYSTEM)                          │
│                                                                    │
│  ┌──────────────────┐         ┌──────────────────┐              │
│  │  Banking Apps    │ ──────> │  S3 Landing      │              │
│  │  (Daily Jobs)    │         │  Buckets         │              │
│  └──────────────────┘         └──────────────────┘              │
│                                        │                          │
│                                        ▼                          │
│                         ┌──────────────────────────┐             │
│                         │  Anti-Malware Scanning   │             │
│                         │  (Lambda Functions)      │             │
│                         └──────────────────────────┘             │
│                                        │                          │
│                                        ▼                          │
│                         ┌──────────────────────────┐             │
│                         │  AWS Transfer Family     │             │
│                         │  (SFTP Endpoint)         │             │
│                         └──────────────────────────┘             │
└────────────────────────────────┬──────────────────────────────────┘
                                 │
                                 │ VPN / Direct Connect
                                 │
                                 ▼
┌───────────────────────────────────────────────────────────────────┐
│                    GO ANYWHERE MFT PLATFORM                        │
│              (FILE TRANSFER ORCHESTRATION LAYER)                   │
│                                                                    │
│  ┌──────────────────────────────────────────────────────────────┐│
│  │              SolarWinds Monitoring & Alerting                 ││
│  │  • File transfer status monitoring                            ││
│  │  • Failure detection & notifications                          ││
│  │  • Performance metrics & SLA tracking                         ││
│  └──────────────────────────────────────────────────────────────┘│
│                                                                    │
│  ┌──────────────────┐         ┌──────────────────┐              │
│  │  MFT Workflows   │ ──────> │  Error Handling  │              │
│  │  • Encryption    │         │  • Retry Logic   │              │
│  │  • Validation    │         │  • DLQ Management│              │
│  └──────────────────┘         └──────────────────┘              │
└────────────────────────────────┬──────────────────────────────────┘
                                 │
                                 │ VPN / Direct Connect
                                 │
                                 ▼
┌───────────────────────────────────────────────────────────────────┐
│                    ON-PREMISE FILE SERVERS                         │
│                        (DESTINATION SYSTEM)                        │
│                                                                    │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │              Pro2Col MFT Agent Servers (x2)                 │  │
│  │                                                             │  │
│  │  Server 1: PREM-MFT-01        Server 2: PREM-MFT-02       │  │
│  │  • Go Anywhere Agent          • Go Anywhere Agent          │  │
│  │  • File reception             • Failover / Load Balancing  │  │
│  │  • Initial validation         • Initial validation         │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                 │                                  │
│                                 ▼                                  │
│                  ┌──────────────────────────────┐                │
│                  │  File Landing Zone           │                │
│                  │  \\<FILE_SERVER>\file_transfer\NBS│                │
│                  └──────────────────────────────┘                │
│                                 │                                  │
│                                 ▼                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │              BMC Control-M Processing Jobs                  │  │
│  │                                                             │  │
│  │  Job 1: P_MIS5_Transfer_WebSave_Sun_To_Fri                │  │
│  │         • Initial file download and placement              │  │
│  │                                                             │  │
│  │  Job 2: P_MIS5_Agresso_MI_Staging_Copy                    │  │
│  │         • Copy to <STAGING_DRIVE>:\AgressoMIFeed\Staging                 │  │
│  │                                                             │  │
│  │  Job 3: P_COPY_WEBSAVE_FILES_TEMP                         │  │
│  │         • File preparation for reformatting                │  │
│  │                                                             │  │
│  │  Job 4: P_Websave_Agresso_Post_Cloud                      │  │
│  │         • Reformat to webtrans.dat (fixed-width)           │  │
│  │                                                             │  │
│  │  Job 5: P_Websave_Agresso_SFTP_Send                       │  │
│  │         • SFTP upload to Go Anywhere Cloud                 │  │
│  └────────────────────────────────────────────────────────────┘  │
└────────────────────────────────┬──────────────────────────────────┘
                                 │
                                 │ SFTP
                                 │
                                 ▼
┌───────────────────────────────────────────────────────────────────┐
│                    GO ANYWHERE CLOUD STORAGE                       │
│                      (INTERMEDIATE STORAGE)                        │
│                                                                    │
│  • SolarWinds monitoring active                                   │
│  • File retention (30 days)                                       │
│  • Access control (Agresso only)                                  │
└────────────────────────────────┬──────────────────────────────────┘
                                 │
                                 │ SFTP
                                 │
                                 ▼
┌───────────────────────────────────────────────────────────────────┐
│                      UNIT4 AGRESSO CLOUD                           │
│                       (FINAL DESTINATION)                          │
│                                                                    │
│  Gateway: <AGRESSO_SFTP_HOST>                              │
│  Path: \\S-UKSBW-APPP06\uk_wbs_prod$\Data Import                 │
└───────────────────────────────────────────────────────────────────┘
```

---

## 📁 Key Files for Testing

### Priority 1 Files (Primary Focus)

| File Name Pattern | Type | Description | Daily Volume | Critical? |
|-------------------|------|-------------|--------------|-----------|
| **CIF_Customer_Info_YYYYMMDD.csv** | CSV | Customer Information Feed | ~50 MB | ✅ YES |
| **Deposits_YYYYMMDD.xlsx** | XLSX | Daily deposits transactions | ~30 MB | ✅ YES |
| **Withdrawals_YYYYMMDD.xlsx** | XLSX | Daily withdrawals transactions | ~25 MB | ✅ YES |

### Secondary Files (Coverage Testing)

| File Name Pattern | Type | Description | Purpose |
|-------------------|------|-------------|---------|
| **Daily_MI_YYYYMMDD.xlsx** | XLSX | Daily Management Information | Test .xlsx format |
| **DD.MM.YY_TEST1_MI.xlsx** | XLSX | TEST1-specific MI data | Test .xlsx format |
| **Transaction_Report_YYYYMMDD.html** | HTML | Transaction summary report | Test .html format |
| **Account_Balances_YYYYMMDD.csv** | CSV | Account balance extract | Test .csv format |

---

## 🎯 PART A: Testing on AWS Side (Before Sending Files)

### Who Performs These Tests?
**Team:** AWS Platform Team / Cloud Engineering Team  
**Access Required:** 
- AWS Console access (S3, Lambda, CloudWatch)
- AWS CLI / SDK access
- VPN access to AWS environment

### Where Are Tests Performed?
**Primary Location:** AWS Cloud Infrastructure  
**Services Used:**
- Amazon S3 (file storage)
- AWS Lambda (anti-malware, validation)
- AWS Transfer Family (SFTP endpoint)
- Amazon CloudWatch (monitoring & alerts)
- AWS Backup / S3 Versioning (backup & recovery)

---

### Test Group AWS-1: File Generation & Availability

#### AWS-TEST-001: Daily File Generation Validation
**Objective:** Verify banking application generates all required files daily

**Test Steps:**
1. Check S3 landing bucket at scheduled time (e.g., 06:00 AM daily)
2. Verify presence of all expected files:
   - `CIF_Customer_Info_20250115.csv`
   - `Deposits_20250115.xlsx`
   - `Withdrawals_20250115.xlsx`
   - `Daily_MI_20250115.xlsx`
3. Verify file naming convention matches pattern
4. Verify file timestamps are within expected window (±5 minutes of schedule)

**Success Criteria:**
- ✅ All files present in S3 landing bucket
- ✅ File names match naming convention
- ✅ Timestamps within acceptable range

**Monitoring:**
```bash
# AWS CLI command to list files
aws s3 ls s3://banking-app-landing-bucket/daily-feeds/2025/01/15/

# Expected output:
# 2025-01-15 06:02:15   52428800 CIF_Customer_Info_20250115.csv
# 2025-01-15 06:03:22   31457280 Deposits_20250115.xlsx
# 2025-01-15 06:04:18   26214400 Withdrawals_20250115.xlsx
```

**Failure Scenario:** Missing file - go to AWS-TEST-015 (Recovery from Backup)

---

#### AWS-TEST-002: File Completeness Check
**Objective:** Ensure files are not empty and contain expected data structure

**Test Steps:**
1. Use Lambda function to check file size > 0 bytes
2. For CSV files: verify header row present
3. For XLSX files: verify sheet count and column count
4. Check file is not corrupted (able to parse first 10 rows)

**Success Criteria:**
- ✅ File size > 1 KB (not empty)
- ✅ File structure validated (headers, sheets)
- ✅ First 10 rows parse successfully

**Monitoring:**
```python
# Lambda function pseudocode
import boto3
import pandas as pd

def validate_file(bucket, key):
    s3 = boto3.client('s3')
    obj = s3.get_object(Bucket=bucket, Key=key)
    
    # Check size
    size = obj['ContentLength']
    if size < 1024:  # Less than 1KB
        raise ValueError(f"File too small: {size} bytes")
    
    # Parse first 10 rows
    if key.endswith('.csv'):
        df = pd.read_csv(obj['Body'], nrows=10)
    elif key.endswith('.xlsx'):
        df = pd.read_excel(obj['Body'], nrows=10)
    
    print(f"✅ File valid: {len(df)} rows parsed")
```

**Failure Scenario:** Empty or corrupted file - go to AWS-TEST-015 (Recovery from Backup)

---

### Test Group AWS-2: Anti-Malware Scanning

#### AWS-TEST-003: Clean File Scanning
**Objective:** Verify clean files pass anti-malware scan and continue to transfer

**Test Steps:**
1. Upload a clean test file to S3 landing bucket
2. Lambda anti-malware function automatically triggered
3. Verify scan completes successfully
4. Verify file remains in landing bucket (not quarantined)
5. Verify file tagged with metadata: `scan-status: clean`

**Success Criteria:**
- ✅ Scan completes within 10 seconds
- ✅ File marked as "clean"
- ✅ File available for transfer

**Monitoring:**
```bash
# Check CloudWatch Logs for Lambda AV function
aws logs tail /aws/lambda/antimalware-scanner --follow

# Expected log output:
# [INFO] Scanning file: CIF_Customer_Info_20250115.csv
# [INFO] File size: 50 MB
# [INFO] Scan result: CLEAN
# [INFO] Scan duration: 4.2 seconds
# [INFO] File tagged: scan-status=clean, scan-timestamp=2025-01-15T06:05:22Z
```

---

#### AWS-TEST-004: Malware Detection (EICAR Test)
**Objective:** Verify infected files are detected and quarantined

**Test Steps:**
1. Upload EICAR test file to S3 landing bucket
   ```
   X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*
   ```
2. Lambda AV function triggered automatically
3. Verify file detected as infected
4. Verify file moved to quarantine bucket: `s3://banking-app-quarantine/`
5. Verify SNS alert sent to operations team

**Success Criteria:**
- ✅ EICAR file detected as malware
- ✅ File quarantined (moved to quarantine bucket)
- ✅ Original file removed from landing bucket
- ✅ SNS alert received within 30 seconds

**Monitoring:**
```bash
# Check quarantine bucket
aws s3 ls s3://banking-app-quarantine/2025/01/15/

# Expected output:
# 2025-01-15 06:10:33   68 EICAR_TEST_FILE.txt

# Check SNS alert delivery
aws sns list-subscriptions-by-topic --topic-arn arn:aws:sns:eu-west-1:123456789012:malware-alerts

# Expected email alert:
# Subject: 🚨 MALWARE DETECTED - File Quarantined
# Body: File: EICAR_TEST_FILE.txt
#       Status: INFECTED
#       Action: Quarantined
#       Location: s3://banking-app-quarantine/2025/01/15/EICAR_TEST_FILE.txt
```

**Failure Scenario:** Malware not detected - CRITICAL SECURITY ISSUE - escalate immediately

---

### Test Group AWS-3: File Integrity & Validation

#### AWS-TEST-005: MD5 Checksum Calculation
**Objective:** Ensure file integrity tracked with checksums

**Test Steps:**
1. Lambda function calculates MD5 checksum for each file
2. Checksum stored as S3 object metadata
3. Verify checksum matches manual calculation

**Success Criteria:**
- ✅ MD5 checksum calculated and stored
- ✅ Checksum accessible via S3 metadata

**Monitoring:**
```bash
# Get S3 object metadata
aws s3api head-object \
  --bucket banking-app-landing-bucket \
  --key daily-feeds/2025/01/15/CIF_Customer_Info_20250115.csv

# Expected output includes:
# "Metadata": {
#     "md5-checksum": "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",
#     "scan-status": "clean",
#     "file-size": "52428800",
#     "generated-timestamp": "2025-01-15T06:02:15Z"
# }
```

---

### Test Group AWS-4: File Transfer to Go Anywhere MFT

#### AWS-TEST-006: MFT Connection Establishment
**Objective:** Verify AWS can establish connection to Go Anywhere MFT platform

**Test Steps:**
1. AWS Transfer Family SFTP endpoint attempts connection to Go Anywhere
2. Verify SSH key authentication succeeds
3. Verify connection established within 5 seconds

**Success Criteria:**
- ✅ Connection established successfully
- ✅ Authentication passes
- ✅ Connection latency < 100ms

**Monitoring:**
```bash
# Check AWS Transfer Family logs
aws transfer list-executions \
  --server-id s-1234567890abcdef \
  --max-results 10

# Expected log:
# ExecutionId: exec-abc123
# Status: COMPLETED
# Duration: 3.2 seconds
```

**Failure Scenario:** Connection timeout - go to AWS-TEST-016 (Network Failure Recovery)

---

#### AWS-TEST-007: File Upload to MFT
**Objective:** Verify files uploaded successfully to Go Anywhere MFT

**Test Steps:**
1. Initiate file transfer via AWS Transfer Family
2. Monitor upload progress
3. Verify file arrives in Go Anywhere MFT landing zone
4. Verify file size matches source

**Success Criteria:**
- ✅ File uploaded successfully
- ✅ File size matches (no corruption)
- ✅ Upload completes within SLA (e.g., < 2 minutes for 50MB file)

**Monitoring:**
```bash
# Monitor CloudWatch Metrics
aws cloudwatch get-metric-statistics \
  --namespace AWS/Transfer \
  --metric-name BytesTransferred \
  --dimensions Name=ServerId,Value=s-1234567890abcdef \
  --start-time 2025-01-15T06:00:00Z \
  --end-time 2025-01-15T06:10:00Z \
  --period 60 \
  --statistics Sum

# Expected: 52428800 bytes transferred
```

**Failure Scenario:** Upload fails - go to AWS-TEST-017 (Upload Retry Logic)

---

### Test Group AWS-5: Error Handling & Recovery (AWS Side)

#### AWS-TEST-015: Recovery from Backup (Missing File)
**Objective:** Verify quick recovery of missing files from S3 backup/versioning

**Test Scenario:** Banking application failed to generate `CIF_Customer_Info_20250115.csv`

**Test Steps:**
1. Check if file missing from landing bucket
2. Access S3 versioning to retrieve previous day's file structure
3. Restore from backup (e.g., from previous day or from AWS Backup vault)
4. Manually trigger file generation job if needed
5. Verify file recovered and available for transfer

**Success Criteria:**
- ✅ Missing file detected within 30 minutes
- ✅ File recovered from backup within 15 minutes
- ✅ File validated (checksum, structure)
- ✅ File available for transfer

**Recovery Commands:**
```bash
# Check S3 versioning
aws s3api list-object-versions \
  --bucket banking-app-landing-bucket \
  --prefix daily-feeds/2025/01/15/CIF_Customer_Info_20250115.csv

# Restore previous version
aws s3api copy-object \
  --bucket banking-app-landing-bucket \
  --copy-source banking-app-landing-bucket/daily-feeds/2025/01/14/CIF_Customer_Info_20250114.csv \
  --key daily-feeds/2025/01/15/CIF_Customer_Info_20250115.csv

# Or restore from AWS Backup
aws backup start-restore-job \
  --recovery-point-arn arn:aws:backup:eu-west-1:123456789012:recovery-point:abcd-1234 \
  --metadata file=CIF_Customer_Info_20250115.csv
```

**SLA Target:** File recovered and transfer resumed within 30 minutes

---

#### AWS-TEST-016: Network Failure Recovery
**Objective:** Verify AWS handles network failures gracefully

**Test Scenario:** VPN connection to Go Anywhere MFT goes down during file transfer

**Test Steps:**
1. Simulate VPN failure (disconnect VPN tunnel)
2. Observe AWS Transfer Family behavior
3. Verify transfer paused (not failed)
4. Restore VPN connection
5. Verify transfer resumes automatically

**Success Criteria:**
- ✅ Transfer pauses (not aborted)
- ✅ CloudWatch alarm triggered
- ✅ Transfer resumes within 2 minutes of VPN restoration
- ✅ File integrity maintained (checksum matches)

**Monitoring:**
```bash
# Check VPN tunnel status
aws ec2 describe-vpn-connections --vpn-connection-ids vpn-12345678

# Monitor Transfer Family execution
aws transfer describe-execution \
  --server-id s-1234567890abcdef \
  --execution-id exec-abc123

# Expected status progression:
# Status: IN_PROGRESS → EXCEPTION → IN_PROGRESS → COMPLETED
```

---

#### AWS-TEST-017: Upload Retry Logic
**Objective:** Verify failed uploads retry automatically

**Test Scenario:** File upload to Go Anywhere fails due to temporary network issue

**Test Steps:**
1. Simulate network interruption during upload (50% complete)
2. Verify AWS Transfer Family retries upload
3. Verify exponential backoff: 1 min, 2 min, 4 min
4. Verify upload succeeds on retry

**Success Criteria:**
- ✅ Failed upload triggers automatic retry
- ✅ Retry count ≤ 3 attempts
- ✅ Backoff timing as expected
- ✅ Upload completes successfully

**Monitoring:**
```bash
# Check CloudWatch Logs for retry attempts
aws logs filter-log-events \
  --log-group-name /aws/transfer/s-1234567890abcdef \
  --filter-pattern "retry"

# Expected log output:
# [INFO] Upload failed: CIF_Customer_Info_20250115.csv
# [INFO] Retry attempt 1/3 in 60 seconds
# [INFO] Upload resumed: CIF_Customer_Info_20250115.csv
# [INFO] Upload completed: CIF_Customer_Info_20250115.csv
```

---

### AWS Testing Summary

| Test ID | Test Name | Criticality | Expected Duration |
|---------|-----------|-------------|-------------------|
| AWS-TEST-001 | File generation validation | 🔴 HIGH | 5 min |
| AWS-TEST-002 | File completeness check | 🔴 HIGH | 5 min |
| AWS-TEST-003 | Clean file scanning | 🟡 MEDIUM | 10 min |
| AWS-TEST-004 | Malware detection | 🔴 HIGH | 10 min |
| AWS-TEST-005 | MD5 checksum calculation | 🟡 MEDIUM | 5 min |
| AWS-TEST-006 | MFT connection | 🔴 HIGH | 5 min |
| AWS-TEST-007 | File upload to MFT | 🔴 HIGH | 10 min |
| AWS-TEST-015 | Recovery from backup | 🔴 HIGH | 30 min |
| AWS-TEST-016 | Network failure recovery | 🟡 MEDIUM | 30 min |
| AWS-TEST-017 | Upload retry logic | 🟡 MEDIUM | 15 min |

**Total AWS Testing Duration:** ~2 hours

---

## 🎯 PART B: Testing on On-Premise Side (After Receiving Files)

### Who Performs These Tests?
**Team:** On-Premise Infrastructure Team / BMC Control-M Administrators  
**Access Required:**
- RDP access to on-premise servers (PREM-MFT-01, PREM-MFT-02)
- Access to Go Anywhere Agent management console
- BMC Control-M console access
- Windows File Server access (\\<FILE_SERVER>\file_transfer\NBS)
- Active Directory / Domain Admin access (for permissions)

### Where Are Tests Performed?

#### Option 1: Pro2Col MFT Agent Servers
**Server 1: PREM-MFT-01**
- Hostname: `PREM-MFT-01.domain.local`
- IP: `10.10.10.51`
- Role: Primary MFT agent (Go Anywhere Pro2Col Agent installed)
- OS: Windows Server 2019/2022
- Function: Receives files from AWS via Go Anywhere MFT

**Server 2: PREM-MFT-02**
- Hostname: `PREM-MFT-02.domain.local`
- IP: `10.10.10.52`
- Role: Secondary MFT agent / Failover (Go Anywhere Pro2Col Agent installed)
- OS: Windows Server 2019/2022
- Function: Failover for PREM-MFT-01, load balancing

#### Option 2: File Landing Zone
**Location:** `\\<FILE_SERVER>\file_transfer\NBS`
- Type: Windows File Share
- Access: BMC Control-M service account, MFT agents
- Function: Initial file landing location after MFT transfer

#### Option 3: Staging Area
**Location:** `<STAGING_DRIVE>:\AgressoMIFeed\Staging`
- Type: Local disk on Control-M server
- Function: Temporary storage during file processing

#### Option 4: Go Anywhere Cloud Storage
**Location:** Go Anywhere Cloud (SaaS)
- URL: `https://goanywhere.cloud/`
- Function: Final storage before transfer to Agresso
- Monitoring: SolarWinds

---

### Test Group PREM-1: File Reception on MFT Agents

#### PREM-TEST-001: File Reception on PREM-MFT-01
**Objective:** Verify files arrive successfully on primary MFT agent server

**Where to Test:** PREM-MFT-01 server

**Test Steps:**
1. RDP into PREM-MFT-01 server
2. Open Go Anywhere Agent console
3. Monitor file reception from AWS
4. Verify file arrives in agent's incoming directory (e.g., `C:\GoAnywhere\Incoming\`)
5. Verify file metadata (size, timestamp, checksum)

**Success Criteria:**
- ✅ File received within 5 minutes of AWS upload
- ✅ File size matches source (52,428,800 bytes)
- ✅ No corruption (checksum validated)

**Monitoring Commands:**
```powershell
# RDP to PREM-MFT-01
mstsc /v:PREM-MFT-01.domain.local

# Check Go Anywhere Agent logs
Get-Content "C:\GoAnywhere\Logs\agent.log" -Tail 50

# Expected log output:
# [2025-01-15 06:15:22] INFO: File received: CIF_Customer_Info_20250115.csv
# [2025-01-15 06:15:23] INFO: Size: 52428800 bytes
# [2025-01-15 06:15:24] INFO: Checksum validated: a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
# [2025-01-15 06:15:25] INFO: File moved to: \\<FILE_SERVER>\file_transfer\NBS\

# Verify file in landing zone
Test-Path "\\<FILE_SERVER>\file_transfer\NBS\CIF_Customer_Info_20250115.csv"
# Output: True

# Check file size
(Get-Item "\\<FILE_SERVER>\file_transfer\NBS\CIF_Customer_Info_20250115.csv").Length
# Output: 52428800
```

**Failure Scenario:** File not received - go to PREM-TEST-020 (MFT Agent Down Recovery)

---

#### PREM-TEST-002: Failover to PREM-MFT-02
**Objective:** Verify failover to secondary MFT agent if primary fails

**Where to Test:** PREM-MFT-01 (simulate failure) → PREM-MFT-02 (failover target)

**Test Scenario:** PREM-MFT-01 goes down, files should route to PREM-MFT-02

**Test Steps:**
1. Stop Go Anywhere Agent service on PREM-MFT-01:
   ```powershell
   Stop-Service -Name "GoAnywhereAgent"
   ```
2. Trigger file transfer from AWS
3. Verify Go Anywhere MFT detects PREM-MFT-01 unavailable
4. Verify file routes to PREM-MFT-02 automatically
5. Verify file arrives successfully on PREM-MFT-02
6. Restart PREM-MFT-01 agent

**Success Criteria:**
- ✅ MFT detects primary agent down within 30 seconds
- ✅ File routes to secondary agent automatically
- ✅ File arrives on PREM-MFT-02 within 2 minutes
- ✅ SolarWinds alert sent (primary agent down)

**Monitoring:**
```powershell
# On PREM-MFT-02, check logs
Get-Content "C:\GoAnywhere\Logs\agent.log" -Tail 50

# Expected log:
# [2025-01-15 06:20:10] WARN: Primary agent (PREM-MFT-01) unreachable
# [2025-01-15 06:20:11] INFO: Failover activated
# [2025-01-15 06:20:45] INFO: File received: CIF_Customer_Info_20250115.csv
# [2025-01-15 06:20:46] INFO: Size: 52428800 bytes
```

**SolarWinds Alert Expected:**
```
⚠️ Subject: MFT Agent Down - PREM-MFT-01
Body:
  Server: PREM-MFT-01.domain.local
  Status: UNREACHABLE
  Failover Status: ACTIVATED
  Active Server: PREM-MFT-02.domain.local
  Action: Investigate PREM-MFT-01 service
  Time: 2025-01-15 06:20:10
```

---

### Test Group PREM-2: File Landing Zone Validation

#### PREM-TEST-003: File Arrival in Landing Zone
**Objective:** Verify files moved to \\<FILE_SERVER>\file_transfer\NBS

**Where to Test:** File server \\<FILE_SERVER>

**Test Steps:**
1. Access file share: `\\<FILE_SERVER>\file_transfer\NBS`
2. Verify file present after MFT agent reception
3. Check file permissions (BMC Control-M service account has read access)
4. Verify file properties (size, timestamps)

**Success Criteria:**
- ✅ File present in \\<FILE_SERVER>\file_transfer\NBS
- ✅ File permissions correct (Control-M can read)
- ✅ File not locked (available for processing)

**Monitoring:**
```powershell
# Check file exists
Test-Path "\\<FILE_SERVER>\file_transfer\NBS\CIF_Customer_Info_20250115.csv"

# Check file permissions
Get-Acl "\\<FILE_SERVER>\file_transfer\NBS\CIF_Customer_Info_20250115.csv" | Format-List

# Expected output includes:
# Access: NT AUTHORITY\SYSTEM Allow  FullControl
#         DOMAIN\SVC_CONTROLM Allow  Read, Write
#         DOMAIN\MFT_AGENTS Allow  Read, Write

# Check file not locked
$file = "\\<FILE_SERVER>\file_transfer\NBS\CIF_Customer_Info_20250115.csv"
try {
    [IO.File]::OpenWrite($file).close()
    Write-Host "✅ File not locked"
} catch {
    Write-Host "❌ File locked: $($_.Exception.Message)"
}
```

---

#### PREM-TEST-004: File Decryption (If Encrypted)
**Objective:** Verify encrypted files decrypted successfully

**Where to Test:** PREM-MFT-01 or PREM-MFT-02 (depending on which agent received file)

**Test Scenario:** File received encrypted, must be decrypted before Control-M processing

**Test Steps:**
1. Go Anywhere Agent detects encrypted file (e.g., `CIF_Customer_Info_20250115.csv.gpg`)
2. Agent retrieves decryption key from key store
3. File decrypted automatically: `CIF_Customer_Info_20250115.csv`
4. Verify decrypted file readable and valid

**Success Criteria:**
- ✅ File decrypted successfully
- ✅ Decrypted file size reasonable (not empty, not corrupted)
- ✅ File structure valid (can parse first 10 rows)

**Monitoring:**
```powershell
# Check Go Anywhere decryption logs
Get-Content "C:\GoAnywhere\Logs\decryption.log" -Tail 50

# Expected log:
# [2025-01-15 06:17:10] INFO: Encrypted file detected: CIF_Customer_Info_20250115.csv.gpg
# [2025-01-15 06:17:11] INFO: Retrieving decryption key: KEY_CIF_PROD
# [2025-01-15 06:17:12] INFO: Decryption started
# [2025-01-15 06:17:15] INFO: Decryption completed: CIF_Customer_Info_20250115.csv
# [2025-01-15 06:17:16] INFO: Original size: 52430000 bytes, Decrypted size: 52428800 bytes
```

**Failure Scenario:** Decryption fails - go to PREM-TEST-021 (Decryption Failure Recovery)

---

#### PREM-TEST-005: Virus Scanning (On-Premise AV)
**Objective:** Verify on-premise antivirus scans incoming files

**Where to Test:** File server \\<FILE_SERVER> (Windows Defender or McAfee)

**Test Steps:**
1. File arrives in \\<FILE_SERVER>\file_transfer\NBS
2. On-premise antivirus (Windows Defender / McAfee) automatically scans file
3. Verify scan completes before Control-M processing
4. Verify scan result logged

**Success Criteria:**
- ✅ AV scan triggered automatically
- ✅ Scan completes within 30 seconds
- ✅ File marked as clean
- ✅ Scan result logged in Windows Event Viewer

**Monitoring:**
```powershell
# Check Windows Defender logs
Get-WinEvent -LogName "Microsoft-Windows-Windows Defender/Operational" -MaxEvents 10 | 
  Where-Object {$_.Message -like "*CIF_Customer_Info_20250115.csv*"}

# Expected event:
# Event ID: 1116 (Malware detection - should be 1000 for clean files)
# Level: Information
# Message: Windows Defender Antivirus has scanned a file and determined it is clean.
#          File: \\<FILE_SERVER>\file_transfer\NBS\CIF_Customer_Info_20250115.csv
#          Scan Result: No threats detected

# Or for McAfee:
Get-Content "C:\ProgramData\McAfee\Logs\VSCore.log" -Tail 50 | 
  Select-String "CIF_Customer_Info_20250115.csv"
```

**Failure Scenario (Malware Detected):**
```powershell
# Expected response if malware detected:
# 1. File quarantined to C:\ProgramData\Microsoft\Windows Defender\Quarantine\
# 2. Windows Event Log entry: Event ID 1116 (Malware Detected)
# 3. Email alert sent to security team
# 4. File removed from \\<FILE_SERVER>\file_transfer\NBS
# 5. BMC Control-M job fails (file not found)
```

---

### Test Group PREM-3: BMC Control-M Processing

#### PREM-TEST-006: Control-M Job Triggering
**Objective:** Verify file arrival triggers Control-M job automatically

**Where to Test:** BMC Control-M server

**Test Steps:**
1. Access BMC Control-M console
2. Monitor job: `P_MIS5_Transfer_WebSave_Sun_To_Fri`
3. Verify job triggered when file detected in \\<FILE_SERVER>\file_transfer\NBS
4. Verify job status changes: Waiting → Executing → Completed

**Success Criteria:**
- ✅ Job triggered within 2 minutes of file arrival
- ✅ Job status = "Executing"
- ✅ No errors in job log

**Monitoring:**
```powershell
# Access Control-M Workload Automation (via GUI or CLI)
# Check job status
ctm run status P_MIS5_Transfer_WebSave_Sun_To_Fri

# Expected output:
# Job Name: P_MIS5_Transfer_WebSave_Sun_To_Fri
# Status: Executing
# Start Time: 2025-01-15 06:18:30
# Expected End: 2025-01-15 06:20:00

# Check job log
ctm run log P_MIS5_Transfer_WebSave_Sun_To_Fri

# Expected log:
# [06:18:30] Job started
# [06:18:31] Checking for files in \\<FILE_SERVER>\file_transfer\NBS
# [06:18:32] Found file: CIF_Customer_Info_20250115.csv
# [06:18:33] File validation passed
# [06:18:34] Processing file...
```

---

#### PREM-TEST-007: Staging Copy Job
**Objective:** Verify files copied to staging area

**Where to Test:** BMC Control-M job `P_MIS5_Agresso_MI_Staging_Copy`

**Test Steps:**
1. Monitor Control-M job: `P_MIS5_Agresso_MI_Staging_Copy`
2. Verify files copied from \\<FILE_SERVER>\file_transfer\NBS to <STAGING_DRIVE>:\AgressoMIFeed\Staging
3. Verify file integrity (size matches)
4. Verify original file remains in NBS (not moved, only copied)

**Success Criteria:**
- ✅ Job completes successfully
- ✅ File present in <STAGING_DRIVE>:\AgressoMIFeed\Staging
- ✅ File size matches original
- ✅ Original file still in \\<FILE_SERVER>\file_transfer\NBS

**Monitoring:**
```powershell
# Check Control-M job status
ctm run status P_MIS5_Agresso_MI_Staging_Copy

# Verify file in staging
Test-Path "<STAGING_DRIVE>:\AgressoMIFeed\Staging\CIF_Customer_Info_20250115.csv"
# Output: True

# Compare file sizes
$originalSize = (Get-Item "\\<FILE_SERVER>\file_transfer\NBS\CIF_Customer_Info_20250115.csv").Length
$stagingSize = (Get-Item "<STAGING_DRIVE>:\AgressoMIFeed\Staging\CIF_Customer_Info_20250115.csv").Length

if ($originalSize -eq $stagingSize) {
    Write-Host "✅ File copy successful - sizes match"
} else {
    Write-Host "❌ File copy error - size mismatch"
}
```

---

#### PREM-TEST-008: File Preparation Job
**Objective:** Verify file preparation job reads and validates files

**Where to Test:** BMC Control-M job `P_COPY_WEBSAVE_FILES_TEMP`

**Test Steps:**
1. Monitor Control-M job: `P_COPY_WEBSAVE_FILES_TEMP`
2. Verify job reads files from staging area
3. Verify data validation (schema check, data type check)
4. Verify temporary files created

**Success Criteria:**
- ✅ Job completes successfully
- ✅ Data validation passes
- ✅ Temp files created in expected location

**Monitoring:**
```powershell
# Check job log
ctm run log P_COPY_WEBSAVE_FILES_TEMP

# Expected log:
# [06:22:10] Reading file: <STAGING_DRIVE>:\AgressoMIFeed\Staging\CIF_Customer_Info_20250115.csv
# [06:22:11] Row count: 10,523
# [06:22:12] Column validation: PASSED
# [06:22:13] Data type validation: PASSED
# [06:22:14] Temp file created: D:\AgressoMIFeed\Temp\CIF_20250115.tmp
```

---

#### PREM-TEST-009: File Reformatting Job
**Objective:** Verify file reformatted to webtrans.dat (fixed-width format)

**Where to Test:** BMC Control-M job `P_Websave_Agresso_Post_Cloud`

**Test Steps:**
1. Monitor Control-M job: `P_Websave_Agresso_Post_Cloud`
2. Verify CSV/XLSX files converted to fixed-width format
3. Verify output file created: `webtrans.dat`
4. Validate fixed-width format (no headers, no delimiters, specific column widths)

**Success Criteria:**
- ✅ Job completes successfully
- ✅ webtrans.dat created
- ✅ Format validation passes (fixed-width, no headers)
- ✅ Record count matches source file

**Monitoring:**
```powershell
# Check job status
ctm run status P_Websave_Agresso_Post_Cloud

# Verify output file exists
Test-Path "D:\AgressoMIFeed\Output\webtrans.dat"
# Output: True

# Validate fixed-width format (first 5 lines)
Get-Content "D:\AgressoMIFeed\Output\webtrans.dat" -TotalCount 5

# Expected output (fixed-width, no delimiters):
# 00012345  John Doe                  1000.50  2025-01-15
# 00012346  Jane Smith                 500.25  2025-01-15
# 00012347  Bob Johnson               1500.75  2025-01-15

# Count records
$recordCount = (Get-Content "D:\AgressoMIFeed\Output\webtrans.dat").Count
Write-Host "Record count in webtrans.dat: $recordCount"
# Expected: 10,523 (matches source file row count)
```

---

#### PREM-TEST-010: Dependency Handling (One File Succeeds, Another Fails)
**Objective:** Verify Control-M handles file dependencies correctly

**Where to Test:** BMC Control-M console

**Test Scenario:** 
- File 1 (CIF_Customer_Info_20250115.csv) processes successfully
- File 2 (Deposits_20250115.xlsx) fails validation
- Dependent jobs should handle failure appropriately

**Test Steps:**
1. Corrupt File 2 (Deposits_20250115.xlsx) intentionally:
   ```powershell
   # Replace file content with garbage
   "CORRUPTED DATA" | Out-File "\\<FILE_SERVER>\file_transfer\NBS\Deposits_20250115.xlsx"
   ```
2. Monitor Control-M job execution
3. Verify File 1 job completes successfully
4. Verify File 2 job fails validation
5. Verify dependent jobs handle failure:
   - Option A: Skip dependent processing for File 2
   - Option B: Send alert and wait for manual intervention

**Success Criteria:**
- ✅ File 1 processing completes successfully
- ✅ File 2 validation fails as expected
- ✅ Error logged in Control-M
- ✅ Alert sent to operations team
- ✅ webtrans.dat contains only File 1 data (or separate output files)

**Monitoring:**
```powershell
# Check Control-M job statuses
ctm run status P_MIS5_Agresso_MI_Staging_Copy | Where-Object {$_.FileName -eq "CIF_Customer_Info_20250115.csv"}
# Expected: Status = Completed

ctm run status P_MIS5_Agresso_MI_Staging_Copy | Where-Object {$_.FileName -eq "Deposits_20250115.xlsx"}
# Expected: Status = Failed

# Check Control-M alert log
ctm run alerts

# Expected alert:
# Alert ID: ALT-20250115-001
# Job: P_MIS5_Agresso_MI_Staging_Copy
# File: Deposits_20250115.xlsx
# Error: File validation failed - corrupted data
# Action: Manual intervention required
# Severity: HIGH
```

**Resolution Steps:**
1. Identify root cause (corrupted file)
2. Request file re-upload from AWS (see AWS-TEST-015 for recovery)
3. Once valid file received, rerun failed Control-M job
4. Verify processing completes successfully

---

### Test Group PREM-4: Transfer to Go Anywhere Cloud

#### PREM-TEST-011: SFTP to Go Anywhere Cloud
**Objective:** Verify webtrans.dat uploaded to Go Anywhere Cloud storage

**Where to Test:** BMC Control-M job `P_Websave_Agresso_SFTP_Send`

**Test Steps:**
1. Monitor Control-M job: `P_Websave_Agresso_SFTP_Send`
2. Verify SFTP connection established to Go Anywhere Cloud
3. Verify webtrans.dat uploaded successfully
4. Verify file present in Go Anywhere Cloud storage

**Success Criteria:**
- ✅ SFTP connection established
- ✅ File uploaded successfully
- ✅ Upload duration within SLA (< 5 minutes)
- ✅ File visible in Go Anywhere Cloud web console

**Monitoring:**
```powershell
# Check Control-M job log
ctm run log P_Websave_Agresso_SFTP_Send

# Expected log:
# [06:30:10] Connecting to Go Anywhere Cloud SFTP
# [06:30:11] Host: sftp.goanywhere.cloud
# [06:30:12] User: banking_app_prod
# [06:30:13] Authentication: SUCCESS
# [06:30:14] Uploading file: webtrans.dat (52 MB)
# [06:30:45] Upload progress: 25%
# [06:31:15] Upload progress: 50%
# [06:31:45] Upload progress: 75%
# [06:32:10] Upload completed: webtrans.dat
# [06:32:11] File size verified: 52428800 bytes
# [06:32:12] SFTP connection closed

# Verify file in Go Anywhere Cloud (via web console or API)
# Login to: https://goanywhere.cloud/
# Navigate to: /incoming/banking-app/
# Verify file present: webtrans_20250115.dat
```

---

#### PREM-TEST-012: Go Anywhere Cloud Storage Validation
**Objective:** Verify file stored correctly in Go Anywhere Cloud

**Where to Test:** Go Anywhere Cloud web console (https://goanywhere.cloud/)

**Test Steps:**
1. Login to Go Anywhere Cloud web console
2. Navigate to banking app folder: `/incoming/banking-app/`
3. Verify file present: `webtrans_20250115.dat`
4. Verify file metadata (size, upload timestamp, checksum)
5. Verify file accessible (download test)

**Success Criteria:**
- ✅ File present in correct folder
- ✅ File size matches source (52,428,800 bytes)
- ✅ File downloadable (not corrupted)
- ✅ Checksum validated

**Monitoring:**
```
# Via Go Anywhere Cloud Web Console:
1. Login: https://goanywhere.cloud/
2. Navigate: Files → incoming → banking-app
3. Verify file listing:
   
   File Name: webtrans_20250115.dat
   Size: 50.0 MB (52,428,800 bytes)
   Uploaded: 2025-01-15 06:32:12 UTC
   Checksum (MD5): a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6
   Status: Available
   Retention: 30 days

4. Download test (click download button)
5. Verify download completes successfully
```

**SolarWinds Monitoring:**
```
✅ SolarWinds Alert (Success):
Subject: File Upload Success - webtrans_20250115.dat
Body:
  File: webtrans_20250115.dat
  Source: \\<FILE_SERVER> (via PREM-MFT-01)
  Destination: Go Anywhere Cloud (/incoming/banking-app/)
  Upload Time: 2025-01-15 06:32:12 UTC
  File Size: 50.0 MB
  Status: SUCCESS
  Next Step: Transfer to Unit4 Agresso scheduled for 07:00 AM
```

---

### Test Group PREM-5: Error Scenarios & Recovery (On-Premise)

#### PREM-TEST-020: MFT Agent Down Recovery
**Objective:** Verify recovery when MFT agent service fails

**Where to Test:** PREM-MFT-01 and PREM-MFT-02

**Test Scenario:** Go Anywhere Agent service crashes on PREM-MFT-01

**Test Steps:**
1. Simulate agent crash:
   ```powershell
   # RDP to PREM-MFT-01
   Stop-Service -Name "GoAnywhereAgent" -Force
   ```
2. Verify SolarWinds detects agent down (< 2 minutes)
3. Verify files route to PREM-MFT-02 automatically (see PREM-TEST-002)
4. Restart agent on PREM-MFT-01:
   ```powershell
   Start-Service -Name "GoAnywhereAgent"
   ```
5. Verify agent rejoins cluster
6. Verify file transfer resumes normally

**Success Criteria:**
- ✅ SolarWinds detects failure within 2 minutes
- ✅ Alert sent to operations team
- ✅ Automatic failover to PREM-MFT-02
- ✅ No files lost during failover
- ✅ Agent restart successful
- ✅ File transfer resumes normally

**Recovery Time Objective (RTO):** < 5 minutes

---

#### PREM-TEST-021: Decryption Failure Recovery
**Objective:** Recover from decryption key errors

**Where to Test:** PREM-MFT-01 or PREM-MFT-02

**Test Scenario:** Decryption key expired or missing

**Test Steps:**
1. Simulate decryption key error (rename key file):
   ```powershell
   Rename-Item "C:\GoAnywhere\Keys\CIF_PROD_KEY.asc" "C:\GoAnywhere\Keys\CIF_PROD_KEY.asc.bak"
   ```
2. Trigger file transfer (encrypted file)
3. Verify decryption fails
4. Verify error logged and alert sent
5. Restore decryption key:
   ```powershell
   Rename-Item "C:\GoAnywhere\Keys\CIF_PROD_KEY.asc.bak" "C:\GoAnywhere\Keys\CIF_PROD_KEY.asc"
   ```
6. Manually trigger re-decryption:
   ```powershell
   # Via Go Anywhere Agent console:
   # Right-click failed file → Retry Decryption
   ```
7. Verify decryption succeeds
8. Verify file processing continues

**Success Criteria:**
- ✅ Decryption failure detected immediately
- ✅ Error logged with clear message
- ✅ Alert sent within 1 minute
- ✅ Key restored successfully
- ✅ Retry succeeds
- ✅ No data loss

**Expected Error Log:**
```
[2025-01-15 06:25:10] ERROR: Decryption failed for file: CIF_Customer_Info_20250115.csv.gpg
[2025-01-15 06:25:11] ERROR: Decryption key not found: CIF_PROD_KEY.asc
[2025-01-15 06:25:12] ERROR: File moved to error queue: C:\GoAnywhere\Error\CIF_Customer_Info_20250115.csv.gpg
[2025-01-15 06:25:13] ALERT: Email sent to ops-team@example.com
```

---

#### PREM-TEST-022: Control-M Job Failure Recovery
**Objective:** Recover from failed Control-M job

**Where to Test:** BMC Control-M console

**Test Scenario:** Job `P_Websave_Agresso_Post_Cloud` fails due to disk space

**Test Steps:**
1. Simulate disk space issue (fill disk to 95%):
   ```powershell
   # Create large temp file to fill disk
   fsutil file createnew D:\temp_fill.dat 10737418240  # 10 GB
   ```
2. Trigger Control-M job: `P_Websave_Agresso_Post_Cloud`
3. Verify job fails with "Disk full" error
4. Verify alert sent to operations team
5. Free up disk space:
   ```powershell
   Remove-Item D:\temp_fill.dat -Force
   Remove-Item D:\AgressoMIFeed\Archive\*.dat -Recurse -Force  # Clean old files
   ```
6. Rerun failed Control-M job:
   ```powershell
   ctm run rerun P_Websave_Agresso_Post_Cloud
   ```
7. Verify job completes successfully

**Success Criteria:**
- ✅ Job failure detected immediately
- ✅ Error clearly indicates root cause (disk space)
- ✅ Alert sent within 2 minutes
- ✅ Disk space freed up
- ✅ Job rerun succeeds
- ✅ No data loss or corruption

**Recovery Time:** < 15 minutes

---

#### PREM-TEST-023: File Recovery from Backup (On-Premise)
**Objective:** Recover deleted or corrupted files from on-premise backup

**Where to Test:** \\<FILE_SERVER> file server backup

**Test Scenario:** File accidentally deleted from \\<FILE_SERVER>\file_transfer\NBS

**Test Steps:**
1. Simulate file deletion:
   ```powershell
   Remove-Item "\\<FILE_SERVER>\file_transfer\NBS\CIF_Customer_Info_20250115.csv" -Force
   ```
2. Verify file missing
3. Access Windows Server Backup or backup software (Veeam, Commvault, etc.)
4. Locate most recent backup containing the file
5. Restore file to original location
6. Verify file integrity (size, checksum)
7. Rerun Control-M jobs if needed

**Success Criteria:**
- ✅ Backup available and accessible
- ✅ File restored within 30 minutes
- ✅ File integrity validated
- ✅ Processing resumes successfully

**Recovery Commands (Windows Server Backup):**
```powershell
# List available backups
wbadmin get versions -backupTarget:E:

# Restore specific file
wbadmin start recovery `
  -version:01/15/2025-06:00 `
  -itemType:File `
  -items:\\<FILE_SERVER>\file_transfer\NBS\CIF_Customer_Info_20250115.csv `
  -recoverTarget:Original `
  -overwrite:yes

# Or via Veeam:
# 1. Open Veeam Backup & Replication console
# 2. Navigate: Home → Backups → File-Level Restore
# 3. Select backup: <FILE_SERVER>_Daily_2025-01-15
# 4. Browse to: \file_transfer\NBS\CIF_Customer_Info_20250115.csv
# 5. Click Restore → Restore to Original Location
```

**Recovery Time Objective (RTO):** < 30 minutes

---

#### PREM-TEST-024: Internet Outage (VPN Down)
**Objective:** Verify detection and alerting when VPN/Internet connection fails

**Where to Test:** Network infrastructure + all servers

**Test Scenario:** Site-to-Site VPN between AWS and on-premise goes down

**Test Steps:**
1. Simulate VPN failure (disconnect VPN tunnel)
2. Verify MFT agents detect connectivity loss
3. Verify SolarWinds alerts within 2 minutes
4. Verify files queue on AWS side (not dropped)
5. Restore VPN connection
6. Verify queued files transfer automatically
7. Verify no data loss

**Success Criteria:**
- ✅ VPN failure detected within 2 minutes
- ✅ SolarWinds alert sent immediately
- ✅ Files queue on AWS (not dropped)
- ✅ VPN restored successfully
- ✅ Files transfer automatically after restoration
- ✅ No data loss

**Monitoring:**
```powershell
# Check VPN status from on-premise side
Test-NetConnection -ComputerName "aws-transfer-endpoint.amazonaws.com" -Port 22

# Expected during outage:
# WARNING: Ping to aws-transfer-endpoint.amazonaws.com failed
# TcpTestSucceeded : False

# SolarWinds alert expected:
Subject: 🚨 CRITICAL - VPN Connection Down
Body:
  Alert: VPN connection to AWS failed
  Tunnel Status: DOWN
  Last Successful Connection: 2025-01-15 06:35:10
  Affected Services:
    - File transfer from AWS to on-premise
    - MFT agents (PREM-MFT-01, PREM-MFT-02) cannot reach AWS
  Action Required:
    - Check VPN tunnel status on AWS side
    - Verify on-premise firewall rules
    - Check ISP connectivity
  Runbook: https://wiki.example.com/vpn-troubleshooting
```

---

### On-Premise Testing Summary

| Test ID | Test Name | Server/Location | Criticality | Duration |
|---------|-----------|-----------------|-------------|----------|
| PREM-TEST-001 | File reception on PREM-MFT-01 | PREM-MFT-01 | 🔴 HIGH | 10 min |
| PREM-TEST-002 | Failover to PREM-MFT-02 | Both MFT servers | 🔴 HIGH | 20 min |
| PREM-TEST-003 | File landing zone validation | \\<FILE_SERVER> | 🔴 HIGH | 5 min |
| PREM-TEST-004 | File decryption | MFT servers | 🟡 MEDIUM | 10 min |
| PREM-TEST-005 | Virus scanning (on-prem) | \\<FILE_SERVER> | 🟡 MEDIUM | 10 min |
| PREM-TEST-006 | Control-M job triggering | Control-M server | 🔴 HIGH | 10 min |
| PREM-TEST-007 | Staging copy job | Control-M server | 🔴 HIGH | 10 min |
| PREM-TEST-008 | File preparation job | Control-M server | 🟡 MEDIUM | 10 min |
| PREM-TEST-009 | File reformatting job | Control-M server | 🔴 HIGH | 15 min |
| PREM-TEST-010 | Dependency handling | Control-M server | 🟡 MEDIUM | 20 min |
| PREM-TEST-011 | SFTP to Go Anywhere Cloud | Control-M server | 🔴 HIGH | 15 min |
| PREM-TEST-012 | Cloud storage validation | Go Anywhere Cloud | 🟡 MEDIUM | 10 min |
| PREM-TEST-020 | MFT agent recovery | Both MFT servers | 🔴 HIGH | 20 min |
| PREM-TEST-021 | Decryption failure recovery | MFT servers | 🟡 MEDIUM | 15 min |
| PREM-TEST-022 | Control-M job recovery | Control-M server | 🔴 HIGH | 20 min |
| PREM-TEST-023 | File recovery from backup | \\<FILE_SERVER> | 🔴 HIGH | 30 min |
| PREM-TEST-024 | Internet outage (VPN down) | Network/All servers | 🔴 HIGH | 30 min |

**Total On-Premise Testing Duration:** ~4-5 hours

---

## 🎯 Go Anywhere Cloud Storage Testing

### Who Performs These Tests?
**Team:** MFT Team + Operations Team  
**Access:** Go Anywhere Cloud web console (https://goanywhere.cloud/)

### Test Group CLOUD-1: Final Transfer to Agresso

#### CLOUD-TEST-001: Transfer to Unit4 Agresso Cloud
**Objective:** Verify webtrans.dat transferred successfully to Agresso

**Where to Test:** Go Anywhere Cloud (initiates transfer) → Unit4 Agresso (receives)

**Test Steps:**
1. Verify webtrans.dat present in Go Anywhere Cloud
2. Scheduled transfer initiates (e.g., 07:00 AM daily)
3. SFTP connection to Agresso: `<AGRESSO_SFTP_HOST>`
4. File uploaded to: `\\S-UKSBW-APPP06\uk_wbs_prod$\Data Import`
5. Verify Agresso acknowledges receipt

**Success Criteria:**
- ✅ SFTP connection to Agresso succeeds
- ✅ File uploaded successfully
- ✅ Agresso sends confirmation (ACK file or email)
- ✅ File visible in Agresso import folder

**Monitoring:**
```
# Via Go Anywhere Cloud web console:
1. Navigate: Workflows → Scheduled Transfers
2. Find: Daily_Agresso_Transfer_07AM
3. View execution log:

   [07:00:10] Workflow started: Daily_Agresso_Transfer_07AM
   [07:00:11] Source file: /incoming/banking-app/webtrans_20250115.dat
   [07:00:12] Connecting to Agresso SFTP
   [07:00:13] Host: <AGRESSO_SFTP_HOST>
   [07:00:14] User: banking_prod_user
   [07:00:15] Authentication: SUCCESS
   [07:00:16] Uploading file: webtrans_20250115.dat
   [07:01:45] Upload completed (50 MB in 89 seconds)
   [07:01:46] File path: \\S-UKSBW-APPP06\uk_wbs_prod$\Data Import\webtrans_20250115.dat
   [07:01:47] Agresso ACK received: ACK_webtrans_20250115.txt
   [07:01:48] Workflow completed successfully

# SolarWinds notification:
✅ Subject: File Transfer to Agresso Success
Body:
  File: webtrans_20250115.dat
  Destination: Unit4 Agresso Cloud
  Transfer Time: 89 seconds
  File Size: 50.0 MB
  Status: SUCCESS
  Agresso ACK: Received
  Next Step: Agresso General Ledger processing
```

---

## 📊 Complete Testing Matrix

### Test Execution Plan

| Phase | Location | Team | Duration | Success Rate Target |
|-------|----------|------|----------|---------------------|
| **Phase 1: AWS Testing** | AWS Cloud | AWS Platform Team | 2 hours | ≥ 95% |
| **Phase 2: MFT Agent Testing** | PREM-MFT-01/02 | On-Prem / MFT Team | 2 hours | ≥ 95% |
| **Phase 3: Control-M Testing** | Control-M Server | On-Prem Team | 3 hours | ≥ 95% |
| **Phase 4: Cloud Storage Testing** | Go Anywhere Cloud | MFT Team | 1 hour | ≥ 98% |
| **Phase 5: End-to-End Testing** | All locations | All teams | 4 hours | ≥ 90% |
| **Phase 6: Failover Testing** | All locations | All teams | 4 hours | ≥ 85% |

**Total Testing Duration:** ~16 hours (2 days)

---

## 🚨 SolarWinds Monitoring Summary

### What SolarWinds Monitors

| Component | Monitoring Point | Alert Threshold | Notification |
|-----------|------------------|-----------------|--------------|
| **AWS Transfer** | File upload success/failure | Any failure | Email, SMS |
| **Go Anywhere MFT** | Workflow execution | Execution time > 10 min | Email |
| **MFT Agents (PREM-MFT-01/02)** | Service status | Service down > 2 min | SMS, PagerDuty |
| **VPN Connectivity** | AWS ↔ On-Prem | VPN tunnel down | SMS, PagerDuty |
| **File Age** | Files not processed | File age > 2 hours | Email, Slack |
| **Go Anywhere Cloud** | Storage capacity | Disk > 90% | Email |
| **Agresso Transfer** | Final transfer status | Transfer failure | Email, SMS |

---

## ✅ Success Criteria Summary

### Overall OAT Success Criteria

| Metric | Target | Measurement |
|--------|--------|-------------|
| **File Transfer Success Rate** | ≥ 99% | (Successful transfers / Total transfers) × 100 |
| **File Recovery Time** | < 30 minutes | Time from failure detection to successful recovery |
| **MFT Agent Failover Time** | < 5 minutes | Time to failover from PREM-MFT-01 to PREM-MFT-02 |
| **VPN Outage Detection** | < 2 minutes | Time from VPN down to SolarWinds alert |
| **Control-M Job Recovery** | < 15 minutes | Time from job failure to successful rerun |
| **Data Integrity** | 100% | Checksum validation pass rate |
| **Alert Delivery** | < 1 minute | Time from event to alert delivery |

---

## 📞 Escalation Matrix

| Issue Severity | Response Time | Escalation Path |
|----------------|---------------|-----------------|
| **CRITICAL** (VPN down, MFT platform down, data loss) | < 15 minutes | L1 → L2 → Manager → Director |
| **HIGH** (File transfer failure, job failure) | < 30 minutes | L1 → L2 → Manager |
| **MEDIUM** (Delayed transfer, warning alerts) | < 1 hour | L1 → L2 |
| **LOW** (Informational alerts) | < 4 hours | L1 |

---

## 📚 References

- **TS1 OAT - Failover and Recovery Testing details v0.1.docx** - Detailed test scenarios
- **FILE-TRANSFER-TESTING-STRATEGY.md** - Overall testing strategy
- **AWS_vs_OnPremise_vs_GoAnywhere_Test_Locations.md** - Test location matrix

---

**Document Version:** 1.0  
**Last Updated:** 2025-01-15  
**Owner:** Platform Engineering Team  
**Review Date:** Quarterly  
**Approved By:** [Name], [Title]

---

*This document provides comprehensive guidance for OAT file recovery testing across AWS, On-Premise, and Go Anywhere Cloud environments.*








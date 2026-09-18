# Test Location Matrix: AWS to On-Premise to Go Anywhere
## File Transfer Testing - Clear Test Location Assignments

---

## 📋 Architecture Overview 

```
┌──────────────────────────────────────────────────────────────┐
│                    AWS BANKING APPLICATION                   │
│                         (SOURCE)                             │
│                                                              │
│  • Daily file generation                                     │
│  • S3 landing buckets                                        │
│  • Anti-malware scanning                                     │
│  • File validation                                           │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     │ AWS Transfer Family SFTP
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│              GO ANYWHERE MFT PLATFORM                        │
│           (FILE TRANSFER ORCHESTRATION)                      │
│                                                              │
│  • SolarWinds Monitoring & Notifications                     │
│  • File transfer workflow management                         │
│  • Encryption/Decryption                                     │
│  • Error handling & retry logic                              │
│  • Audit logging                                             │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     │ Site-to-Site VPN 
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│                 ON-PREMISE FILE SERVERS                      │
│                     (DESTINATION)                            │
│                                                              │
│  • \\<FILE_SERVER>\file_transfer\NBS                         |    │
│  • BMC Control-M Jobs                                        │
│  • File processing & reformatting                            │
│  • Staging area management                                   │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     │ SFTP via Go Anywhere
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│               GO ANYWHERE CLOUD STORAGE                      │
│                                                              │
│  • Intermediate storage                                      │
│  • SolarWinds monitoring                                     │
└────────────────────┬─────────────────────────────────────────┘
                     │
                     │ Final SFTP Transfer
                     │
                     ▼
┌──────────────────────────────────────────────────────────────┐
│                  UNIT4 AGRESSO CLOUD                         │
│                   (FINAL DESTINATION)                        │
│                                                              │
│  • <AGRESSO_SFTP_HOST>                                       │
│  • \\Server location\uk_xxx_prod$\Data Import                │
└──────────────────────────────────────────────────────────────┘
```

---

## 🎯 Test Location Decision Matrix

| Test Scenario | Primary Test Location   | Secondary Location | Monitoring Tool | Who Performs Test |
|---------------|-------------------------|--------------------|-----------------|--------------------|
| **1. File Generation in AWS** | ✅ AWS Side              | - | CloudWatch, Lambda Logs | AWS Team |
| **2. File Upload to MFT** | ✅ AWS Side              | Go Anywhere Platform | Go Anywhere Logs, SolarWinds | AWS Team + MFT Team |
| **3. Anti-Malware Scanning** | ✅ AWS Side              | Go Anywhere (if MFT has AV) | CloudWatch, SolarWinds | AWS Team |
| **4. File Encryption** | ✅ Go Anywhere Platform  | AWS (if done pre-transfer) | Go Anywhere Logs, SolarWinds | MFT Team |
| **5. File Transfer to On-Prem** | ✅ Go Anywhere Platform  | On-Premise (reception) | SolarWinds, BMC Control-M | MFT Team + On-Prem Team |
| **6. File Decryption** | ✅ On-Premise Side       | Go Anywhere (if done at MFT) | BMC Control-M, Windows Event Logs | On-Prem Team |
| **7. Virus Scanning ** | ✅ AWS Side              | - | On-Premise Antivirus, Control-M | On-Prem Team |
| **8. File Reception Validation** | ✅ On-Premise Side       | - | BMC Control-M, PowerShell Scripts | On-Prem Team |
| **9. BMC Control-M Processing** | ✅ On-Premise Side       | - | BMC Control-M Dashboard | On-Prem Team |
| **10. File Reformatting** | ✅ On-Premise Side       | - | BMC Control-M Jobs | On-Prem Team |
| **11. SFTP to Go Anywhere Cloud** | ✅ On-Premise Side       | Go Anywhere Cloud | SolarWinds, Control-M | On-Prem Team + MFT Team |
| **12. Go Anywhere Cloud Storage** | ✅ Go Anywhere Cloud     | - | SolarWinds | MFT Team |
| **13. Final Transfer to Agresso** | ✅ Go Anywhere Cloud     | Agresso (reception) | SolarWinds, Agresso Logs | MFT Team + Agresso Team |
| **14. MFT Agent/Platform Down** | ✅ Go Anywhere Platform  | AWS & On-Premise | SolarWinds Alerts | MFT Team |
| **15. Internet/VPN Down** | ✅ Both AWS & On-Premise | Network Infrastructure | AWS CloudWatch, SolarWinds | Network Team |
| **16. File Recovery from Backup** | ✅ All Three             | Depends on recovery source | Backup software, S3 Versioning | Respective Teams |

---

## 📊 Detailed Test Breakdown by Location

### 🔵 **Tests to Perform on AWS Side**

#### Test Group A: File Generation & Initial Validation

| Test ID | Test Name | What to Test | Success Criteria | Monitoring |
|---------|-----------|--------------|------------------|------------|
| **AWS-001** | Daily file generation | Banking app generates files in S3 landing bucket | Files present with correct naming convention | CloudWatch Events, S3 Event Notifications |
| **AWS-002** | File naming convention | Files follow pattern: `<FileType>_YYYYMMDD.<ext>` | All files match naming standard | Lambda validation function |
| **AWS-003** | File completeness | File size > 0 bytes, expected columns present | Size check passes, schema validation passes | Lambda metadata check |
| **AWS-004** | Multiple file types | .xlsx, .csv, .html files generated correctly | Each format parses successfully | Lambda parser tests |
| **AWS-005** | Timestamp accuracy | File creation timestamp matches expected schedule | Files created within ±5 min of schedule | CloudWatch metric |

#### Test Group B: Security & Anti-Malware

| Test ID | Test Name | What to Test | Success Criteria | Monitoring |
|---------|-----------|--------------|------------------|------------|
| **AWS-006** | Clean file scanning | Clean files pass AV scan and continue transfer | File remains in landing bucket | Lambda AV function logs |
| **AWS-007** | Malware detection (EICAR) | EICAR test file triggers quarantine | File moved to quarantine bucket | CloudWatch alarm, SNS alert |
| **AWS-008** | Quarantine isolation | Infected files isolated and not transferred | No infected files reach MFT | S3 bucket policies enforce isolation |
| **AWS-009** | Scan performance | Scan completes in < 5 sec for 10MB file | 95th percentile < 5 sec | CloudWatch metrics |
| **AWS-010** | SNS alert delivery | Malware alert delivered within 30 sec | Alert received by ops team | SNS delivery logs |

#### Test Group C: File Integrity & Validation

| Test ID | Test Name | What to Test | Success Criteria | Monitoring |
|---------|-----------|--------------|------------------|------------|
| **AWS-011** | MD5 checksum calculation | Checksum calculated and stored as metadata | Metadata present on S3 object | S3 object metadata |
| **AWS-012** | File size validation | Size matches expected range | File within ±20% of average size | Lambda validation |
| **AWS-013** | Format validation (XLSX) | Excel files parse without errors | openpyxl successfully reads file | Lambda logs |
| **AWS-014** | Format validation (CSV) | CSV files have correct delimiter and encoding | csv.reader parses successfully | Lambda logs |
| **AWS-015** | Encoding verification | Files in UTF-8 encoding | Character set validation passes | Lambda validation |

#### Test Group D: File Transfer to MFT

| Test ID | Test Name | What to Test | Success Criteria | Monitoring |
|---------|-----------|--------------|------------------|------------|
| **AWS-016** | MFT connection establishment | AWS can connect to Go Anywhere MFT | Connection established < 5 sec | CloudWatch Logs |
| **AWS-017** | Authentication success | SSH key or credentials validated | Auth succeeds | Transfer logs |
| **AWS-018** | File upload initiation | File transfer starts successfully | Transfer begins | CloudWatch Events |
| **AWS-019** | Upload bandwidth | Upload speed meets SLA (e.g., > 10 Mbps) | Speed measured and logged | Custom metric |
| **AWS-020** | Concurrent uploads | Multiple files upload simultaneously | No failures under load | Load test results |

---

### 🟢 **Tests to Perform on Go Anywhere MFT Platform**

#### Test Group E: File Reception & Orchestration

| Test ID | Test Name | What to Test | Success Criteria | Monitoring |
|---------|-----------|--------------|------------------|------------|
| **MFT-001** | File reception from AWS | MFT receives files from AWS successfully | File present in MFT landing zone | Go Anywhere logs, SolarWinds dashboard |
| **MFT-002** | File integrity check | MFT validates MD5 checksum | Checksum matches source | Go Anywhere workflow logs |
| **MFT-003** | SolarWinds notification | Alert sent when file received | Notification delivered < 1 min | SolarWinds alert log |
| **MFT-004** | Workflow triggering | File reception triggers processing workflow | Workflow executes automatically | Go Anywhere workflow status |
| **MFT-005** | File queuing | Files queue properly during high volume | No files dropped | Go Anywhere queue metrics |

#### Test Group F: Encryption & Security

| Test ID | Test Name | What to Test | Success Criteria | Monitoring |
|---------|-----------|--------------|------------------|------------|
| **MFT-006** | Encryption (if applicable) | File encrypted before transfer to on-prem | Encrypted file created | Go Anywhere logs |
| **MFT-007** | Encryption key management | Correct keys used for encryption | No key errors | Go Anywhere security logs |
| **MFT-008** | TLS/SSL validation | Transfer uses TLS 1.2+ | SSL certificate valid | Network packet capture |
| **MFT-009** | Access control | Only authorized systems can retrieve files | Unauthorized access denied | Go Anywhere audit log |
| **MFT-010** | File retention policy | Files deleted after successful transfer | Old files cleaned up | Go Anywhere retention logs |

#### Test Group G: Error Handling & Retry Logic

| Test ID | Test Name | What to Test | Success Criteria | Monitoring |
|---------|-----------|--------------|------------------|------------|
| **MFT-011** | Network interruption handling | MFT retries after network failure | Transfer resumes after reconnect | Go Anywhere retry logs |
| **MFT-012** | Failed transfer retry | Failed transfers retry up to 3 times | Retry count = 3, then alert | SolarWinds alert |
| **MFT-013** | Exponential backoff | Retry delay increases: 1min, 2min, 4min | Timing verified in logs | Go Anywhere workflow logs |
| **MFT-014** | Dead letter queue | Failed files moved to error queue | File in DLQ after max retries | Go Anywhere error queue |
| **MFT-015** | Alert escalation | Critical failures escalate to on-call | PagerDuty/SMS received | SolarWinds escalation log |

#### Test Group H: Transfer to On-Premise

| Test ID | Test Name | What to Test | Success Criteria | Monitoring |
|---------|-----------|--------------|------------------|------------|
| **MFT-016** | VPN connectivity check | MFT can reach on-prem via VPN | Ping/traceroute succeeds | SolarWinds network monitor |
| **MFT-017** | File push to on-prem | Files transferred to \\<FILE_SERVER> | File present on file server | Go Anywhere transfer log |
| **MFT-018** | Transfer completion notification | Notification sent after successful transfer | Alert received < 1 min | SolarWinds notification |
| **MFT-019** | Large file handling | 100MB+ files transfer without timeout | Transfer completes | Go Anywhere logs |
| **MFT-020** | Bandwidth throttling | Transfer doesn't saturate VPN bandwidth | < 80% bandwidth used | Network monitoring |

---

### 🟠 **Tests to Perform on On-Premise Side**

#### Test Group I: File Reception & Validation

| Test ID | Test Name | What to Test | Success Criteria | Monitoring |
|---------|-----------|--------------|------------------|------------|
| **PREM-001** | File arrival detection | Files arrive in \\<FILE_SERVER>\file_transfer\NBS | File present in directory | PowerShell script, Control-M sensor |
| **PREM-002** | File decryption  | Encrypted files decrypted successfully | Decrypted file readable | Decryption script logs |
| **PREM-003** | Virus scanning (on-prem AV) | On-premise AV scans incoming files | Scan completes, no malware found | Antivirus logs |
| **PREM-004** | File permissions check | Files have correct NTFS permissions | Read/write access for Control-M account | Windows Event Viewer |
| **PREM-005** | Disk space monitoring | Adequate disk space for incoming files | > 10 GB free space | SCOM/Monitoring tool |

#### Test Group J: BMC Control-M Processing

| Test ID | Test Name | What to Test | Success Criteria | Monitoring |
|---------|-----------|--------------|------------------|------------|
| **PREM-006** | Control-M job triggering | File arrival triggers Control-M job | Job status = "Started" | BMC Control-M dashboard |
| **PREM-007** | Staging copy (P_MIS5_Agresso_MI_Staging_Copy) | Files copied to <STAGING_DRIVE>:\AgressoMIFeed\Staging | Files present in staging | Control-M job log |
| **PREM-008** | File preparation (P_COPY_WEBSAVE_FILES_TEMP) | Files read and validated | Job completes successfully | Control-M job log |
| **PREM-009** | Reformatting (P_Websave_Agresso_Post_Cloud) | Files converted to fixed-width webtrans.dat | webtrans.dat created | Control-M job log, file validation script |
| **PREM-010** | Dependency handling | If file 1 succeeds, file 2 processes | Both jobs complete in sequence | Control-M dependency chain |

#### Test Group K: Error Scenarios (On-Premise)

| Test ID | Test Name | What to Test | Success Criteria | Monitoring |
|---------|-----------|--------------|------------------|------------|
| **PREM-011** | Missing file detection | Control-M detects if expected file missing | Alert sent within 30 min | Control-M notification |
| **PREM-012** | Corrupted file handling | Corrupted file fails validation gracefully | Job fails, error logged, alert sent | Control-M job log |
| **PREM-013** | Empty file handling | Empty (0-byte) file triggers warning | Warning logged, processing skipped | Control-M log |
| **PREM-014** | Invalid format handling | Invalid XLSX/CSV triggers error | Error logged, file quarantined | Control-M error handler |
| **PREM-015** | Job failure notification | Failed jobs send email/SMS alert | Alert received < 5 min | Email/SMS logs |

#### Test Group L: File Transfer to Go Anywhere Cloud

| Test ID | Test Name | What to Test | Success Criteria | Monitoring |
|---------|-----------|--------------|------------------|------------|
| **PREM-016** | SFTP connection to Go Anywhere Cloud | Connection established from on-prem | Auth succeeds | Control-M SFTP log |
| **PREM-017** | webtrans.dat upload | Formatted file uploaded successfully | File present in Go Anywhere Cloud | Go Anywhere storage logs |
| **PREM-018** | Upload verification | Control-M verifies file uploaded | File size matches, no errors | Control-M verification script |
| **PREM-019** | Post-upload cleanup | Processed files archived/deleted | Staging area cleaned up | PowerShell cleanup script log |
| **PREM-020** | Audit log update | Transfer logged in audit database | Audit record created | SQL query on audit table |

---

### 🟣 **Tests to Perform on Go Anywhere Cloud Storage**

#### Test Group M: Cloud Storage & Final Transfer

| Test ID | Test Name | What to Test | Success Criteria | Monitoring |
|---------|-----------|--------------|------------------|------------|
| **GAC-001** | File reception in cloud storage | webtrans.dat received from on-prem | File present | SolarWinds storage monitor |
| **GAC-002** | Storage retention | Files retained for required duration (e.g., 30 days) | Files older than 30 days purged | Go Anywhere retention policy |
| **GAC-003** | File integrity validation | MD5/SHA256 checksum validated | Checksum matches | Go Anywhere validation log |
| **GAC-004** | Access control | Only Agresso can access files | Unauthorized access blocked | Go Anywhere audit log |
| **GAC-005** | SolarWinds monitoring active | SolarWinds monitors file status | Real-time visibility | SolarWinds dashboard |

#### Test Group N: Final Transfer to Agresso

| Test ID | Test Name | What to Test | Success Criteria | Monitoring |
|---------|-----------|--------------|------------------|------------|
| **GAC-006** | SFTP to Agresso gateway | Connection to <AGRESSO_SFTP_HOST> | Connection succeeds | Go Anywhere transfer log |
| **GAC-007** | Authentication with Agresso | SSH key authentication succeeds | Auth verified | Agresso SFTP logs |
| **GAC-008** | File path validation | File delivered to correct path (\\S-UKSBW-APPP06\uk_wbs_prod$\Data Import) | Path correct | Go Anywhere logs |
| **GAC-009** | Transfer confirmation | Agresso acknowledges file receipt | ACK received | Agresso confirmation log |
| **GAC-010** | Final notification | Success notification sent to ops team | Email/SMS received | SolarWinds notification log |

---

### 🔴 **Tests to Perform at Network/Infrastructure Level (All Locations)**

#### Test Group O: Network & Connectivity

| Test ID     | Test Name | Test Location | What to Test | Success Criteria |
|-------------|-----------|---------------|--------------|------------------|
| **NET-001** | VPN connectivity | AWS ↔ On-Premise | Site-to-Site VPN operational | Both tunnels UP |
| **NET-002** | VPN failover | AWS ↔ On-Premise | Secondary VPN activates if primary fails | Failover < 2 min |
| **NET-003** | DNS resolution | All locations | Hostnames resolve correctly | nslookup succeeds |
| **NET-004** | Firewall rules | All locations | Required ports open (22 for SFTP, 443 for HTTPS) | Connection succeeds |
| **NET-005** | Bandwidth testing | All locations | Adequate bandwidth for file transfer | > 10 Mbps sustained |
| **NET-006** | Latency measurement | All locations | Latency within acceptable range | < 100ms AWS to on-prem |
| **NET-007** | Packet loss | All locations | No packet loss during transfer | 0% loss |
| **NET-008** | MTU optimization | All locations | MTU configured correctly (1500 for VPN) | No fragmentation |
| **NET-009** | Internet outage simulation | All locations | Verify detection and failover | Alert within 2 min |

---

## 🚨 SolarWinds Monitoring & Alerting

### What SolarWinds Monitors

| Component | Metrics Monitored | Alert Threshold | Notification Method |
|-----------|-------------------|-----------------|---------------------|
| **Go Anywhere MFT Platform** | File transfer status, success/failure rate | Failure rate > 5% | Email, SMS, PagerDuty |
| **File Transfer Workflows** | Workflow execution time, errors | Duration > 10 min OR any error | Email, Slack |
| **Network Connectivity** | VPN status, bandwidth utilization | VPN down OR bandwidth > 80% | SMS, PagerDuty |
| **Storage (Go Anywhere Cloud)** | Disk usage, file count | Disk > 90% full | Email |
| **SFTP Connections** | Connection failures, auth failures | > 3 failures in 5 min | Email, SMS |
| **File Age** | Files not processed within SLA | File age > 2 hours | Email, Slack |

### SolarWinds Alert Examples

```
✅ SUCCESS NOTIFICATION:
Subject: File Transfer Success - CIF_Customer_Info_20250101.csv
Body:
  File: CIF_Customer_Info_20250101.csv
  Source: AWS Banking App
  Destination: \\<FILE_SERVER>\file_transfer\NBS
  Transfer Time: 45 seconds
  File Size: 12.5 MB
  Status: SUCCESS
  Next Step: BMC Control-M processing

❌ FAILURE NOTIFICATION:
Subject: URGENT - File Transfer Failed - Deposits_20250101.xlsx
Body:
  File: Deposits_20250101.xlsx
  Source: AWS Banking App
  Destination: \\<FILE_SERVER>\file_transfer\NBS
  Error: Connection timeout after 3 retries
  Retry Count: 3
  Last Attempt: 2025-01-01 10:35:22 UTC
  Status: FAILED
  Action Required: Check VPN connectivity and retry manually
  Runbook: https://wiki.example.com/file-transfer-failure

⚠️ WARNING NOTIFICATION:
Subject: Warning - File Transfer Delayed - Daily_MI_20250101.xlsx
Body:
  File: Daily_MI_20250101.xlsx
  Expected Time: 08:00 AM
  Current Time: 08:45 AM
  Delay: 45 minutes
  Status: PENDING
  Possible Cause: Network latency or source file not generated
  Action: Monitor for next 15 min, then investigate
```

---

## 🎯 Test Execution Responsibilities

### Team 1: AWS Team
- **Responsible for:** Tests AWS-001 through AWS-020
- **Tools:** AWS Console, AWS CLI, Boto3, Python scripts
- **Duration:** Week 1-2

### Team 2: MFT Team (Go Anywhere Specialists)
- **Responsible for:** Tests MFT-001 through MFT-020, GAC-001 through GAC-010
- **Tools:** Go Anywhere web console, SolarWinds, API scripts
- **Duration:** Week 2-4

### Team 3: On-Premise Team
- **Responsible for:** Tests PREM-001 through PREM-020
- **Tools:** BMC Control-M, PowerShell, Windows Event Viewer, SQL Server
- **Duration:** Week 3-5

### Team 4: Network Team
- **Responsible for:** Tests NET-001 through NET-010
- **Tools:** AWS Console, VPN monitoring, Wireshark, ping/traceroute
- **Duration:** Ongoing (parallel with other tests)

---

## ✅ Summary: Where to Test What

| Test Category | AWS | Go Anywhere MFT | On-Premise | Go Anywhere Cloud |
|---------------|-----|----------------|------------|-------------------|
| **File Generation** | ✅ | ❌ | ❌ | ❌ |
| **Anti-Malware Scanning** | ✅ | ⚠️ (optional) | ✅ | ❌ |
| **File Encryption** | ⚠️ (optional) | ✅ | ⚠️ (decryption) | ❌ |
| **File Transfer (AWS→On-Prem)** | ✅ (send) | ✅ (orchestrate) | ✅ (receive) | ❌ |
| **Virus Scanning (On-Prem)** | ❌ | ❌ | ✅ | ❌ |
| **BMC Control-M Processing** | ❌ | ❌ | ✅ | ❌ |
| **File Reformatting** | ❌ | ❌ | ✅ | ❌ |
| **SFTP to Go Anywhere Cloud** | ❌ | ❌ | ✅ (send) | ✅ (receive) |
| **Final Transfer to Agresso** | ❌ | ✅ | ❌ | ✅ |
| **SolarWinds Monitoring** | ⚠️ (integrated) | ✅ | ⚠️ (integrated) | ✅ |
| **Error Handling & Retry** | ✅ | ✅ | ✅ | ✅ |
| **Backup & Recovery** | ✅ | ✅ | ✅ | ✅ |

**Legend:**
- ✅ = Primary responsibility
- ⚠️ = Secondary/optional involvement
- ❌ = Not applicable

---

## 📞 Contact Information

| Team | Contact | Responsibilities |
|------|---------|------------------|
| **AWS Team** | aws-platform@example.com | File generation, AWS Transfer Family, Lambda functions |
| **MFT Team** | mft-team@example.com | Go Anywhere MFT, SolarWinds monitoring, file orchestration |
| **On-Premise Team** | on-prem-ops@example.com | File reception, BMC Control-M, file processing |
| **Network Team** | network-ops@example.com | VPN, Direct Connect, firewall, connectivity |
| **Agresso Team** | agresso-support@example.com | Final file reception, Agresso SFTP gateway |

---

**Document Version:** 1.0  
**Last Updated:** 2025-01-XX  
**Owner:** Platform Engineering Team  
**Review Date:** Quarterly

---

*This document clarifies the testing locations for the AWS-to-On-Premise file transfer architecture with Go Anywhere MFT and SolarWinds monitoring.*







# Diagram Recommendations for Your Presentation

## Your Situation
- **Current State**: Single region (eu-west-1, Ireland) - 10x core banking system constraint
- **Future State**: Potentially multi-region (but not now)
- **Presentation Focus**: Project 1 (WBDM-TST) - Web & Mobile Banking

---

## Available Diagrams

| Diagram | File | Focus | Best For |
|---------|------|-------|----------|
| **1-multi-region-overview** | 1-multi-region-overview.png | Primary + DR regions side-by-side | Future-state vision |
| **2-primary-ireland** | 2-primary-ireland-v2.drawio.png | Detailed single-region (3 AZs) | Current architecture |
| **3-dr-london** | 3-dr-london-v2.drawio.png | DR region in standby | Future DR strategy |
| **architectural-layout** | architectural layout.png | High-level overview | Quick reference |

---

## My Recommendation: Use 2 Diagrams

### **For Your 20-30 Minute Presentation:**

#### **Diagram 1: 2-primary-ireland-v2.drawio.png** ⭐ PRIMARY
**When to show**: Slide 3 (Architecture Overview) or Slide 4 (VPC Segregation)

**Why this one:**
- ✅ Shows your **current single-region design** (3 AZs)
- ✅ Detailed enough to explain VPC segregation
- ✅ Shows all 7 VPCs clearly
- ✅ Demonstrates multi-AZ distribution
- ✅ Directly supports your presentation narrative
- ✅ Assessors can see the actual architecture you designed

**What it shows:**
- All 7 VPCs with CIDR blocks
- 3 AZ distribution
- Transit Gateway connectivity
- Network Firewall placement
- All services (EKS, Aurora, MSK, etc.)
- Data flows

**Talking Points:**
"This is the current architecture for Stage 1. We're deploying in a single region (Ireland) with 3 availability zones due to the 10x core banking system constraint. You can see all 7 VPCs segregated by function, with the Network Firewall providing centralized inspection of all traffic."

---

#### **Diagram 2: 1-multi-region-overview.png** ⭐ SECONDARY (Optional)
**When to show**: Slide 6 (HA & DR) or as a closing slide

**Why this one:**
- ✅ Shows **future multi-region capability**
- ✅ Demonstrates forward-thinking architecture
- ✅ Shows how Stage 1 scales to Stages 2 & 3
- ✅ Addresses "future expansion" concern
- ✅ Shows DR strategy (warm standby in London)
- ✅ Impresses assessors with scalability thinking

**What it shows:**
- Primary region (Ireland) fully active
- DR region (London) in standby
- Failover automation
- Data replication flows
- Cost comparison (active vs. standby)
- RTO/RPO metrics

**Talking Points:**
"While Stage 1 is constrained to a single region due to the 10x system, the architecture is designed to support future multi-region expansion. This diagram shows how we would add a warm standby in London for disaster recovery, with automated failover and data replication. This supports our phased approach for Stages 2 and 3."

---

## Recommended Slide Placement

### **Option A: Detailed Single-Region Focus (Recommended)**

```
Slide 1: Business Challenge & Constraints (2 min)
Slide 2: Assessment Outcomes & Business Impact (1 min)
Slide 3: Architecture Overview (2 min)
         └─ Show: 2-primary-ireland-v2.drawio.png
Slide 4: VPC Segregation & Network Design (2.5 min)
         └─ Reference: Same diagram (zoomed in)
Slide 5: Security Architecture (2.5 min)
Slide 6: Integration Architecture (2 min)
Slide 7: HA & DR (2 min)
         └─ Show: 1-multi-region-overview.png (future state)
Slide 8: Cost & Operations (1.5 min)
Slide 9: Well-Architected Alignment (1 min)
```

**Total Time**: 15 minutes  
**Diagrams Used**: 2 (primary-ireland + multi-region-overview)  
**Impact**: Strong visual support for current and future architecture

---

### **Option B: Multi-Region Emphasis (If Future Expansion is Key)**

```
Slide 1: Business Challenge & Constraints (2 min)
Slide 2: Assessment Outcomes & Business Impact (1 min)
Slide 3: Architecture Overview (2 min)
         └─ Show: 1-multi-region-overview.png (high-level)
Slide 4: Stage 1 - Single Region Detail (2.5 min)
         └─ Show: 2-primary-ireland-v2.drawio.png
Slide 5: Security Architecture (2.5 min)
Slide 6: Integration Architecture (2 min)
Slide 7: HA & DR + Future Expansion (2 min)
         └─ Reference: 1-multi-region-overview.png
Slide 8: Cost & Operations (1.5 min)
Slide 9: Well-Architected Alignment (1 min)
```

**Total Time**: 15 minutes  
**Diagrams Used**: 2 (multi-region-overview + primary-ireland)  
**Impact**: Shows scalability and forward-thinking

---

## Why NOT to Use the Other Diagrams

### ❌ 3-dr-london-v2.drawio.png (DR Region)
**Why skip it:**
- Shows London region in standby (not relevant for Stage 1)
- Adds complexity without adding value
- Assessors will ask "why are you showing a region that's not deployed?"
- Takes up presentation time better used elsewhere
- The multi-region overview already shows the DR strategy

**When to use it:**
- Only if specifically asked about DR procedures
- In a follow-up discussion (not main presentation)
- If you have extra time and want to drill down on DR details

---

### ❌ architectural-layout.png (High-Level Overview)
**Why skip it:**
- Too high-level for a detailed architecture presentation
- Lacks the detail needed to explain VPC segregation
- Doesn't show CIDR blocks, AZ distribution, or services
- Better as a reference document, not a presentation slide

**When to use it:**
- As a handout or reference document
- In executive summary (if presenting to non-technical stakeholders)
- As a quick reference during Q&A

---

## My Strong Recommendation

### **Use These 2 Diagrams:**

1. **2-primary-ireland-v2.drawio.png** (Slide 3-4)
   - Your current single-region architecture
   - Detailed, shows all components
   - Directly supports your narrative

2. **1-multi-region-overview.png** (Slide 7)
   - Future multi-region capability
   - Shows scalability and forward-thinking
   - Addresses "what about expansion?" question

### **Skip:**
- 3-dr-london-v2.drawio.png (too detailed for Stage 1)
- architectural-layout.png (too high-level)

---

## How to Present the Diagrams

### **When Showing 2-primary-ireland-v2.drawio.png:**

**Talking Points (2-3 minutes):**

"This is the detailed architecture for Stage 1. Let me walk you through the key components:

**At the top**, we have CloudFront and WAF for edge security. Traffic flows through the Ingress VPC where we have ALBs and NLBs.

**In the middle**, all traffic is inspected by the Network Firewall in the Inspection VPC. This provides centralized control and audit logging.

**Below that**, we have the Workload VPC with our EKS cluster deployed across 3 availability zones. You can see the Aurora database with read replicas in each AZ, and MSK Kafka for event streaming.

**On the left**, the Hub VPC provides central routing and NAT gateways for internet egress.

**On the right**, the Data VPC contains our analytics services - Glue, Airflow, and S3 data lake.

**All VPCs are connected** through the Transit Gateway, with all cross-VPC traffic flowing through the Network Firewall for inspection.

This design ensures no single point of failure - any AZ can go down without impacting the system."

---

### **When Showing 1-multi-region-overview.png:**

**Talking Points (1-2 minutes):**

"While Stage 1 is constrained to a single region due to the 10x core banking system, the architecture is designed to support future expansion.

This diagram shows how we would add a warm standby in London (eu-west-2) for disaster recovery. The primary region in Ireland would be fully active, while the DR region would maintain read replicas of the database and replicated container images.

In the event of a regional failure, automated failover would:
1. Promote the Aurora read replica to a writer (< 30 seconds)
2. Scale up the EKS cluster in London (< 5 minutes)
3. Update Route 53 DNS to point to London (< 1 minute)
4. Total RTO: < 10 minutes

This approach supports our phased rollout - Stage 1 focuses on single-region resilience, Stage 2 adds warm standby, and Stage 3 could implement active-active multi-region."

---

## Visual Presentation Tips

### **For 2-primary-ireland-v2.drawio.png:**
- Display at full screen (it's detailed)
- Use a pointer or cursor to highlight sections as you explain
- Pause and let assessors read the CIDR blocks
- Point out the 3 AZ distribution
- Highlight the Network Firewall in the center

### **For 1-multi-region-overview.png:**
- Display at full screen
- Show the side-by-side comparison (Primary vs. DR)
- Point out the failover automation (Lambda, Route 53)
- Highlight the data replication flows
- Show the RTO/RPO metrics

---

## Alternative: If You Want to Use All 3

**Only if you have 30+ minutes:**

```
Slide 3: Architecture Overview (2 min)
         └─ Show: 1-multi-region-overview.png (high-level)

Slide 4: Stage 1 - Single Region Detail (3 min)
         └─ Show: 2-primary-ireland-v2.drawio.png

Slide 5: Security Architecture (2.5 min)

Slide 6: Integration Architecture (2 min)

Slide 7: HA & DR Strategy (2.5 min)
         └─ Show: 3-dr-london-v2.drawio.png (detailed DR)

Slide 8: Cost & Operations (1.5 min)

Slide 9: Well-Architected Alignment (1 min)

Slide 10: Future Expansion (Stages 2 & 3) (1 min)
```

**But this is too much for 20-30 minutes.** Stick with 2 diagrams.

---

## Final Recommendation Summary

| Aspect | Recommendation |
|--------|-----------------|
| **Primary Diagram** | 2-primary-ireland-v2.drawio.png |
| **Secondary Diagram** | 1-multi-region-overview.png |
| **Skip** | 3-dr-london-v2.drawio.png, architectural-layout.png |
| **Timing** | 2 diagrams fit perfectly in 15-minute presentation |
| **Impact** | Shows current architecture + future scalability |
| **Assessor Appeal** | Demonstrates forward-thinking design |

---

## How to Export/Use the Diagrams

### **For PowerPoint/Keynote:**
1. Open `2-primary-ireland-v2.drawio.png` in image viewer
2. Copy the image
3. Paste into your slide
4. Resize to fit (usually full slide)
5. Repeat for `1-multi-region-overview.png`

### **For PDF Presentation:**
1. Insert the PNG files directly into your PDF
2. One diagram per slide
3. Add your talking points as speaker notes

### **For Live Presentation:**
1. Have the diagrams open in separate tabs
2. Switch between them as needed
3. Use a pointer or cursor to highlight sections
4. Be ready to zoom in if asked about details

---

## Pro Tips

✅ **Practice with the diagrams** - Know what you're pointing to  
✅ **Have them ready** - Don't fumble with opening files  
✅ **Use them to support, not replace, your talking points** - You're the star, not the diagram  
✅ **Be ready for questions** - Assessors will ask about specific components  
✅ **Have the .drawio files available** - In case they want to see editable versions  

---

## Bottom Line

**Use 2 diagrams:**
1. **2-primary-ireland-v2.drawio.png** - Current single-region architecture (Slide 3-4)
2. **1-multi-region-overview.png** - Future multi-region capability (Slide 7)

This combination:
- ✅ Shows your current design in detail
- ✅ Demonstrates forward-thinking scalability
- ✅ Fits perfectly in 20-30 minute presentation
- ✅ Impresses assessors with both depth and breadth
- ✅ Addresses the "10x constraint" and "future expansion" naturally

Good luck! 🚀

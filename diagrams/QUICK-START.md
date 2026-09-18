# 🎨 Quick Start: Using Your Architecture Diagrams

## 📥 How to Import and Use

### Method 1: Online (Fastest - No Installation)

1. **Open Draw.io Online**
   ```
   https://app.diagrams.net/
   ```

2. **Import Your Diagram**
   - Click **"File"** → **"Open from"** → **"Device"**
   - Navigate to `diagrams/` folder
   - Select one of:
     - `multi-region-overview.drawio` (Start here!)
     - `primary-region-architecture.drawio`
     - `dr-region-architecture.drawio`

3. **View and Edit**
   - Zoom in/out with mouse wheel
   - Pan by clicking and dragging
   - Click any element to edit
   - Use search (Ctrl+F) to find components

4. **Export Your Diagram**
   - **PNG**: `File` → `Export as` → `PNG` → `Export`
   - **PDF**: `File` → `Export as` → `PDF` → `Export`
   - **SVG**: `File` → `Export as` → `SVG` → `Export`

---

### Method 2: VS Code Extension (Recommended for Developers)

1. **Install Extension**
   - Open VS Code
   - Press `Ctrl+Shift+X` (Extensions)
   - Search: `Draw.io Integration`
   - Click **Install**

2. **Open Diagram**
   - In VS Code, navigate to `diagrams/` folder
   - Click on any `.drawio` file
   - It opens inline in VS Code! 🎉

3. **Edit Inline**
   - Edit diagrams without leaving your IDE
   - Auto-saves as you work
   - Git integration built-in

---

### Method 3: Desktop App (Best for Heavy Editing)

1. **Download**
   ```
   https://github.com/jgraph/drawio-desktop/releases
   ```

2. **Install**
   - Windows: Run `.exe` installer
   - Mac: Open `.dmg` and drag to Applications
   - Linux: Use `.deb` or `.rpm` package

3. **Open Files**
   - File → Open
   - Navigate to your `diagrams/` folder
   - Open any `.drawio` file

---

## 🗺️ Which Diagram Should I Use?

### "I need to understand the whole architecture quickly"
**Use**: `multi-region-overview.drawio`
- High-level view of both regions
- Shows failover process
- Perfect for presentations

### "I need to deploy infrastructure in Ireland"
**Use**: `primary-region-architecture.drawio`
- Shows all 7 VPCs in detail
- Complete subnet layouts
- All services and connections

### "I need to set up disaster recovery"
**Use**: `dr-region-architecture.drawio`
- Shows London DR region
- Scaled-down configurations
- Auto-scaling indicators

### "I need all three!"
Import all three and compare side-by-side in Draw.io tabs!

---

## 💡 Pro Tips

### Tip 1: Search for Components
In Draw.io: Press `Ctrl+F` and search for:
- `Aurora` - Find all database instances
- `EKS` - Locate Kubernetes clusters
- `VPC` - Find all networks
- `Transit Gateway` - See connectivity hub

### Tip 2: Export High-Resolution
For documentation or presentations:
```
File → Export as → PNG
- Zoom: 300%
- Border: 20px
- Transparent: No
✅ Results in crisp, professional images
```

### Tip 3: Print Large Format
For war rooms or architecture reviews:
```
File → Print
- Paper Size: A3 or larger
- Fit: 1 page wide
- Orientation: Landscape
```

### Tip 4: Embed in Documentation
Export as SVG and embed in Markdown:
```markdown
![Architecture](diagrams/multi-region-overview.svg)
```

### Tip 5: Create Custom Views
1. Open diagram
2. Collapse/hide sections you don't need
3. Save as new file: `File → Save As`
4. Name it: `architecture-simplified.drawio`

---

## 🎯 Common Scenarios

### Scenario 1: "Show me what happens during a disaster"
1. Open: `multi-region-overview.drawio`
2. Look at bottom section: **"AUTOMATIC FAILOVER PROCESS"**
3. Follow arrows: 7 steps from health check fail to traffic flowing to DR
4. See timing: < 10 minutes total

### Scenario 2: "What VPCs do we have?"
1. Open: `primary-region-architecture.drawio`
2. See all 7 VPCs:
   - Hub (10.0.0.0/16)
   - Inspection (10.1.0.0/16)
   - Workload (10.2.0.0/16)
   - Ingress (10.3.0.0/16)
   - Data (10.4.0.0/16)
   - Shared Services (10.5.0.0/16)
   - Private Ingress (10.6.0.0/16)

### Scenario 3: "What's replicated to DR?"
1. Open: `multi-region-overview.drawio`
2. Look for **dashed blue arrows** between regions
3. See replication details:
   - Aurora: < 1 second
   - S3: ~15 minutes
   - Secrets Manager: Real-time
   - ECR: Automatic

### Scenario 4: "How much will DR cost?"
1. Open: `dr-region-architecture.drawio`
2. Look at **METRICS** section (bottom)
3. See costs:
   - Pilot Light: $150-240/month
   - Warm Standby: $920-1,440/month

---

## 📤 Exporting for Different Teams

### For Executive Presentations
```
Format: PDF
File: multi-region-overview.drawio
Settings:
  - Include: Title
  - Quality: High
  - Pages: 1
Perfect for: Board meetings, budget reviews
```

### For Technical Documentation
```
Format: PNG (300 DPI)
File: All three diagrams
Settings:
  - Zoom: 300%
  - Border: 20px
  - Background: White
Perfect for: Wiki, Confluence, SharePoint
```

### For Developer Portal
```
Format: SVG
File: primary-region-architecture.drawio
Settings:
  - Embed Images: Yes
  - Include Links: Yes
Perfect for: Internal documentation sites
```

### For Print (War Room)
```
Format: PDF
File: All diagrams
Settings:
  - Paper: A3 or A2
  - Orientation: Landscape
  - Fit: 1 page
Perfect for: Incident response, architecture reviews
```

---

## 🔧 Editing Tips

### Adding a New Service
1. Open relevant diagram
2. Click **"+"** button (left side)
3. Search: `AWS` → Find AWS icon library
4. Drag service icon onto diagram
5. Right-click → **Edit Style** → Match colors:
   - Compute: Orange (#D05C17)
   - Database: Blue (#3334B9)
   - Networking: Purple (#4D27AA)
   - Security: Red (#C7131F)

### Connecting Services
1. Click service icon
2. Hover over connection point (blue dot appears)
3. Drag to target service
4. Double-click arrow to add label

### Adding Notes
1. Click **Text** icon (toolbar)
2. Draw text box
3. Add your note
4. Style: `Font size 11, Color #666666`

---

## ❓ Troubleshooting

### "File won't open"
- **Solution**: Make sure you're using Draw.io (not another tool)
- **URL**: https://app.diagrams.net

### "Everything is too small"
- **Solution**: Use mouse wheel to zoom in
- **Or**: View → Zoom → Zoom In (Ctrl++)

### "I can't find a component"
- **Solution**: Use search (Ctrl+F)
- **Or**: Use layers panel (View → Layers)

### "Export is blurry"
- **Solution**: Increase zoom when exporting
- **Settings**: Export → PNG → Zoom: 300%

### "Colors look different"
- **Solution**: Ensure you're viewing in Draw.io
- **Note**: Some PDF readers alter colors

---

## 📚 Additional Resources

### Draw.io Documentation
- **Help Center**: https://www.diagrams.net/doc/
- **Video Tutorials**: https://www.youtube.com/drawioapp
- **Keyboard Shortcuts**: https://www.diagrams.net/shortcuts

### Our Documentation
- **Main README**: `../README.md`
- **DR Guide**: `../docs/DISASTER-RECOVERY.md`
- **Network Architecture**: `../docs/Network Architecture.md`

---

## 🎓 Learning Path

### Level 1: Viewer (5 minutes)
1. Open `multi-region-overview.drawio` online
2. Zoom around and explore
3. Understand primary vs DR
4. See failover process

### Level 2: Editor (15 minutes)
1. Install VS Code extension
2. Open a diagram
3. Edit a text label
4. Save and commit

### Level 3: Creator (30 minutes)
1. Learn AWS icon library
2. Add a new service
3. Connect it to existing services
4. Export and share

### Level 4: Expert (1 hour)
1. Create custom views
2. Add detailed annotations
3. Export in multiple formats
4. Maintain diagrams over time

---

## 🚀 Quick Actions

```bash
# Open online
https://app.diagrams.net/

# Clone repo and view locally
git clone <your-repo>
cd diagrams/
code multi-region-overview.drawio  # Opens in VS Code

# Export all to PNG (requires desktop app or CLI)
for file in *.drawio; do
  draw.io -x -f png -o "${file%.drawio}.png" "$file"
done
```

---

**Ready to explore your architecture?** Start with `multi-region-overview.drawio`! 🎉

**Need help?** Check the main `README.md` in this folder or the project documentation.

# Hospital360 Enterprise Power BI Inventory

**Status:** PBIP/PBIR implementation validated

## Semantic Model

- 12 enterprise tables: six dimensions and six facts.
- 45 enterprise measures in the existing `_Measures` table.
- Display folders: Enterprise Finance, Enterprise Workforce, Enterprise Operations, Enterprise IT.
- Dimension-to-fact, single-direction relationships; one inactive Resolved Date role.
- Fact-to-fact relationships: 0; bidirectional relationships: 0.
- Existing 46 healthcare measures modified: No.

## Pages Added

### Financial Performance

Date, Department, Organization, and Cost Category slicers; eight financial/budget KPIs; seven trend, concentration, mix, and variance visuals. Footer states that values are not real hospital financial statements.

### Workforce Performance

Date, Department, Organization, and Employee Role slicers; seven staffing/payroll KPIs; six department, trend, productivity, and role-mix visuals.

### Operations & Capacity

Date, Department, and Organization slicers; eight utilization/capacity KPIs; six occupancy, flow, wait, appointment, and capacity visuals. Bed measures are blank outside applicable departments.

### Technology Performance

Date, IT System, Organization, Incident Category, and Severity slicers; six reliability/incident KPIs; seven uptime, incident, SLA, downtime, resolution, and usage visuals.

## Navigation and Integrity

The existing Home grid was minimally extended from 8 to 12 proven navigation tiles. Every new page reuses the known-good Home button. Final automated checks: 13 total pages, 4 new pages, 12 Home actions, 45 enterprise measures, invalid JSON 0, broken bindings 0, navigation errors 0, and visuals outside canvas 0.

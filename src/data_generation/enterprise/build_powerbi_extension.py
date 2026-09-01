"""Build the version-controlled Power BI enterprise semantic/report extension.

The builder is deliberately allow-listed: it adds enterprise model objects and
four pages, while leaving all existing healthcare tables, measures, pages, and
relationships untouched.
"""

from __future__ import annotations

from copy import deepcopy
import json
from pathlib import Path
import re
import shutil
import uuid

from src.analytics.db import query_dataframe


ROOT = Path(__file__).resolve().parents[3]
MODEL = ROOT / "powerbi/Hospital360.SemanticModel/definition"
TABLES = MODEL / "tables"
REPORT = ROOT / "powerbi/Hospital360.Report/definition/pages"
NAMESPACE = uuid.UUID("ee29e2f2-0e4c-47f6-b588-624725d4c6d4")

ENTERPRISE_TABLES = (
    "dim_department", "dim_cost_category", "dim_budget_scenario",
    "dim_employee_role", "dim_it_system", "dim_incident_category",
    "fact_finance_monthly", "fact_budget_monthly", "fact_workforce_monthly",
    "fact_operations_daily", "fact_it_incident", "fact_it_system_daily",
)


def stable_id(value: str) -> str:
    return str(uuid.uuid5(NAMESPACE, value))


def tmdl_type(pg_type: str) -> str:
    if pg_type in {"smallint", "integer", "bigint"}:
        return "int64"
    if pg_type in {"numeric", "decimal", "real", "double precision"}:
        return "double"
    if pg_type == "boolean":
        return "boolean"
    if pg_type in {"date", "timestamp without time zone", "timestamp with time zone"}:
        return "dateTime"
    return "string"


def build_table_tmdl(table: str, columns: list[dict[str, object]]) -> str:
    entity = f"analytics {table}"
    lines = [f"table '{entity}'", f"\tlineageTag: {stable_id(entity)}", ""]
    for column in columns:
        name = str(column["column_name"])
        dtype = tmdl_type(str(column["data_type"]))
        lines.extend([
            f"\tcolumn {name}", f"\t\tdataType: {dtype}",
            *( ["\t\tformatString: 0"] if dtype == "int64" else [] ),
            f"\t\tlineageTag: {stable_id(entity+'.'+name)}",
            f"\t\tsummarizeBy: {'none' if dtype in {'string','dateTime','boolean'} or name.endswith('_key') else 'sum'}",
            f"\t\tsourceColumn: {name}", "", "\t\tannotation SummarizationSetBy = Automatic", "",
        ])
    lines.extend([
        f"\tpartition '{entity}' = m", "\t\tmode: import", "\t\tsource =", "\t\t\t\tlet",
        '\t\t\t\t    Source = PostgreSQL.Database("localhost", "hospital360"),',
        f'\t\t\t\t    analytics_{table} = Source{{[Schema="analytics",Item="{table}"]}}[Data]',
        "\t\t\t\tin", f"\t\t\t\t    analytics_{table}", "", "\tannotation PBI_ResultType = Table", "",
    ])
    return "\n".join(lines)


MEASURES: list[tuple[str, str, str, str]] = [
    ("Enterprise Revenue", "SUM('analytics fact_finance_monthly'[operating_revenue])", "$#,0.00", "Enterprise Finance"),
    ("Enterprise Operating Cost", "SUM('analytics fact_finance_monthly'[operating_cost])", "$#,0.00", "Enterprise Finance"),
    ("Enterprise Operating Margin", "[Enterprise Revenue] - [Enterprise Operating Cost]", "$#,0.00", "Enterprise Finance"),
    ("Enterprise Operating Margin %", "DIVIDE([Enterprise Operating Margin],[Enterprise Revenue])", "0.00%", "Enterprise Finance"),
    ("Budget Revenue", "CALCULATE(SUM('analytics fact_budget_monthly'[budget_revenue]),'analytics dim_budget_scenario'[budget_scenario_code]=\"ORIGINAL\")", "$#,0.00", "Enterprise Finance"),
    ("Budget Cost", "CALCULATE(SUM('analytics fact_budget_monthly'[budget_operating_cost]),'analytics dim_budget_scenario'[budget_scenario_code]=\"ORIGINAL\")", "$#,0.00", "Enterprise Finance"),
    ("Revenue Variance", "[Enterprise Revenue]-[Budget Revenue]", "$#,0.00", "Enterprise Finance"),
    ("Cost Variance", "[Enterprise Operating Cost]-[Budget Cost]", "$#,0.00", "Enterprise Finance"),
    ("Budget Variance", "[Enterprise Operating Margin]-([Budget Revenue]-[Budget Cost])", "$#,0.00", "Enterprise Finance"),
    ("Budget Variance %", "DIVIDE([Budget Variance],ABS([Budget Revenue]-[Budget Cost]))", "0.00%", "Enterprise Finance"),
    ("Enterprise Cost per Encounter", "DIVIDE([Enterprise Operating Cost],[Enterprise Encounter Volume])", "$#,0.00", "Enterprise Finance"),
    ("Enterprise Revenue per Encounter", "DIVIDE([Enterprise Revenue],[Enterprise Encounter Volume])", "$#,0.00", "Enterprise Finance"),
    ("Enterprise Payroll Cost", "SUM('analytics fact_finance_monthly'[payroll_cost])", "$#,0.00", "Enterprise Finance"),
    ("Enterprise Payroll Cost %", "DIVIDE([Enterprise Payroll Cost],[Enterprise Operating Cost])", "0.00%", "Enterprise Finance"),
    ("Enterprise Supplies Cost", "SUM('analytics fact_finance_monthly'[supplies_cost])", "$#,0.00", "Enterprise Finance"),
    ("Department Cost Share", "DIVIDE([Enterprise Operating Cost],CALCULATE([Enterprise Operating Cost],REMOVEFILTERS('analytics dim_department')))", "0.00%", "Enterprise Finance"),
    ("Enterprise Headcount", "VAR k=MAX('analytics fact_workforce_monthly'[month_start_date_key]) RETURN CALCULATE(SUM('analytics fact_workforce_monthly'[headcount]),'analytics fact_workforce_monthly'[month_start_date_key]=k)", "#,0", "Enterprise Workforce"),
    ("Enterprise FTE", "VAR k=MAX('analytics fact_workforce_monthly'[month_start_date_key]) RETURN CALCULATE(SUM('analytics fact_workforce_monthly'[fte]),'analytics fact_workforce_monthly'[month_start_date_key]=k)", "#,0.00", "Enterprise Workforce"),
    ("Workforce Payroll Cost", "SUM('analytics fact_workforce_monthly'[payroll_cost])", "$#,0.00", "Enterprise Workforce"),
    ("Overtime Hours", "SUM('analytics fact_workforce_monthly'[overtime_hours])", "#,0.00", "Enterprise Workforce"),
    ("Absence Rate", "DIVIDE(SUM('analytics fact_workforce_monthly'[absence_hours]),SUM('analytics fact_workforce_monthly'[scheduled_hours]))", "0.00%", "Enterprise Workforce"),
    ("Turnover Rate", "DIVIDE(SUM('analytics fact_workforce_monthly'[turnover_count]),SUM('analytics fact_workforce_monthly'[average_headcount]))", "0.00%", "Enterprise Workforce"),
    ("Vacancy Count", "SUM('analytics fact_workforce_monthly'[vacancy_count])", "#,0", "Enterprise Workforce"),
    ("Encounters per FTE", "DIVIDE([Enterprise Encounter Volume],SUM('analytics fact_workforce_monthly'[average_fte]))", "#,0.00", "Enterprise Workforce"),
    ("Payroll Cost per FTE", "DIVIDE([Workforce Payroll Cost],SUM('analytics fact_workforce_monthly'[average_fte]))", "$#,0.00", "Enterprise Workforce"),
    ("Admissions", "SUM('analytics fact_operations_daily'[admissions])", "#,0", "Enterprise Operations"),
    ("Discharges", "SUM('analytics fact_operations_daily'[discharges])", "#,0", "Enterprise Operations"),
    ("Available Beds", "AVERAGE('analytics fact_operations_daily'[available_beds])", "#,0.00", "Enterprise Operations"),
    ("Occupied Beds", "AVERAGE('analytics fact_operations_daily'[occupied_beds])", "#,0.00", "Enterprise Operations"),
    ("Occupancy Rate", "DIVIDE(SUM('analytics fact_operations_daily'[occupied_bed_days]),SUM('analytics fact_operations_daily'[available_bed_days]))", "0.00%", "Enterprise Operations"),
    ("Average Length of Stay", "DIVIDE(SUM('analytics fact_operations_daily'[length_of_stay_days_total]),SUM('analytics fact_operations_daily'[discharged_with_los_count]))", "#,0.00", "Enterprise Operations"),
    ("Bed Turnover", "DIVIDE([Discharges],[Available Beds])", "#,0.00", "Enterprise Operations"),
    ("Waiting Time", "DIVIDE(SUM('analytics fact_operations_daily'[wait_minutes_total]),SUM('analytics fact_operations_daily'[waited_encounter_count]))", "#,0.00", "Enterprise Operations"),
    ("Appointment Completion %", "DIVIDE(SUM('analytics fact_operations_daily'[appointments_completed]),SUM('analytics fact_operations_daily'[appointments_scheduled]))", "0.00%", "Enterprise Operations"),
    ("Enterprise Throughput", "SUM('analytics fact_operations_daily'[throughput])", "#,0", "Enterprise Operations"),
    ("Enterprise Encounter Volume", "SUM('analytics fact_operations_daily'[encounter_count])", "#,0", "Enterprise Operations"),
    ("Incident Count", "COUNTROWS('analytics fact_it_incident')", "#,0", "Enterprise IT"),
    ("Critical Incidents", "CALCULATE([Incident Count],'analytics fact_it_incident'[severity]=\"P1\")", "#,0", "Enterprise IT"),
    ("Uptime %", "DIVIDE(SUM('analytics fact_it_system_daily'[available_minutes]),SUM('analytics fact_it_system_daily'[scheduled_minutes]))", "0.00%", "Enterprise IT"),
    ("Downtime Minutes", "SUM('analytics fact_it_system_daily'[downtime_minutes])", "#,0", "Enterprise IT"),
    ("SLA Compliance %", "DIVIDE(CALCULATE([Incident Count],'analytics fact_it_incident'[sla_met_flag]=TRUE()),CALCULATE([Incident Count],NOT ISBLANK('analytics fact_it_incident'[resolved_at])))", "0.00%", "Enterprise IT"),
    ("Mean Resolution Time", "AVERAGE('analytics fact_it_incident'[resolution_minutes])", "#,0.00", "Enterprise IT"),
    ("IT Error Rate", "DIVIDE(SUM('analytics fact_it_system_daily'[error_count]),SUM('analytics fact_it_system_daily'[transaction_count]))", "0.00%", "Enterprise IT"),
    ("System Transaction Volume", "SUM('analytics fact_it_system_daily'[transaction_count])", "#,0", "Enterprise IT"),
    ("Incidents per 10K Transactions", "DIVIDE([Incident Count]*10000,[System Transaction Volume])", "#,0.00", "Enterprise IT"),
]


RELATIONSHIPS = {
    "fact_finance_monthly": (("month_start_date_key","dim_date","date_key",True),("organization_key","dim_organization","organization_key",True),("department_key","dim_department","department_key",True),("cost_category_key","dim_cost_category","cost_category_key",True)),
    "fact_budget_monthly": (("month_start_date_key","dim_date","date_key",True),("organization_key","dim_organization","organization_key",True),("department_key","dim_department","department_key",True),("budget_scenario_key","dim_budget_scenario","budget_scenario_key",True)),
    "fact_workforce_monthly": (("month_start_date_key","dim_date","date_key",True),("organization_key","dim_organization","organization_key",True),("department_key","dim_department","department_key",True),("employee_role_key","dim_employee_role","employee_role_key",True)),
    "fact_operations_daily": (("date_key","dim_date","date_key",True),("organization_key","dim_organization","organization_key",True),("department_key","dim_department","department_key",True)),
    "fact_it_incident": (("opened_date_key","dim_date","date_key",True),("resolved_date_key","dim_date","date_key",False),("organization_key","dim_organization","organization_key",True),("department_key","dim_department","department_key",True),("it_system_key","dim_it_system","it_system_key",True),("incident_category_key","dim_incident_category","incident_category_key",True)),
    "fact_it_system_daily": (("date_key","dim_date","date_key",True),("organization_key","dim_organization","organization_key",True),("it_system_key","dim_it_system","it_system_key",True)),
}


def build_semantic_model() -> None:
    metadata = query_dataframe("SELECT table_name,column_name,data_type,ordinal_position FROM information_schema.columns WHERE table_schema='analytics' AND table_name LIKE 'dim_%' OR table_schema='analytics' AND table_name LIKE 'fact_%' ORDER BY table_name,ordinal_position")
    for table in ENTERPRISE_TABLES:
        rows = metadata.loc[metadata.table_name.eq(table)].to_dict("records")
        if not rows:
            raise RuntimeError(f"No analytics metadata found for {table}")
        (TABLES / f"analytics {table}.tmdl").write_text(build_table_tmdl(table, rows), encoding="utf-8")

    model_path = MODEL / "model.tmdl"
    model = model_path.read_text(encoding="utf-8")
    for table in ENTERPRISE_TABLES:
        ref = f"ref table 'analytics {table}'"
        if ref not in model:
            model = model.replace("ref table _Measures", f"{ref}\nref table _Measures")
    order_match = re.search(r"annotation PBI_QueryOrder = (\[[^\n]+\])", model)
    if order_match:
        order = json.loads(order_match.group(1))
        for table in ENTERPRISE_TABLES:
            entity = f"analytics {table}"
            if entity not in order:
                order.append(entity)
        model = model[:order_match.start(1)] + json.dumps(order, separators=(",",":")) + model[order_match.end(1):]
    model_path.write_text(model, encoding="utf-8")

    measures_path = TABLES / "_Measures.tmdl"
    measures = measures_path.read_text(encoding="utf-8").rstrip() + "\n"
    for name, dax, fmt, folder in MEASURES:
        if f"\tmeasure '{name}' =" in measures:
            continue
        measures += f"\n\tmeasure '{name}' =\n\t\t\t{dax}\n\t\tformatString: {fmt}\n\t\tdisplayFolder: {folder}\n\t\tlineageTag: {stable_id('measure.'+name)}\n"
    measures_path.write_text(measures, encoding="utf-8")

    relationships_path = MODEL / "relationships.tmdl"
    relationships = relationships_path.read_text(encoding="utf-8").rstrip() + "\n"
    for fact, mappings in RELATIONSHIPS.items():
        for from_col, dim, to_col, active in mappings:
            rid = stable_id(f"relationship.{fact}.{from_col}.{dim}.{to_col}")
            if f"relationship {rid}" in relationships:
                continue
            relationships += f"\nrelationship {rid}\n"
            if not active:
                relationships += "\tisActive: false\n"
            relationships += f"\tfromColumn: 'analytics {fact}'.{from_col}\n\ttoColumn: 'analytics {dim}'.{to_col}\n\n\tannotation PBI_IsFromSource = FS\n"
    relationships_path.write_text(relationships, encoding="utf-8")


def literal(value: str) -> dict:
    return {"expr": {"Literal": {"Value": f"'{value}'"}}}


def set_title(visual: dict, title: str) -> None:
    objects = visual["visual"].setdefault("visualContainerObjects", {})
    objects["title"] = [{"properties": {"show": {"expr":{"Literal":{"Value":"true"}}}, "text": literal(title), "fontSize":{"expr":{"Literal":{"Value":"13D"}}}, "bold":{"expr":{"Literal":{"Value":"true"}}}, "fontColor":{"solid":{"color":literal("#0F4C45")}}, "alignment":literal("center")}}]


def projection(entity: str, prop: str, kind: str = "Measure") -> dict:
    return {"field": {kind: {"Expression": {"SourceRef": {"Entity": entity}}, "Property": prop}}, "queryRef": f"{entity}.{prop}", "nativeQueryRef": prop}


def build_report() -> None:
    exec_visuals = REPORT / "6f0c1a2b3d4e5f708192/visuals"
    template = {
        "card": json.loads((exec_visuals/"10000000000000000006/visual.json").read_text(encoding="utf-8-sig")),
        "slicer": json.loads((exec_visuals/"10000000000000000002/visual.json").read_text(encoding="utf-8-sig")),
        "line": json.loads((exec_visuals/"1000000000000000000c/visual.json").read_text(encoding="utf-8-sig")),
        "text": json.loads((exec_visuals/"10000000000000000001/visual.json").read_text(encoding="utf-8-sig")),
        "home": json.loads((exec_visuals/"30000000000000000100/visual.json").read_text(encoding="utf-8-sig")),
        "home_icon": json.loads((exec_visuals/"30000000000000000102/visual.json").read_text(encoding="utf-8-sig")),
        "bar": json.loads((REPORT/"6f0c1a2b3d4e5f708194/visuals/40000000000000000020/visual.json").read_text(encoding="utf-8-sig")),
        "column": json.loads((REPORT/"6f0c1a2b3d4e5f708195/visuals/50000000000000000020/visual.json").read_text(encoding="utf-8-sig")),
    }
    pages = [
      ("6f0c1a2b3d4e5f70819b","Financial Performance",[("Date","analytics dim_date","full_date"),("Department","analytics dim_department","department_name"),("Organization","analytics dim_organization","organization_name"),("Cost Category","analytics dim_cost_category","cost_category_name")],["Enterprise Revenue","Enterprise Operating Cost","Enterprise Operating Margin","Enterprise Operating Margin %","Budget Revenue","Budget Cost","Budget Variance","Enterprise Cost per Encounter"],[("Monthly Revenue vs Budget","line","analytics dim_date","year_month",["Enterprise Revenue","Budget Revenue"]),("Monthly Operating Cost vs Budget","line","analytics dim_date","year_month",["Enterprise Operating Cost","Budget Cost"]),("Operating Margin Trend","line","analytics dim_date","year_month",["Enterprise Operating Margin"]),("Revenue by Department","bar","analytics dim_department","department_name",["Enterprise Revenue"]),("Operating Cost by Department","bar","analytics dim_department","department_name",["Enterprise Operating Cost"]),("Cost Category Mix","column","analytics dim_cost_category","cost_category_name",["Enterprise Operating Cost"]),("Department Budget Variance","bar","analytics dim_department","department_name",["Budget Variance"])],"Synthetic enterprise financial data • Not real hospital financial statements"),
      ("6f0c1a2b3d4e5f70819c","Workforce Performance",[("Date","analytics dim_date","full_date"),("Department","analytics dim_department","department_name"),("Organization","analytics dim_organization","organization_name"),("Employee Role","analytics dim_employee_role","employee_role_name")],["Enterprise Headcount","Enterprise FTE","Workforce Payroll Cost","Overtime Hours","Absence Rate","Turnover Rate","Encounters per FTE"],[("FTE by Department","bar","analytics dim_department","department_name",["Enterprise FTE"]),("Payroll by Department","bar","analytics dim_department","department_name",["Workforce Payroll Cost"]),("Overtime Trend","line","analytics dim_date","year_month",["Overtime Hours"]),("Absence Trend","line","analytics dim_date","year_month",["Absence Rate"]),("Encounters per FTE","bar","analytics dim_department","department_name",["Encounters per FTE"]),("Employee Role Mix","column","analytics dim_employee_role","employee_role_name",["Enterprise FTE"])],"Synthetic workforce data • Associations do not establish causation"),
      ("6f0c1a2b3d4e5f70819d","Operations & Capacity",[("Date","analytics dim_date","full_date"),("Department","analytics dim_department","department_name"),("Organization","analytics dim_organization","organization_name")],["Admissions","Discharges","Occupancy Rate","Average Length of Stay","Available Beds","Occupied Beds","Waiting Time","Appointment Completion %"],[("Occupancy Trend","line","analytics dim_date","year_month",["Occupancy Rate"]),("Admissions vs Discharges","line","analytics dim_date","year_month",["Admissions","Discharges"]),("Occupancy by Department","bar","analytics dim_department","department_name",["Occupancy Rate"]),("Waiting Time by Department","bar","analytics dim_department","department_name",["Waiting Time"]),("Appointment Completion","column","analytics dim_department","department_name",["Appointment Completion %"]),("Capacity Utilization","line","analytics dim_date","year_month",["Occupancy Rate","Enterprise Throughput"])],"Synthetic operational data • Bed metrics apply only to relevant departments"),
      ("6f0c1a2b3d4e5f70819e","Technology Performance",[("Date","analytics dim_date","full_date"),("IT System","analytics dim_it_system","it_system_name"),("Organization","analytics dim_organization","organization_name"),("Incident Category","analytics dim_incident_category","incident_category_name"),("Severity","analytics fact_it_incident","severity")],["Uptime %","Downtime Minutes","Incident Count","Critical Incidents","SLA Compliance %","Mean Resolution Time"],[("Uptime by System","bar","analytics dim_it_system","it_system_name",["Uptime %"]),("Incident Trend","line","analytics dim_date","year_month",["Incident Count"]),("Incidents by Severity","column","analytics fact_it_incident","severity",["Incident Count"]),("SLA Compliance by System","bar","analytics dim_it_system","it_system_name",["SLA Compliance %"]),("Downtime by System","bar","analytics dim_it_system","it_system_name",["Downtime Minutes"]),("Resolution Time Trend","line","analytics dim_date","year_month",["Mean Resolution Time"]),("System Usage Trend","line","analytics dim_date","year_month",["System Transaction Volume"])],"Synthetic technology operations data • Incidents do not represent a real hospital"),
    ]

    metadata_path = REPORT / "pages.json"
    metadata = json.loads(metadata_path.read_text(encoding="utf-8-sig"))
    for page_id, display, slicers, cards, charts, footer in pages:
        page_dir = REPORT / page_id
        visuals_dir = page_dir / "visuals"
        if page_dir.exists():
            shutil.rmtree(page_dir)
        visuals_dir.mkdir(parents=True)
        page = json.loads((REPORT/"6f0c1a2b3d4e5f708192/page.json").read_text(encoding="utf-8-sig"))
        page["name"], page["displayName"] = page_id, display
        (page_dir/"page.json").write_text(json.dumps(page,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
        counter=0
        def add(obj: dict, x: int,y: int,w: int,h: int) -> None:
            nonlocal counter
            counter+=1; name=f"e{page_id[-2:]}{counter:017d}"[-20:]
            obj=deepcopy(obj); obj["name"]=name; obj["position"].update({"x":x,"y":y,"width":w,"height":h,"z":1000+counter,"tabOrder":counter})
            target=visuals_dir/name; target.mkdir(); (target/"visual.json").write_text(json.dumps(obj,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
        title=deepcopy(template["text"]); title["visual"]["objects"]["general"][0]["properties"]["paragraphs"][0]["textRuns"][0]["value"]=display
        add(title,82,18,650,54); add(template["home"],24,24,44,44); add(template["home_icon"],24,25,44,42)
        sw=280 if len(slicers)<=4 else 220
        sx=1920-len(slicers)*(sw+12)-24
        for i,(label,entity,col) in enumerate(slicers):
            v=deepcopy(template["slicer"]); p=projection(entity,col,"Column"); p["active"]=True; v["visual"]["query"]={"queryState":{"Values":{"projections":[p]}}}; v["visual"]["objects"]["header"][0]["properties"]["text"]=literal(label)
            if label!="Date": v["visual"]["objects"].pop("data",None)
            add(v,sx+i*(sw+12),18,sw,76)
        card_w=(1856-(len(cards)-1)*12)//len(cards)
        for i,measure in enumerate(cards):
            v=deepcopy(template["card"]); v["visual"]["query"]["queryState"]["Data"]["projections"]=[projection("_Measures",measure)]; add(v,32+i*(card_w+12),118,card_w,128)
        positions=[]
        top=charts[:4]; bottom=charts[4:]
        for i in range(len(top)): positions.append((32+i*464,270,448,342))
        bw=(1856-(len(bottom)-1)*16)//max(len(bottom),1)
        for i in range(len(bottom)): positions.append((32+i*(bw+16),632,bw,350))
        for chart,(x,y,w,h) in zip(charts,positions):
            title_text,kind,entity,col,measures=chart; v=deepcopy(template[kind]); v.pop("filterConfig",None)
            category=projection(entity,col,"Column"); category["active"]=True
            yproj=[projection("_Measures",m) for m in measures]
            q=v["visual"].setdefault("query",{}); q["queryState"]={"Category":{"projections":[category]},"Y":{"projections":yproj}}; q["sortDefinition"]={"sort":[{"field":category["field"],"direction":"Ascending"}],"isDefaultSort":True}; set_title(v,title_text); add(v,x,y,w,h)
        foot=deepcopy(template["text"]); run=foot["visual"]["objects"]["general"][0]["properties"]["paragraphs"][0]["textRuns"][0]; run["value"]=footer; run["textStyle"].update({"fontSize":"10px","color":"#667085"}); add(foot,32,1004,1856,40)
        if page_id not in metadata["pageOrder"]: metadata["pageOrder"].append(page_id)
    metadata_path.write_text(json.dumps(metadata,indent=2)+"\n",encoding="utf-8")


def extend_home_navigation() -> None:
    """Resize the existing tile grid and add four enterprise destinations."""
    visuals = REPORT / "6f0c1a2b3d4e5f708193/visuals"
    existing_shapes = [f"3000000000000000000{i}" for i in range(3, 10)] + ["30000000000000000010"]
    existing_texts = [f"300000000000000000{i}" for i in range(11, 19)]
    existing_buttons = ["30000000000000000019"] + [f"3100000000000000000{i}" for i in range(1, 8)]
    xs = [90, 535, 980, 1425]
    ys = [240, 445, 650]
    for i, (shape_id, text_id, button_id) in enumerate(zip(existing_shapes, existing_texts, existing_buttons)):
        row, col = divmod(i, 4)
        for visual_id, x, y, w, h in ((shape_id,xs[col],ys[row],405,180),(button_id,xs[col],ys[row],405,180),(text_id,xs[col]+20,ys[row]+34,365,110)):
            path=visuals/visual_id/"visual.json"; obj=json.loads(path.read_text(encoding="utf-8-sig")); obj["position"].update({"x":x,"y":y,"width":w,"height":h}); path.write_text(json.dumps(obj,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")
    shape_template=json.loads((visuals/existing_shapes[0]/"visual.json").read_text(encoding="utf-8-sig"))
    text_template=json.loads((visuals/existing_texts[0]/"visual.json").read_text(encoding="utf-8-sig"))
    button_template=json.loads((visuals/existing_buttons[0]/"visual.json").read_text(encoding="utf-8-sig"))
    destinations=[("Financial Performance","6f0c1a2b3d4e5f70819b"),("Workforce Performance","6f0c1a2b3d4e5f70819c"),("Operations & Capacity","6f0c1a2b3d4e5f70819d"),("Technology Performance","6f0c1a2b3d4e5f70819e")]
    for col,(label,destination) in enumerate(destinations):
        specs=((f"3200000000000000000{col+1}",shape_template,xs[col],ys[2],405,180),(f"3200000000000000000{col+5}",text_template,xs[col]+20,ys[2]+34,365,110),(f"320000000000000000{col+9:02d}",button_template,xs[col],ys[2],405,180))
        for visual_id,source,x,y,w,h in specs:
            target=visuals/visual_id; target.mkdir(exist_ok=True); obj=deepcopy(source); obj["name"]=visual_id; obj["position"].update({"x":x,"y":y,"width":w,"height":h,"z":220+col,"tabOrder":30+col})
            if obj["visual"]["visualType"]=="textbox": obj["visual"]["objects"]["general"][0]["properties"]["paragraphs"][0]["textRuns"][0]["value"]=label
            if obj["visual"]["visualType"]=="actionButton":
                link=obj["visual"]["visualContainerObjects"]["visualLink"][0]["properties"]; link["navigationSection"]=literal(destination); link["tooltip"]=literal(f"Open {label}")
            (target/"visual.json").write_text(json.dumps(obj,indent=2,ensure_ascii=False)+"\n",encoding="utf-8")


if __name__ == "__main__":
    build_semantic_model()
    build_report()
    extend_home_navigation()
    print("Enterprise Power BI extension generated")

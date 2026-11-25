"""Create the polished two-page storyboard PDF (requires ReportLab)."""
from pathlib import Path
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, KeepTogether

ROOT = Path(__file__).resolve().parent
OUT = ROOT / "Storyboard.pdf"
NAVY = colors.HexColor("#10243A")
BLUE = colors.HexColor("#155A78")
CYAN = colors.HexColor("#27B8CB")
PALE = colors.HexColor("#EAF5F7")
CORAL = colors.HexColor("#D95D51")
INK = colors.HexColor("#233548")
MUTED = colors.HexColor("#586B7C")

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name="ProjectTitle", parent=styles["Title"], fontName="Helvetica-Bold", fontSize=25, leading=29,
                          textColor=NAVY, alignment=TA_LEFT, spaceAfter=5))
styles.add(ParagraphStyle(name="SubtitleCustom", parent=styles["Normal"], fontSize=10, leading=14, textColor=MUTED, spaceAfter=10))
styles.add(ParagraphStyle(name="SceneTitle", parent=styles["Heading2"], fontName="Helvetica-Bold", fontSize=13, leading=16, textColor=BLUE, spaceAfter=3))
styles.add(ParagraphStyle(name="BodyCustom", parent=styles["BodyText"], fontSize=9.2, leading=13, textColor=INK, spaceAfter=3))
styles.add(ParagraphStyle(name="MathCustom", parent=styles["BodyText"], fontSize=9.2, leading=13, textColor=BLUE, spaceAfter=0))
styles.add(ParagraphStyle(name="SmallLabel", parent=styles["Normal"], fontName="Helvetica-Bold", fontSize=7.5, leading=9, textColor=CORAL))

scenes = [
    ("1 · HOOK", "0:05-0:48", "A car drives along the road with spinning wheels and motion streaks. Live time and distance counters tick up as the question <b>How fast right now?</b> appears.", "Average speed = distance ÷ time = 60 ÷ 3 = 20 metres per second. Ask how speed can be measured at one instant."),
    ("2 · INTRODUCTION", "0:48-1:34", "Axes and the parabola <b>y = x²</b> draw progressively as a pulsing point sweeps along the curve and its coordinates update.", "Define f(x) = x² and identify A = (1, 1). The learning goal is to find the exact slope at x = 1."),
    ("3 · VISUAL INTUITION", "1:34-2:21", "Point B travels along the curve toward A. The secant rotates while the run h and rise change; the tangent direction becomes visible.", "Secant slope = [f(1+h) − f(1)] / h. This is the average rate over an interval, where h ≠ 0."),
    ("4 · WORKED DERIVATION", "2:21-3:07", "The algebra writes one line at a time as the secant moves. Values for h = 1, 0.5, and 0.1 appear beside the graph.", "[(1+h)² − 1] / h = [1+2h+h²−1] / h = [2h+h²] / h = h(2+h)/h = 2+h. Cancel h only while h ≠ 0. The sample slopes are 3, 2.5, and 2.1."),
    ("5 · INTERPRETATION", "3:07-4:00", "The secant settles into the green tangent at A. A rise-and-run marker and derivative notation connect the graph to the result.", "As h approaches zero, 2+h approaches 2. Thus f′(1)=2, and for f(x)=x², f′(x)=2x."),
    ("6 · SUMMARY & CREDITS", "4:00-4:56", "Three animated takeaways move through SECANT → LIMIT → TANGENT. Math, music, and AI credits finish with the progress line.", "A secant measures average change, the limit brings points together, and the tangent gives instantaneous slope."),
]

def scene_card(scene):
    title, timing, visual, math = scene
    inner = [Paragraph(f"{title} <font color='#D95D51'>· {timing}</font>", styles["SceneTitle"]),
             Paragraph("<b>VISUAL</b>  " + visual, styles["BodyCustom"]),
             Paragraph("<b>MATHEMATICS</b>  " + math, styles["MathCustom"])]
    card = Table([[inner]], colWidths=[7.15*inch])
    card.setStyle(TableStyle([
        ("BACKGROUND", (0,0),(-1,-1), colors.white), ("BOX", (0,0),(-1,-1), .6, colors.HexColor("#CFDCE5")),
        ("LINEBEFORE", (0,0),(0,-1), 4, CYAN), ("LEFTPADDING",(0,0),(-1,-1),12), ("RIGHTPADDING",(0,0),(-1,-1),12),
        ("TOPPADDING",(0,0),(-1,-1),9), ("BOTTOMPADDING",(0,0),(-1,-1),9),
    ]))
    return KeepTogether([card, Spacer(1, 10)])

def page_decor(canvas, doc):
    canvas.saveState()
    w,h = letter
    canvas.setFillColor(NAVY); canvas.rect(0,h-12,w,12,stroke=0,fill=1)
    canvas.setStrokeColor(colors.HexColor("#D9E4EB")); canvas.line(doc.leftMargin, 37, w-doc.rightMargin, 37)
    canvas.setFont("Helvetica", 8); canvas.setFillColor(MUTED)
    canvas.drawString(doc.leftMargin, 24, "MATH IN MOTION  /  DERIVATIVES")
    canvas.drawRightString(w-doc.rightMargin, 24, f"STORYBOARD  ·  {doc.page}")
    canvas.restoreState()

doc = SimpleDocTemplate(str(OUT), pagesize=letter, rightMargin=.68*inch, leftMargin=.68*inch,
                        topMargin=.55*inch, bottomMargin=.65*inch, title="Derivative: Instantaneous Rate of Change - Storyboard",
                        author="Mathematics Animation Project")
story = [Paragraph("Derivative: Instantaneous Rate of Change", styles["ProjectTitle"]),
         Paragraph("SIX-SCENE STORYBOARD  ·  4:56 ANIMATED VIDEO  ·  NATURAL-PACE NARRATION + QUIET ORIGINAL MUSIC", styles["SubtitleCustom"]),
         Spacer(1, 4)]
objective = Table([[Paragraph("LEARNING OBJECTIVE", styles["SmallLabel"]),
                    Paragraph("See how a secant slope approaches the tangent slope, giving the instantaneous rate of change.", styles["BodyCustom"])]],
                  colWidths=[1.45*inch, 5.7*inch])
objective.setStyle(TableStyle([("BACKGROUND",(0,0),(-1,-1),PALE), ("BOX",(0,0),(-1,-1),.6,CYAN),
                               ("VALIGN",(0,0),(-1,-1),"MIDDLE"), ("LEFTPADDING",(0,0),(-1,-1),10),
                               ("RIGHTPADDING",(0,0),(-1,-1),10), ("TOPPADDING",(0,0),(-1,-1),8),
                               ("BOTTOMPADDING",(0,0),(-1,-1),8)]))
story += [objective, Spacer(1, 12)]
story.extend(scene_card(s) for s in scenes[:4])
story += [PageBreak(), Paragraph("From secant to tangent", styles["ProjectTitle"]),
          Paragraph("The final two scenes interpret the limit and recap the key result.", styles["SubtitleCustom"]),
          Spacer(1, 4)]
story.extend(scene_card(s) for s in scenes[4:])
formula = Table([[Paragraph("WORKED EXAMPLE", styles["SmallLabel"])],
                 [Paragraph("f(x) = x²  ·  f′(x) = 2x  ·  f′(1) = 2", styles["SceneTitle"])],
                 [Paragraph("[(1+h)² − 1] / h = (2h + h²) / h = 2 + h  →  2 as h → 0", styles["MathCustom"])]], colWidths=[7.15*inch])
formula.setStyle(TableStyle([("BACKGROUND",(0,0),(-1,-1),PALE), ("BOX",(0,0),(-1,-1),.6,CYAN),
                            ("LEFTPADDING",(0,0),(-1,-1),12),("RIGHTPADDING",(0,0),(-1,-1),12),
                            ("TOPPADDING",(0,0),(-1,-1),6),("BOTTOMPADDING",(0,0),(-1,-1),6)]))
flow = Table([[Paragraph("<font color='#D95D51'><b>1 · SECANT</b></font><br/>Measure across an interval", styles["BodyCustom"]),
               Paragraph("<font color='#155A78'><b>2 · SIMPLIFY</b></font><br/>The slope becomes 2 + h", styles["BodyCustom"]),
               Paragraph("<font color='#32805A'><b>3 · LIMIT</b></font><br/>As h → 0, the slope → 2", styles["BodyCustom"])]],
              colWidths=[7.15*inch/3]*3)
flow.setStyle(TableStyle([("BACKGROUND",(0,0),(-1,-1),colors.white), ("GRID",(0,0),(-1,-1),.5,colors.HexColor("#CFDCE5")),
                          ("VALIGN",(0,0),(-1,-1),"MIDDLE"), ("LEFTPADDING",(0,0),(-1,-1),8),
                          ("RIGHTPADDING",(0,0),(-1,-1),8), ("TOPPADDING",(0,0),(-1,-1),8),
                          ("BOTTOMPADDING",(0,0),(-1,-1),8)]))
facts = Table([[Paragraph("TOPIC", styles["SmallLabel"]), Paragraph("Derivative as instantaneous rate of change", styles["BodyCustom"])],
               [Paragraph("EXAMPLE", styles["SmallLabel"]), Paragraph("f(x) = x² at x = 1", styles["BodyCustom"])],
               [Paragraph("DURATION", styles["SmallLabel"]), Paragraph("4 minutes 56 seconds; narrated with quiet instrumental music", styles["BodyCustom"])],
               [Paragraph("STUDENT", styles["SmallLabel"]), Paragraph("Surya Pratap Singh Rathore · URN E25B070859 · Turing · Lambda", styles["BodyCustom"])],
               [Paragraph("CREDITS", styles["SmallLabel"]), Paragraph("OpenStax Calculus, Vol. 1, §3.1. Original instrumental score composed for this video. AI assistance with the script, visuals, code, and narration; student reviewed the mathematics.", styles["BodyCustom"])]],
              colWidths=[1.25*inch, 5.9*inch])
facts.setStyle(TableStyle([("BACKGROUND",(0,0),(0,-1),PALE), ("GRID",(0,0),(-1,-1),.4,colors.HexColor("#CFDCE5")),
                           ("VALIGN",(0,0),(-1,-1),"MIDDLE"), ("LEFTPADDING",(0,0),(-1,-1),9),
                           ("RIGHTPADDING",(0,0),(-1,-1),9), ("TOPPADDING",(0,0),(-1,-1),5),
                           ("BOTTOMPADDING",(0,0),(-1,-1),4)]))
story += [formula, Spacer(1, 9), flow, Spacer(1, 10), Paragraph("PROJECT DETAILS", styles["SmallLabel"]), Spacer(1, 3), facts]
doc.build(story, onFirstPage=page_decor, onLaterPages=page_decor)
print(OUT)

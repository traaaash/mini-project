from pathlib import Path
from PyPDF2 import PdfReader

pdf_path = Path(r'C:\MINI-PROJET\Mini-Projet IaaS v2.pdf')
reader = PdfReader(str(pdf_path))
for idx, page in enumerate(reader.pages, start=1):
    print(f'--- PAGE {idx} ---')
    print(page.extract_text() or '')

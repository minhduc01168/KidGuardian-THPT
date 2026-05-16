import os
import re

def parse_and_generate(readme_path, output_path, title):
    with open(readme_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Extract info
    title_match = re.search(r'# (BUỔI \d+:.+)', content)
    slide_title = title_match.group(1) if title_match else title
    
    time_match = re.search(r'\*\*Thời gian:\*\*\s*(.+)', content)
    time_str = time_match.group(1) if time_match else ""
    
    obj_match = re.search(r'\*\*Mục tiêu:\*\*\s*(.+)', content)
    obj_str = obj_match.group(1) if obj_match else ""

    # Generate header (Removed header and footer directives)
    slide = f"""---
marp: true
theme: default
paginate: true
style: |
  section {{
    background-color: #f8f9fa;
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
    padding: 40px 50px;
    font-size: 26px; /* Giảm nhẹ font chữ chung */
    overflow-y: auto; /* Cho phép cuộn toàn trang nếu text quá dài */
  }}
  h1 {{
    color: #2c3e50;
    font-size: 2.0em;
    text-align: center;
  }}
  h2 {{
    color: #34495e;
    border-bottom: 2px solid #3498db;
    padding-bottom: 10px;
    margin-bottom: 20px;
    font-size: 1.4em;
  }}
  h3 {{
    color: #2980b9;
    font-size: 1.2em;
  }}
  .center {{
    text-align: center;
  }}
  code {{
    background-color: #e8eaed;
    border-radius: 4px;
    padding: 2px 4px;
    color: #c0392b;
    font-size: 0.85em;
  }}
  pre {{
    background-color: #f1f3f5;
    border-left: 4px solid #3498db;
    max-height: 480px; /* Tăng chiều cao lên một chút do đã bỏ header/footer */
    overflow-y: auto;  /* Hiển thị thanh cuộn cho code dài */
    padding: 15px;
    box-shadow: inset 0 0 10px rgba(0,0,0,0.05);
  }}
  pre code {{
    color: #333;
    background-color: transparent;
    font-size: 0.85em;
  }}
  /* Tùy chỉnh thanh cuộn (Scrollbar) cho đẹp mắt */
  ::-webkit-scrollbar {{
    width: 8px;
    height: 8px;
  }}
  ::-webkit-scrollbar-track {{
    background: #e1e1e1; 
    border-radius: 4px;
  }}
  ::-webkit-scrollbar-thumb {{
    background: #888; 
    border-radius: 4px;
  }}
  ::-webkit-scrollbar-thumb:hover {{
    background: #555; 
  }}
---

<!-- _class: lead -->
# 🚀 {slide_title}

**Thời gian:** {time_str}  
**Mục tiêu:** {obj_str}

---

## 🎯 Tổng quan buổi học

- **Lý thuyết:** Nắm bắt các khái niệm quan trọng
- **Thực hành:** Áp dụng kiến thức vào thực tế
- **Bài tập:** Củng cố kiến thức đã học

"""

    # Split by ## 
    sections = re.split(r'\n## ', content)
    for section in sections[1:]:
        lines = section.split('\n')
        sec_title = lines[0].strip()
        sec_body = '\n'.join(lines[1:])
        
        if sec_title.startswith('PHẦN'):
            slide += f"""
---
<!-- _class: lead -->
# 📚 {sec_title}

"""
            # Split by ### for subsections
            subsections = re.split(r'\n### ', sec_body)
            # Add any content before the first ###
            first_part = subsections[0].strip()
            if first_part:
                slide += f"{first_part}\n"
                
            for sub in subsections[1:]:
                sub_lines = sub.split('\n')
                sub_title = sub_lines[0].strip()
                # Remove numbers like "1.1 "
                sub_title = re.sub(r'^\d+\.\d+\s+', '', sub_title)
                sub_body = '\n'.join(sub_lines[1:]).strip()
                
                # Split further if sub_body is very long and contains ####
                if '\n#### ' in sub_body:
                    mini_sections = re.split(r'\n#### ', sub_body)
                    slide += f"""---
## {sub_title}

{mini_sections[0].strip()}
"""
                    for mini in mini_sections[1:]:
                        mini_lines = mini.split('\n')
                        mini_title = mini_lines[0].strip()
                        mini_body = '\n'.join(mini_lines[1:]).strip()
                        slide += f"""---
## {mini_title}

{mini_body}
"""
                else:
                    slide += f"""---
## {sub_title}

{sub_body}
"""
        elif sec_title in ['TÀI LIỆU THAM KHẢO', 'CÂU HỎI ÔN TẬP']:
            slide += f"""---
## {sec_title}

{sec_body.strip()}
"""

    slide += """
---
<!-- _class: lead -->
# 🎉 Cảm ơn các bạn!
### Hẹn gặp lại vào buổi sau
"""
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(slide)

base_dir = '/home/minh/CVS/kidguardian-thpt/docs/dao-tao'
for i in range(1, 11):
    session_dir = f"buoi-{i:02d}"
    readme_path = os.path.join(base_dir, session_dir, 'README.md')
    slide_path = os.path.join(base_dir, session_dir, 'slide.md')
    
    if os.path.exists(readme_path):
        try:
            parse_and_generate(readme_path, slide_path, f"Buổi {i}")
            print(f"Generated Markdown for {session_dir}")
        except Exception as e:
            print(f"Error processing {session_dir}: {e}")


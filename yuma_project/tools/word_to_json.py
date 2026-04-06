"""
将资料组整理的Word文档批量转换为 stories.json
Word格式要求：
标题：阿诗玛
民族：彝族
原文：
（彝文或藏文）
翻译：
（中文翻译）
简介：
（故事简介，可为空）
"""
from docx import Document
import json
import os

def convert_word_to_json(folder_path="stories_word", output_file="stories.json"):
    """
    遍历文件夹内所有.docx，提取字段生成JSON
    """
    data = []
    story_id = 1

    for filename in os.listdir(folder_path):
        if not filename.endswith(".docx"):
            continue

        filepath = os.path.join(folder_path, filename)
        doc = Document(filepath)
        # 将所有段落文本合并，用换行分隔
        full_text = "\n".join([p.text for p in doc.paragraphs])

        # 提取各字段（使用strip去除前后空白）
        title = ""
        ethnic = ""
        yi_text = ""
        chinese_text = ""
        intro = ""

        if "标题：" in full_text:
            title = full_text.split("标题：")[1].split("\n")[0].strip()
        if "民族：" in full_text:
            ethnic = full_text.split("民族：")[1].split("\n")[0].strip()
        if "原文：" in full_text:
            # 取“原文：”之后到下一个“翻译：”之前的内容
            yi_part = full_text.split("原文：")[1]
            yi_text = yi_part.split("翻译：")[0].strip()
        if "翻译：" in full_text:
            # 取“翻译：”之后到下一个“简介：”之前的内容
            chinese_part = full_text.split("翻译：")[1]
            chinese_text = chinese_part.split("简介：")[0].strip()
        if "简介：" in full_text:
            intro = full_text.split("简介：")[1].strip()

        # 构造记录
        story = {
            "id": story_id,
            "title": title,
            "ethnic": ethnic,
            "yi_text": yi_text,
            "chinese_text": chinese_text,
            "intro": intro
        }
        data.append(story)
        story_id += 1
        print(f"已转换：{filename} -> ID {story['id']}")

    # 写入JSON文件
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    print(f"完成！共转换 {len(data)} 个故事，已保存至 {output_file}")

if __name__ == "__main__":
    # 使用前请确保 stories_word 文件夹存在，并放入Word文档
    convert_word_to_json()
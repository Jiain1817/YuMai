"""
一键脚本：生成占位封面图 + 更新 stories.json 添加 cover_image 字段
用法：python backend/scripts/setup_story_cover.py
"""
import os
import sys
import json
import shutil
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Pillow 未安装，正在安装...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
    from PIL import Image

PROJECT_ROOT = Path(__file__).resolve().parents[2]
IMAGE_DIR = PROJECT_ROOT / "backend" / "static" / "images"
DATA_FILE = PROJECT_ROOT / "data" / "stories.json"
BACKUP_FILE = DATA_FILE.with_suffix(".json.bak")

COLORS = [
    (180, 100, 100),  # 暗红
    (100, 150, 180),  # 蓝灰
    (120, 170, 120),  # 绿
    (200, 170,  80),  # 金黄
    (160, 110, 180),  # 紫
]


def generate_placeholders():
    IMAGE_DIR.mkdir(parents=True, exist_ok=True)
    for i, color in enumerate(COLORS, 1):
        img_path = IMAGE_DIR / f"story{i}.jpg"
        if not img_path.exists():
            img = Image.new("RGB", (300, 400), color)
            img.save(img_path)
            print(f"  生成: {img_path.name}")
        else:
            print(f"  已存在，跳过: {img_path.name}")


def update_stories():
    if not DATA_FILE.exists():
        print(f"错误：找不到 {DATA_FILE}")
        sys.exit(1)

    shutil.copyfile(DATA_FILE, BACKUP_FILE)
    print(f"  备份至: {BACKUP_FILE.name}")

    with DATA_FILE.open("r", encoding="utf-8") as f:
        stories = json.load(f)

    updated = 0
    for idx, story in enumerate(stories):
        if "cover_image" not in story:
            story_id = story.get("id", idx)
            index = (story_id % 5) + 1
            story["cover_image"] = f"/static/images/story{index}.jpg"
            updated += 1

    with DATA_FILE.open("w", encoding="utf-8") as f:
        json.dump(stories, f, ensure_ascii=False, indent=2)

    print(f"  更新了 {updated} 条故事的 cover_image 字段")


if __name__ == "__main__":
    print("=== 生成占位图 ===")
    generate_placeholders()
    print("\n=== 更新 stories.json ===")
    update_stories()
    print("\n完成！启动后端后可验证：")
    print("  http://127.0.0.1:8000/static/images/story1.jpg")
    print("  http://127.0.0.1:8000/stories")
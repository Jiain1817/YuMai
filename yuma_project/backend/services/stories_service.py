import json
from pathlib import Path
from typing import Optional, List, Dict, Any


def _find_project_root(start: Path) -> Path:
    for parent in (start, *start.parents):
        if (parent / "data" / "stories.json").exists():
            return parent
    return start.parents[1]


PROJECT_ROOT = _find_project_root(Path(__file__).resolve())
STORIES_PATH = PROJECT_ROOT / "data" / "stories.json"


def _load_stories() -> List[Dict[str, Any]]:
    if not STORIES_PATH.exists():
        return []
    with STORIES_PATH.open("r", encoding="utf-8") as f:
        data = json.load(f)
    return data if isinstance(data, list) else []


def _get_content_zh(story: Dict[str, Any]) -> str:
    """从 story 中提取中文正文，兼容新结构 content.zh / content 字符串 / 旧字段。"""
    content = story.get("content")
    if isinstance(content, dict):
        text = (
            content.get("zh")
            or content.get("ZH")
            or content.get("cn")
            or content.get("CN")
        )
        if isinstance(text, str):
            return text
    if isinstance(content, str):
        return content
    for key in ("chinese_text", "yi_text"):
        val = story.get(key)
        if isinstance(val, str) and val.strip():
            return val
    return ""


def get_all_stories() -> List[Dict[str, Any]]:
    """返回原始故事列表（含所有字段）。"""
    return _load_stories()


def list_stories(stories: Optional[List[Dict[str, Any]]] = None) -> List[Dict]:
    """
    GET /stories 列表：返回 id, title, ethnic, intro, summary, cover_image。
    summary 由 content.zh 前 80 字生成；缺字段时用空字符串，向后兼容。
    """
    if stories is None:
        stories = _load_stories()
    result: List[Dict[str, Any]] = []
    for story in stories:
        if "id" not in story or "title" not in story:
            continue

        content_zh = _get_content_zh(story)
        summary = (content_zh[:80] + "…") if len(content_zh) > 80 else content_zh

        item: Dict[str, Any] = {
            "id": story["id"],
            "title": story["title"],
            "ethnic": story.get("ethnic", ""),
            "intro": story.get("intro", ""),
            "summary": summary,
            "cover_image": story.get("cover_image"),
        }
        result.append(item)

    return result


def normalize_content(content: Dict[str, Any]) -> Dict[str, str]:
    """
    标准化 content 字段，统一为 zh/yi/zang 三个字段。
    映射规则：ii → yi, bo → zang
    """
    normalized = {
        "zh": "",
        "yi": "",
        "zang": ""
    }

    if not isinstance(content, dict):
        return normalized

    # 处理中文字段
    normalized["zh"] = (
        content.get("zh") or
        content.get("ZH") or
        content.get("cn") or
        content.get("CN") or
        ""
    )

    # 处理彝文字段：优先使用 yi，其次映射 ii
    normalized["yi"] = (
        content.get("yi") or
        content.get("YI") or
        content.get("ii") or
        content.get("II") or
        ""
    )

    # 处理藏文字段：优先使用 zang，其次映射 bo，最后尝试 original
    normalized["zang"] = (
        content.get("zang") or
        content.get("ZANG") or
        content.get("bo") or
        content.get("BO") or
        content.get("original") or
        ""
    )

    return normalized


def get_story_by_id(story_id: int) -> Optional[Dict]:
    """
    获取故事详情，自动标准化 content 字段为 zh/yi/zang 结构。
    保留原有字段，同时添加标准化字段。
    """
    stories = _load_stories()
    for story in stories:
        if story.get("id") == story_id:
            # 如果 content 是字典，进行标准化处理
            if isinstance(story.get("content"), dict):
                original_content = story["content"]
                normalized = normalize_content(original_content)
                # 保留原有字段，添加标准化字段
                story["content"] = {**original_content, **normalized}
            return story
    return None


from fastapi import APIRouter
from backend.services.stories_service import list_stories, get_story_by_id, get_all_stories

router = APIRouter()


@router.get("/stories")
def get_stories():
    return list_stories()


@router.get("/stories/search")
async def search_stories(query: str = ""):
    """按 title / ethnic / keywords 搜索故事，返回与 /stories 相同结构。"""
    if not query:
        return []
    q = query.lower()
    results = []
    for story in get_all_stories():
        if "id" not in story or "title" not in story:
            continue
        hit = (
            q in story.get("title", "").lower()
            or q in story.get("ethnic", "").lower()
            or any(q in kw.lower() for kw in story.get("keywords", []))
        )
        if hit:
            results.append(story)
    return list_stories(stories=results)


@router.get("/story/{story_id}")
def get_story(story_id: int):
    """返回完整故事对象，兼容缺少 intro/keywords 等字段的旧数据。"""
    story = get_story_by_id(story_id)
    if story is None:
        return {"error": "story not found"}
    return story


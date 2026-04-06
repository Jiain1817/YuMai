import io
import edge_tts
from fastapi import APIRouter
from fastapi.responses import StreamingResponse, JSONResponse
from backend.services.stories_service import get_story_by_id

router = APIRouter()


def _extract_zh_text(story: dict) -> str:
    content = story.get("content")
    if isinstance(content, dict):
        zh = content.get("zh") or content.get("ZH") or content.get("cn") or content.get("CN")
        if isinstance(zh, str) and zh.strip():
            return zh
    if isinstance(content, str) and content.strip():
        return content
    return story.get("chinese_text", "")


@router.get("/tts/{story_id}")
async def get_tts(story_id: int):
    story = get_story_by_id(story_id)
    if story is None:
        return JSONResponse(status_code=404, content={"error": "story not found"})

    text = _extract_zh_text(story)
    if not text.strip():
        return JSONResponse(status_code=400, content={"error": "该故事无中文文本"})

    communicate = edge_tts.Communicate(text, "zh-CN-XiaoxiaoNeural")
    buf = io.BytesIO()
    async for chunk in communicate.stream():
        if chunk["type"] == "audio":
            buf.write(chunk["data"])
    buf.seek(0)

    return StreamingResponse(buf, media_type="audio/mpeg")

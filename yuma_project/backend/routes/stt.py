import os
import tempfile
import whisper
from fastapi import APIRouter, File, UploadFile
from fastapi.responses import JSONResponse

router = APIRouter()

_model = None


def _get_model():
    global _model
    if _model is None:
        _model = whisper.load_model("base")
    return _model


@router.post("/stt")
async def stt(audio: UploadFile = File(...)):
    if not audio.content_type or not audio.content_type.startswith("audio/"):
        return JSONResponse(status_code=400, content={"error": "仅支持音频文件（audio/*）"})

    suffix = os.path.splitext(audio.filename or "audio.wav")[1] or ".wav"
    tmp_path = None
    try:
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            tmp.write(await audio.read())
            tmp_path = tmp.name

        model = _get_model()
        result = model.transcribe(tmp_path)
        return {"text": result["text"]}
    except Exception as e:
        return JSONResponse(status_code=500, content={"error": f"识别失败：{str(e)}"})
    finally:
        if tmp_path and os.path.exists(tmp_path):
            os.remove(tmp_path)

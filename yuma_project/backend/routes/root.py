from fastapi import APIRouter

router = APIRouter()


@router.get("/")
def read_root():
    return {"message": "\u8bed\u8109\u540e\u7aef\u542f\u52a8\u6210\u529f"}


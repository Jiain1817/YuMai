import os
from pathlib import Path

from typing import List, Dict, Any, Optional

from backend.services.stories_service import _load_stories

try:
    from sentence_transformers import SentenceTransformer
except ImportError as e:  # pragma: no cover - import guard
    raise ImportError(
        "sentence-transformers 未安装，请先执行：pip install sentence-transformers faiss-cpu"
    ) from e

try:
    import faiss
except ImportError as e:  # pragma: no cover - import guard
    raise ImportError(
        "faiss 未安装，请先执行：pip install faiss-cpu"
    ) from e

# 使用相对路径，从 yuma_project 根目录
PROJECT_ROOT = Path(__file__).resolve().parents[2]
MODEL_PATH = PROJECT_ROOT / "models" / "paraphrase-multilingual-MiniLM-L12-v2"

_model: Optional[SentenceTransformer] = None
_index: Optional["faiss.IndexFlatIP"] = None
_stories: List[Dict[str, Any]] = []


def _get_model() -> SentenceTransformer:
    global _model
    if _model is None:
        if not MODEL_PATH.exists():
            # 如果本地没有，自动下载到该目录
            _model = SentenceTransformer("paraphrase-multilingual-MiniLM-L12-v2", cache_folder=str(MODEL_PATH.parent))
            _model.save(str(MODEL_PATH))
        else:
            _model = SentenceTransformer(str(MODEL_PATH))
    return _model


def _extract_content(story: Dict[str, Any]) -> str:
    """
    用于 RAG 向量化的文本：拼接 title + intro + content.zh。
    兼容新结构 content.zh / content 字符串 / 旧字段；缺 intro 等不报错。
    """
    parts: List[str] = []

    title = story.get("title")
    if isinstance(title, str) and title.strip():
        parts.append(title.strip())

    intro = story.get("intro")
    if isinstance(intro, str) and intro.strip():
        parts.append(intro.strip())

    content = story.get("content")
    if isinstance(content, dict):
        zh = (
            content.get("zh")
            or content.get("ZH")
            or content.get("cn")
            or content.get("CN")
        )
        if isinstance(zh, str) and zh.strip():
            parts.append(zh.strip())
    elif isinstance(content, str) and content.strip():
        parts.append(content.strip())
    else:
        for key in ("chinese_text", "yi_text"):
            val = story.get(key)
            if isinstance(val, str) and val.strip():
                parts.append(val.strip())
                break

    return "\n".join(parts) if parts else ""


def _build_index() -> None:
    """从 stories.json 构建 FAISS 向量索引（每次搜索前重新构建，确保数据最新）"""
    global _index, _stories

    # 强制每次重新构建，保证 stories.json 更新后索引同步更新
    _index = None
    _stories = []

    all_stories = _load_stories()
    texts: List[str] = []
    kept_stories: List[Dict[str, Any]] = []

    print(f"========== RAG 索引构建 ==========")
    print(f"共加载 {len(all_stories)} 个故事")

    for story in all_stories:
        text = _extract_content(story)
        if not text:
            print(f"  ⚠️ 跳过（无有效文本）: {story.get('title', '未知标题')}")
            continue
        print(f"  ✅ 索引: {story.get('title', '未知标题')} (文本长度: {len(text)})")
        texts.append(text)
        kept_stories.append(story)

    if not texts:
        # 没有可用文本，不构建索引
        _index = None
        _stories = []
        print("⚠️ 没有可用文本，未构建索引")
        return

    model = _get_model()
    embeddings = model.encode(texts, convert_to_numpy=True, normalize_embeddings=True)

    dim = embeddings.shape[1]
    index = faiss.IndexFlatIP(dim)  # 归一化后用内积做余弦相似度
    index.add(embeddings)

    _index = index
    _stories = kept_stories
    print(f"✅ 索引构建完成，共 {len(texts)} 个故事向量，维度: {dim}")
    print("===================================")


def search_similar_stories(question: str, top_k: int = 3) -> List[Dict[str, Any]]:
    """
    基于语义相似度检索最相关的故事列表（默认返回 top_k=3 个）
    """
    _build_index()

    if _index is None or not _stories:
        return []

    model = _get_model()
    query_embedding = model.encode(
        [question],
        convert_to_numpy=True,
        normalize_embeddings=True,
    )

    k = min(top_k, len(_stories))
    scores, indices = _index.search(query_embedding, k)

    SIMILARITY_THRESHOLD = 0.3  # 相似度低于此值不返回
    result: List[Dict[str, Any]] = []
    for rank, idx in enumerate(indices[0]):
        score = float(scores[0][rank])
        if score < SIMILARITY_THRESHOLD:
            print(f"  🔇 过滤低相似度: {_stories[int(idx)].get('title', '未知')} (score={score:.3f})")
            continue
        story = _stories[int(idx)]
        story_with_score = dict(story)
        story_with_score["_score"] = score
        result.append(story_with_score)

    # 调试日志：打印检索到的故事标题
    print("========== RAG 检索日志 ==========")
    for i, story in enumerate(result):
        try:
            print(f"Top{i+1}:", story.get("title", "未知标题"))
        except Exception:
            print(f"Top{i+1}: 无法读取标题")
    print("===================================")

    return result

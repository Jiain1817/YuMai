import json
from pathlib import Path
from typing import List, Dict, Any

import numpy as np

try:
    from sentence_transformers import SentenceTransformer
except ImportError as e:  # pragma: no cover - import guard
    raise ImportError(
        "未找到 sentence-transformers，请先运行：pip install sentence-transformers faiss-cpu"
    ) from e

try:
    import faiss
except ImportError as e:  # pragma: no cover - import guard
    raise ImportError(
        "未找到 faiss，请先运行：pip install faiss-cpu"
    ) from e


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = PROJECT_ROOT / "data"
STORIES_PATH = DATA_DIR / "stories.json"
INDEX_PATH = DATA_DIR / "vector.index"
META_PATH = DATA_DIR / "vector_meta.json"

MODEL_NAME = "sentence-transformers/all-MiniLM-L6-v2"


def load_stories() -> List[Dict[str, Any]]:
    if not STORIES_PATH.exists():
        raise FileNotFoundError(f"未找到语料文件：{STORIES_PATH}")

    with STORIES_PATH.open("r", encoding="utf-8") as f:
        data = json.load(f)

    if not isinstance(data, list):
        raise ValueError("stories.json 内容格式错误，必须是列表(list)")

    return data


def extract_text_from_story(story: Dict[str, Any]) -> str:
    """
    提取用于向量化的文本：
    1. 优先使用 story['content']['zh']
    2. 如果 story['content'] 是字符串，则直接使用
    """
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

    return ""


def build_embeddings(stories: List[Dict[str, Any]]) -> (np.ndarray, List[Dict[str, Any]]):
    texts: List[str] = []
    meta: List[Dict[str, Any]] = []

    for story in stories:
        text = extract_text_from_story(story)
        if not text:
            continue

        story_id = story.get("id")
        if story_id is None:
            continue

        texts.append(text)
        meta.append({"story_id": story_id})

    if not texts:
        raise ValueError("没有从 stories.json 中提取到任何可用文本，请检查 content/zh 字段。")

    print(f"共提取 {len(texts)} 条故事文本，开始编码为向量...")
    model = SentenceTransformer(MODEL_NAME)
    embeddings = model.encode(texts, convert_to_numpy=True, show_progress_bar=True)

    return embeddings.astype("float32"), meta


def build_faiss_index(embeddings: np.ndarray) -> faiss.Index:
    dim = embeddings.shape[1]
    print(f"向量维度：{dim}，构建 FAISS IndexFlatL2 索引...")
    index = faiss.IndexFlatL2(dim)
    index.add(embeddings)
    print(f"索引中共包含 {index.ntotal} 条向量。")
    return index


def save_index_and_meta(index: faiss.Index, meta: List[Dict[str, Any]]) -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    print(f"保存向量索引到：{INDEX_PATH}")
    faiss.write_index(index, str(INDEX_PATH))

    print(f"保存向量元数据到：{META_PATH}")
    with META_PATH.open("w", encoding="utf-8") as f:
        json.dump(meta, f, ensure_ascii=False, indent=2)


def main() -> None:
    print("=== 构建 stories 向量索引 ===")
    print(f"项目根目录：{PROJECT_ROOT}")
    print(f"读取语料：{STORIES_PATH}")

    stories = load_stories()
    embeddings, meta = build_embeddings(stories)
    index = build_faiss_index(embeddings)
    save_index_and_meta(index, meta)

    print("=== 向量索引构建完成 ===")
    print(f"索引文件：{INDEX_PATH}")
    print(f"元数据文件：{META_PATH}")


if __name__ == "__main__":
    main()


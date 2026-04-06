"""
少数民族语言故事智能体模块
作者：李可欣
版本：v2.2（强化语言指令 + lang参数）
函数签名：ask_model(question: str, story: dict, use_rag: bool, history: list, lang: str) -> dict
"""

from openai import OpenAI
import os
from dotenv import load_dotenv
from typing import Dict, Optional, List, Any

from backend.services.rag_service import search_similar_stories

load_dotenv()

if not os.getenv("OPENAI_API_KEY"):
    raise ValueError("OPENAI_API_KEY 未设置，请检查 .env 文件")

# ==================== 配置 ====================
MODEL_NAME = "deepseek-chat"
TEMPERATURE = 0.3
MAX_TOKENS = 1000
# =============================================

client = OpenAI(
    api_key=os.getenv("OPENAI_API_KEY"),
    base_url="https://api.deepseek.com"
)

# 基础系统提示词（通用部分）
SYSTEM_PROMPT_BASE = """你是一名中国民间故事讲解员。
回答问题时必须严格依据提供的故事内容。
如果故事中没有答案，请回答：
"故事中没有提到这个信息"。

重要：如果用户的问题是追问或延续之前的话题，请结合之前的对话内容来回答，不要重复说"故事中没有提到"。
"""

# 自由对话系统提示词（通用部分）
FREE_CHAT_PROMPT_BASE = """你是一名温暖友好的AI文化伴侣，可以与用户轻松聊天。
你可以谈论：
- 中国少数民族文化、习俗、节日
- 民间故事、传说、史诗（如格萨尔王、阿诗玛）
- 语言学习、文化探索话题
- 日常生活中的轻松话题

回答风格：亲切、自然、有文化底蕴，但不拘谨。
如果用户问的故事信息你不确定，可以诚实地说"这个我不太确定，但根据我的了解..."。
"""

# 语言映射：将 lang 代码转换为自然语言名称
LANG_NAMES = {
    'zh': '汉语',
    'bo': '藏语',
    'ii': '彝语',
}


def _build_system_prompt(base_prompt: str, lang: str) -> str:
    """根据语言构建系统提示词，在基础提示词上添加语言指示"""
    if lang == 'zh':
        return base_prompt
    lang_name = LANG_NAMES.get(lang, '汉语')
    return f"{base_prompt}\n\n请用{lang_name}回答所有问题。"


def _generate_suggestions(question: str, answer: str, story_title: str = "", lang: str = 'zh') -> List[str]:
    """根据问答内容生成猜你想问建议列表（最多2条），并尝试用目标语言生成"""
    context_hint = f"相关故事：{story_title}。" if story_title else ""
    lang_instruction = f"请用{ LANG_NAMES.get(lang, '汉语') }生成。\n" if lang != 'zh' else ""
    suggestions_prompt = f"""{context_hint}
用户问题：{question}
AI回答：{answer}

{lang_instruction}请根据以上对话，生成2个用户可能会追问的简短问题。每行一个，不要编号，不要加引号。"""

    try:
        response = client.chat.completions.create(
            model=MODEL_NAME,
            messages=[{"role": "user", "content": suggestions_prompt}],
            temperature=0.5,
            max_tokens=100
        )
        raw = response.choices[0].message.content or ""
        lines = [l.strip() for l in raw.split('\n') if l.strip()]
        # 过滤掉编号开头
        suggestions = [l for l in lines if not l.startswith(('1', '2', '3', '4', '5', '・', '-', '*', '·'))]
        return suggestions[:2]
    except Exception:
        return []


def ask_model(
    question: str,
    story: dict,
    use_rag: bool = False,
    history: Optional[List[Dict]] = None,
    lang: str = 'zh'
) -> Dict[str, Any]:
    """
    后端要求的接口函数

    Args:
        question: 用户问题（字符串）
        story: 前端选择的主故事字典，包含 id, title, 等字段
        use_rag: 是否启用全局知识库检索（默认 False，仅使用当前故事）
        history: 对话历史，格式为 [{"role": "user"/"assistant", "content": "..."}]
        lang: 回答语言代码（'zh'/'bo'/'ii'）

    Returns:
        {
            "answer": str,
            "source": str,
            "rag_sources": List[{"title": str, "score": float}],
            "suggestions": List[str]  # 最多2条
        }
    """
    # 1. 基于用户问题检索相似故事（RAG 检索层），仅在 use_rag=True 时启用
    if use_rag:
        retrieved_stories: List[Dict] = search_similar_stories(question, top_k=3)

        # 确保用户当前选中的故事也在上下文中（如果不在检索结果中，则手动加入）
        if story:
            main_id = story.get("id")
            if main_id is not None and not any(s.get("id") == main_id for s in retrieved_stories):
                retrieved_stories.insert(0, story)
            elif main_id is None:
                retrieved_stories.insert(0, story)

        if not retrieved_stories and story:
            retrieved_stories = [story]
    else:
        # 不启用全局检索时，只使用当前选中的故事
        retrieved_stories = [story] if story else []

    # 2. 将多个故事拼接成统一上下文（格式：标题、民族、简介、正文）
    context_blocks = []
    for idx, s in enumerate(retrieved_stories, start=1):
        block = _build_rag_context(s, idx)
        context_blocks.append(block)

    full_context = "\n\n".join(context_blocks) if context_blocks else ""

    # 记录 RAG 检索来源（含相似度 score，缺 _score 时默认 0）
    rag_sources: List[Dict[str, Any]] = [
        {"title": s.get("title", ""), "score": float(s.get("_score", 0))}
        for s in retrieved_stories
    ]
    source: str = (rag_sources[0]["title"] if rag_sources else "未知来源")
    story_title: str = rag_sources[0]["title"] if rag_sources else ""

    # 3. 构建系统提示词和消息列表
    system_prompt = _build_system_prompt(SYSTEM_PROMPT_BASE, lang)
    messages = [{"role": "system", "content": system_prompt}]

    # 强化语言指令：添加一条用户消息强调必须使用目标语言
    if lang != 'zh':
        lang_name = LANG_NAMES.get(lang, '汉语')
        messages.insert(1, {"role": "user", "content": f"请必须用{lang_name}回答我接下来问的所有问题，不要使用其他语言。"})

    # 4. 构建用户提示词（含上下文、历史）
    user_prompt = f"""以下是若干与问题相关的故事内容，请仅依据这些内容进行回答。

{full_context}

【用户问题】
{question}

请根据以上故事内容作答。"""

    # 添加语言指示（如果非汉语）
    if lang != 'zh':
        lang_name = LANG_NAMES.get(lang, '汉语')
        user_prompt = f"请用{lang_name}回答。\n\n{user_prompt}"

    # 添加历史对话
    if history:
        for msg in history:
            role = "user" if msg.get("role") == "user" else "assistant"
            messages.append({"role": role, "content": msg.get("content", "")})
        # 重新构造带历史对话的用户提示词
        history_context = "\n".join([
            f"{'用户' if msg.get('role') == 'user' else '我'}：" + msg.get("content", "")
            for msg in history
        ])
        user_prompt = f"""【对话历史】
{history_context}

【当前问题】
{question}

请根据对话历史和以下故事内容作答。如果问题是关于之前对话中提到的内容，请结合历史来回答。
\n【相关故事内容】\n{full_context}\n\n请根据以上内容作答。"""
        if lang != 'zh':
            lang_name = LANG_NAMES.get(lang, '汉语')
            user_prompt = f"请用{lang_name}回答。\n\n{user_prompt}"

    messages.append({"role": "user", "content": user_prompt})

    # 5. 调用大模型获取回答
    try:
        response = client.chat.completions.create(
            model=MODEL_NAME,
            messages=messages,
            temperature=TEMPERATURE,
            max_tokens=MAX_TOKENS
        )
        generated_answer = response.choices[0].message.content
    except Exception as e:
        generated_answer = f"【系统错误】{str(e)}"

    # 6. 生成猜你想问（也尝试用目标语言）
    suggestions = _generate_suggestions(question, generated_answer, story_title, lang)

    return {
        "answer": generated_answer,
        "source": source,
        "rag_sources": rag_sources,
        "suggestions": suggestions,
    }


def _get_content_zh(story: dict) -> str:
    """提取正文 content.zh，兼容新结构及旧字段。"""
    content = story.get("content")
    if isinstance(content, dict):
        zh = content.get("zh") or content.get("ZH") or content.get("cn") or content.get("CN")
        if isinstance(zh, str):
            return zh
    if isinstance(content, str):
        return content
    if story.get("chinese_text"):
        return story["chinese_text"]
    if story.get("yi_text"):
        return story["yi_text"]
    return ""


def _build_rag_context(story: dict, index: int) -> str:
    """
    构建 RAG 上下文块，格式：
    【故事 N】
    标题：xxx
    民族：xxx
    简介：xxx
    正文：xxx
    缺 intro/keywords 等不报错，向后兼容。
    """
    lines = [f"【故事 {index}】"]
    title = story.get("title")
    if title is not None and str(title).strip():
        lines.append(f"标题：{title}")
    ethnic = story.get("ethnic")
    if ethnic is not None and str(ethnic).strip():
        lines.append(f"民族：{ethnic}")
    intro = story.get("intro")
    if intro is not None and str(intro).strip():
        lines.append(f"简介：{intro}")
    body = _get_content_zh(story)
    if not body.strip():
        body = _build_context_legacy(story)
    lines.append(f"正文：\n{body}")
    return "\n".join(lines)


def _build_context_legacy(story: dict) -> str:
    """旧数据回退：无 content.zh 时用 yi_text/chinese_text/intro 拼接。"""
    parts = []
    if story.get("yi_text"):
        parts.append(story["yi_text"])
    if story.get("chinese_text"):
        parts.append(story["chinese_text"])
    if story.get("intro"):
        parts.append(story["intro"])
    return "\n".join(parts) if parts else "（无正文）"


def free_chat(
    question: str,
    history: Optional[List[Dict]] = None,
    lang: str = 'zh'
) -> Dict[str, Any]:
    """
    自由对话模式：不依赖知识库，纯粹的大模型对话。
    用于用户闲聊、问候、或未开启 RAG 的通用问答。

    Args:
        question: 用户问题
        history: 对话历史，格式为 [{"role": "user"/"assistant", "content": "..."}]
        lang: 回答语言代码
    """
    # 构建系统提示词（包含语言要求）
    system_prompt = _build_system_prompt(FREE_CHAT_PROMPT_BASE, lang)
    messages = [{"role": "system", "content": system_prompt}]

    # 强化语言指令：添加一条用户消息强调必须使用目标语言
    if lang != 'zh':
        lang_name = LANG_NAMES.get(lang, '汉语')
        messages.insert(1, {"role": "user", "content": f"请必须用{lang_name}回答我接下来问的所有问题，不要使用其他语言。"})

    # 添加历史对话
    if history:
        for msg in history:
            role = "user" if msg.get("role") == "user" else "assistant"
            messages.append({"role": role, "content": msg.get("content", "")})

    # 添加当前问题，如果非汉语，在问题前添加语言指示
    user_question = question
    if lang != 'zh':
        lang_name = LANG_NAMES.get(lang, '汉语')
        user_question = f"请用{lang_name}回答。\n{user_question}"
    messages.append({"role": "user", "content": user_question})

    try:
        response = client.chat.completions.create(
            model=MODEL_NAME,
            messages=messages,
            temperature=0.7,
            max_tokens=MAX_TOKENS
        )
        generated_answer = response.choices[0].message.content
    except Exception as e:
        generated_answer = f"【系统错误】{str(e)}"

    # 生成猜你想问（同样尝试用目标语言）
    suggestions = _generate_suggestions(question, generated_answer, "", lang)

    return {
        "answer": generated_answer,
        "source": "自由对话",
        "rag_sources": [],
        "suggestions": suggestions,
    }

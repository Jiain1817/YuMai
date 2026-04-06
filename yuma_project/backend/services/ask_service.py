from typing import Dict, Any, Optional, List

from backend.services.stories_service import get_story_by_id
from backend.services import agent
from backend.services.rag_service import search_similar_stories

# 搜索意图关键词
SEARCH_INTENT_PATTERNS = [
    # 直接搜索类
    '搜索', '查找', '找一下', '帮我找', '有没有', '有没有关于',
    '查一下', '搜一下', '了解一下',
    # 介绍类
    '介绍一下', '讲讲', '说一说', '介绍一下', '介绍一下',
    '是什么', '什么是', '谁是', '哪个是', '哪个',
    '讲的是什么', '说的是', '讲的是',
    # 故事文化相关
    '故事', '传说', '人物', '文化', '史诗', '节日',
    '习俗', '传统', '民族', '非遗', '遗产',
    # 问句类
    '为什么', '为什么是', '为什么会', '怎样', '怎么样',
    '如何', '为何',
]


def _is_search_intent(question: str) -> bool:
    """判断用户是否有知识库检索意图"""
    q = question.lower().strip()
    if len(q) < 2:
        return False
    for pattern in SEARCH_INTENT_PATTERNS:
        if pattern in q:
            return True
    return False


def ask_question(
    story_id: Optional[int],
    question: str,
    use_rag: bool = False,
    history: Optional[List[Dict]] = None,
    lang: str = 'zh',  # 新增语言参数
) -> Dict[str, Any]:
    """
    AI 问答入口：
    1. 有 story_id → 基于指定故事回答
    2. 无 story_id + 搜索意图 + use_rag=True → 全局 RAG 检索
    3. 无 story_id + 无搜索意图 → 自由对话模式
    4. 无 story_id + 搜索意图 + use_rag=False → 自由对话模式（尊重用户关闭 RAG 的选择）
    5. 有 history → 将历史对话拼接到系统提示词中
    6. lang → 指定回答语言（zh/bo/ii）
    """
    # 有指定故事
    if story_id is not None:
        story = get_story_by_id(story_id)
        if not story:
            return {
                "answer": "未找到该故事",
                "source": "未找到故事",
                "rag_sources": [],
            }
        # 传递 lang 给 agent
        return agent.ask_model(question, story, use_rag=use_rag, history=history, lang=lang)

    # 无指定故事，检测搜索意图
    has_intent = _is_search_intent(question)

    # 意图触发且用户开启 RAG → 全局知识库检索
    if has_intent and use_rag:
        retrieved_stories: List[Dict] = search_similar_stories(question, top_k=2)
        if not retrieved_stories:
            # 知识库为空，但用户意图明确 → 走自由对话
            return agent.free_chat(question, history=history, lang=lang)
        return agent.ask_model(question, retrieved_stories[0], use_rag=True, history=history, lang=lang)

    # 其他情况 → 自由对话模式
    return agent.free_chat(question, history=history, lang=lang)


# Backward-compatible alias
def answer_question(
    story_id: Optional[int],
    question: str,
    use_rag: bool = False,
    history: Optional[List[Dict]] = None,
    lang: str = 'zh',  # 新增语言参数
) -> Dict[str, Any]:
    return ask_question(story_id, question, use_rag, history, lang)

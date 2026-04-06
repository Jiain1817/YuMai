# API 文档

## 基础信息

| 项目 | 内容 |
|------|------|
| 启动命令 | `uvicorn backend.app:app --reload` |
| 默认地址 | `http://127.0.0.1:8000` |
| Swagger UI | `http://127.0.0.1:8000/docs` |
| ReDoc | `http://127.0.0.1:8000/redoc` |

---

## 接口列表

### GET /stories

获取所有故事列表。

**响应示例**
```json
[
  {
    "id": 1,
    "title": "萨迦格言·第1则",
    "ethnic": "藏族",
    "intro": "智者学识似宝库，积聚珍宝诸格言。",
    "summary": "智者学识似宝库，积聚珍宝诸格言。万水归处为大海…",
    "cover_image": "/static/images/story2.jpg"
  }
]
```

---

### GET /stories/search

按关键词搜索故事。

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| query | string | 是 | 搜索关键词 |

**响应示例**
```json
[
  {
    "id": 23,
    "title": "妈妈的女儿",
    "ethnic": "彝族",
    "intro": "...",
    "summary": "..."
  }
]
```

---

### GET /story/{story_id}

获取单个故事完整数据。

**响应示例**
```json
{
  "id": 1,
  "title": "萨迦格言·第1则",
  "ethnic": "藏族",
  "region": "西藏",
  "category": "格言",
  "intro": "...",
  "keywords": ["智慧", "格言"],
  "characters": [],
  "content": {
    "zh": "智者学识似宝库...",
    "yi": "彝语文本",
    "zang": "藏语文本",
    "original": "原文"
  },
  "moral": "",
  "source": "萨迦格言集",
  "collector": "",
  "cover_image": "/static/images/story2.jpg"
}
```

**错误响应**
```json
{ "error": "story not found" }
```

---

### POST /ask

向 AI 提问，基于指定故事内容回答（RAG 增强）。

**请求体**
```json
{
  "story_id": 1,
  "question": "这个故事的主题是什么？"
}
```

**响应示例**
```json
{
  "answer": "这个故事的主题是...",
  "source": "萨迦格言·第1则",
  "rag_sources": [
    {"title": "萨迦格言·第1则", "score": 0.92}
  ]
}
```

**错误响应**
```json
{ "error": "错误信息" }
```

---

### GET /tts/{story_id}

将故事中文文本合成为语音，返回 MP3 音频流。

**响应**
- Content-Type: `audio/mpeg`
- 返回音频二进制流

---

### POST /stt

上传音频文件，返回语音识别文本（Whisper）。

**请求**
- Content-Type: `multipart/form-data`
- 字段名：`audio`

**响应示例**
```json
{
  "text": "识别出的文字内容"
}
```

---

### GET /static/images/{filename}

访问故事封面图片静态文件。

---

## 数据模型

### Story（完整故事对象）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 故事唯一 ID |
| title | string | 故事标题 |
| ethnic | string | 民族 |
| content.zh | string | 中文正文 |
| content.yi | string | 彝语正文 |
| content.zang | string | 藏语正文 |
| cover_image | string | 封面图片路径 |

### StoryListItem（列表接口返回）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 故事唯一 ID |
| title | string | 故事标题 |
| ethnic | string | 民族 |
| intro | string | 简介 |
| summary | string | 正文前 80 字摘要 |
| cover_image | string \| null | 封面图片路径 |

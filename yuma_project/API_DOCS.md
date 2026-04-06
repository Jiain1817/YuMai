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
按关键词搜索故事，匹配 `title`、`ethnic`、`keywords` 字段（忽略大小写）。

**Query 参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| query | string | 是 | 搜索关键词，为空时返回空列表 |

**响应示例**
```json
[
  {
    "id": 23,
    "title": "妈妈的女儿",
    "ethnic": "彝族",
    "intro": "...",
    "summary": "...",
    "cover_image": "/static/images/story4.jpg"
  }
]
```

**错误码**

| 状态码 | 说明 |
|--------|------|
| 200 | 成功，query 为空时返回 `[]` |

---

### GET /story/{story_id}
获取单个故事完整数据。

**路径参数**

| 参数 | 类型 | 说明 |
|------|------|------|
| story_id | int | 故事 ID |

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
    "original": "..."
  },
  "moral": "",
  "source": "萨迦格言集",
  "collector": "",
  "cover_image": "/static/images/story2.jpg"
}
```

**错误码**

| 状态码 | 说明 |
|--------|------|
| 200 | 成功 |
| 200 | `{"error": "story not found"}` — ID 不存在 |

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

**错误码**

| 状态码 | 说明 |
|--------|------|
| 200 | 成功 |
| 200 | `{"error": "..."}` — 调用失败时返回错误信息 |

---

### GET /tts/{story_id}
将故事中文文本合成为语音，返回 MP3 音频流。

**路径参数**

| 参数 | 类型 | 说明 |
|------|------|------|
| story_id | int | 故事 ID |

**响应**
- Content-Type: `audio/mpeg`
- 直接返回音频二进制流

**错误码**

| 状态码 | 说明 |
|--------|------|
| 200 | 成功，返回音频流 |
| 404 | `{"error": "story not found"}` |
| 400 | `{"error": "该故事无中文文本"}` |

---

### POST /stt
上传音频文件，返回语音识别文本（使用 Whisper base 模型）。

**请求**
- Content-Type: `multipart/form-data`
- 字段名：`audio`，类型：音频文件（audio/*）

**响应示例**
```json
{
  "text": "识别出的文字内容"
}
```

**错误码**

| 状态码 | 说明 |
|--------|------|
| 200 | 成功 |
| 400 | 文件类型不是 audio/* |
| 500 | Whisper 识别失败 |

---

### GET /static/images/{filename}
访问故事封面图片静态文件。

**示例**
```
GET /static/images/story1.jpg
```

---

## 数据模型

### Story（完整故事对象）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 故事唯一 ID |
| title | string | 故事标题 |
| ethnic | string | 民族 |
| region | string | 地区 |
| category | string | 分类（格言/诗歌/故事等） |
| intro | string | 简介 |
| keywords | string[] | 关键词列表 |
| characters | string[] | 人物列表 |
| content.zh | string | 中文正文 |
| content.original | string | 原文（少数民族语言） |
| moral | string | 寓意 |
| source | string | 来源 |
| collector | string | 采集人 |
| cover_image | string | 封面图片路径，如 `/static/images/story2.jpg` |

### StoryListItem（列表接口返回）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 故事唯一 ID |
| title | string | 故事标题 |
| ethnic | string | 民族 |
| intro | string | 简介 |
| summary | string | 正文前 80 字摘要 |
| cover_image | string \| null | 封面图片路径 |

---

## 注意事项

### 环境变量
在项目根目录创建 `.env` 文件：
```
OPENAI_API_KEY=your_deepseek_api_key
```
`/ask` 接口依赖此变量，未设置时后端启动会报错。

### 依赖安装
```bash
pip install fastapi uvicorn edge-tts openai-whisper pillow python-dotenv openai
```

### Whisper 模型缓存
`base` 模型已手动下载缓存，首次调用 `/stt` 时会从缓存加载（约 1-2 秒），后续请求复用同一模型实例。

### TTS 网络要求
`edge-tts` 需要访问微软 TTS 服务，确保服务器有外网连接。

### 静态图片替换
替换 `backend/static/images/` 下的图片文件（保持文件名不变），`stories.json` 中的 `cover_image` 路径无需修改。

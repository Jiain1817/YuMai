# 语脉后端 (yuma_project)

少数民族非遗故事阅读与 AI 问答平台后端服务。

## 技术栈

| 组件 | 技术 |
|------|------|
| 框架 | FastAPI + uvicorn |
| AI/RAG | OpenAI API (DeepSeek) + Whisper (语音识别) |
| 向量检索 | Sentence Transformers + FAISS |
| TTS | edge-tts (微软语音合成) |
| 数据存储 | JSON 文件 (`data/stories.json`) |

## 快速启动

```bash
cd yuma_project

# 安装依赖
pip install fastapi uvicorn edge-tts openai-whisper python-dotenv openai sentence-transformers

# 启动（仅本机访问）
uvicorn backend.app:app --reload

# 启动（允许局域网真机访问）
uvicorn backend.app:app --reload --host 0.0.0.0 --port 8000
```

验证：
```bash
curl http://127.0.0.1:8000/
# {"message":"语脉后端启动成功"}
```

## 项目结构

```
yuma_project/
├── backend/
│   ├── app.py              # FastAPI 入口，CORS 配置
│   ├── routes/             # API 路由
│   │   ├── root.py         # GET /
│   │   ├── stories.py      # GET /stories, /stories/search, /story/{id}
│   │   ├── ask.py         # POST /ask
│   │   ├── tts.py         # GET /tts/{story_id}
│   │   └── stt.py         # POST /stt
│   └── services/           # 业务逻辑
│       ├── stories_service.py
│       ├── ask_service.py
│       ├── rag_service.py
│       └── agent.py
├── data/
│   └── stories.json        # 故事数据
├── scripts/                # 工具脚本
│   └── build_vector_index.py
└── .env                    # OPENAI_API_KEY
```

## 环境配置

在项目根目录创建 `.env`：
```
OPENAI_API_KEY=your_deepseek_api_key
```

## 在线文档

- Swagger UI: http://127.0.0.1:8000/docs
- ReDoc: http://127.0.0.1:8000/redoc

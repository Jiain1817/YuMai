# 语脉 App (yumai_app)

少数民族非遗故事阅读与 AI 问答平台 Flutter 应用。

支持中文、彝语、藏语三种语言。

## 技术栈

| 组件 | 技术 |
|------|------|
| 框架 | Flutter 3.11.1 |
| HTTP | http: ^1.2.1 |
| 本地存储 | shared_preferences |
| 录音 | record: ^6.2.0 |
| 音频播放 | audioplayers: ^6.6.0 |

## 快速启动

```bash
cd yumai_app

# 安装依赖
flutter pub get

# Web 浏览器
flutter run -d chrome

# Android 模拟器（自动使用 10.0.2.2 连接后端）
flutter run -d android

# 真机（需指定后端 IP）
flutter run --dart-define=API_BASE_URL=http://<后端IP>:8000 -d <device-id>
```

## 项目结构

```
yumai_app/
└── lib/
    ├── main.dart
    ├── models/
    │   └── story.dart       # Story 数据模型
    ├── services/
    │   └── api_services.dart  # API 调用封装
    └── screens/
        ├── home_screen.dart
        ├── story_list_screen.dart
        ├── story_detail_screen.dart
        ├── ai_chat_screen.dart
        ├── bookshelf_screen.dart
        ├── history_screen.dart
        └── profile_screen.dart
```

## API 对接

后端 baseURL：`http://127.0.0.1:8000`（可通过环境变量 `API_BASE_URL` 覆盖）

| 接口 | 方法 | 说明 |
|------|------|------|
| `/stories` | GET | 获取故事列表 |
| `/stories/search?query=xxx` | GET | 搜索故事 |
| `/story/{id}` | GET | 获取故事详情 |
| `/ask` | POST | AI 问答 |
| `/tts/{id}` | GET | 文字转语音 |
| `/stt` | POST | 语音转文字 |

## 数据格式

Story 模型字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 故事 ID |
| title | String | 标题 |
| ethnic | String | 民族 |
| intro | String | 简介 |
| chineseText | String | 中文正文 |
| yiText | String | 彝语正文 |
| tibetanText | String | 藏语正文 |
| coverImage | String? | 封面图 |

前端已做多格式兼容处理，支持后端返回的各种字段命名（zh/ii/bo/yi/zang 等）。

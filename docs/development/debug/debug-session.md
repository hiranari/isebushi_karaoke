# 🐛 デバッグセッションログ

生成日時: 2025-07-25T13:22:40.930345
総エントリ数: 10

## 📊 カテゴリ別サマリー
- **SESSION**: 2件
- **CACHE**: 1件
- **PITCH_DETECTION**: 3件
- **AUDIO_SWITCH**: 3件
- **TEST_RESULT**: 1件

## 📝 詳細ログ

### [13:22:40] SESSION
**デバッグセッション開始: カラオケページ開始**

### [13:22:40] CACHE
**キャッシュからピッチデータを読み込み: assets/sounds/Test.wav**
```json
{
  "pitch_count": 1200,
  "cached": true
}
```

### [13:22:40] PITCH_DETECTION
**音源: assets/sounds/Test.wav**
```json
{
  "total_pitches": 1200,
  "valid_pitches": 1200,
  "valid_rate": "100.0%",
  "min_pitch": "330.0",
  "max_pitch": "330.0",
  "avg_pitch": "330.0",
  "first_10_pitches": [
    "330.0",
    "330.0",
    "330.0",
    "330.0",
    "330.0",
    "330.0",
    "330.0",
    "330.0",
    "330.0",
    "330.0"
  ]
}
```

### [13:22:40] AUDIO_SWITCH
**音源切り替え開始: Test.wav → Test_improved.wav**

### [13:22:40] AUDIO_SWITCH
**音源切り替え: Test.wav → Test_improved.wav**
```json
{
  "success": true,
  "timestamp": "2025-07-25T13:22:40.920864"
}
```

### [13:22:40] SESSION
**セッションをリセットしました**

### [13:22:40] PITCH_DETECTION
**改善版音源でピッチ検出開始**

### [13:22:40] PITCH_DETECTION
**音源: assets/sounds/Test_improved.wav**
```json
{
  "total_pitches": 17,
  "valid_pitches": 16,
  "valid_rate": "94.1%",
  "min_pitch": "261.6",
  "max_pitch": "523.3",
  "avg_pitch": "385.4",
  "first_10_pitches": [
    "0.0",
    "261.6",
    "293.7",
    "329.6",
    "349.2",
    "392.0",
    "440.0",
    "493.9",
    "523.3",
    "261.6"
  ]
}
```

### [13:22:40] AUDIO_SWITCH
**音源切り替え完了: Test_improved.wav**

### [13:22:40] TEST_RESULT
**Test.wav → Test_improved.wav 音源切り替え: 成功**
```json
{
  "success": true,
  "details": "constant 330Hz issue resolved, C4-C5 scale detected correctly"
}
```


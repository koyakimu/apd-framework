<!-- コンテキスト間シナリオテンプレート -->
<!-- 複数コンテキストにまたがるデータフロー・連携シナリオを定義 -->

---
version: 1
---

## Scenario XC-001: {シナリオタイトル}

**Description**: {シナリオの概要}

**Contexts**: {コンテキスト1}, {コンテキスト2}

### Flow

#### Step 1
- **Context**: {コンテキスト名}
- **Action**: {アクション}
- **Data Out**:
  - To: {送信先コンテキスト}
  - Payload: {データの説明}

#### Step 2
- **Context**: {コンテキスト名}
- **Action**: {アクション}
- **Data In**:
  - From: {受信元コンテキスト}
  - Payload: {データの説明}

### Related Specs
- {SPEC_ID_1}
- {SPEC_ID_2}

### Verification Points
- {検証項目1}
- {検証項目2}

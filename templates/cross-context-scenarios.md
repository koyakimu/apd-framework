<!-- Cross-context scenario template -->
<!-- Defines data flows and integration scenarios that span multiple contexts -->

---
version: 1
---

## Scenario XC-001: {scenario title}

**Description**: {scenario summary}

**Contexts**: {context 1}, {context 2}

### Flow

#### Step 1
- **Context**: {context name}
- **Action**: {action}
- **Data Out**:
  - To: {destination context}
  - Payload: {description of the data}

#### Step 2
- **Context**: {context name}
- **Action**: {action}
- **Data In**:
  - From: {source context}
  - Payload: {description of the data}

### Related Specs
- {SPEC_ID_1}
- {SPEC_ID_2}

### Verification Points
- {verification item 1}
- {verification item 2}

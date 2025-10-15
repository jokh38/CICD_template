## **AI 워크플로우 자동화 구현 제안서**

### **1. 아키텍처 개선 방향**

#### **1.1 핵심 구조 변경사항**

| 구성 요소 | 기존 계획 | **개선 제안** |
|:--|:--|:--|
| **AI 호출 방식** | `subprocess.run()` 직접 호출 | **`--prompt-stdin` 또는 파이프라인 활용**으로 긴 프롬프트 안전하게 전달 |
| **상태 관리** | 워크플로우 각 스텝 | **GitHub Actions 아티팩트 + 캐싱 메커니즘** 추가 |
| **피드백 루프** | 단순 재시도 | **Headless mode (`-p` 플래그)와 `--output-format stream-json`**으로 정형화된 피드백 처리 |
| **컨텍스트 유지** | 매번 새로 생성 | **CLAUDE.md 파일 활용**으로 프로젝트별 지속적 컨텍스트 관리 |

#### **1.2 디렉토리 구조 제안**

```
.github/
├── workflows/
│   ├── claude-code-pr-automation.yaml    # 메인 자동화 워크플로우
│   ├── claude-code-fix-ci.yaml           # CI 실패 자동 수정
│   └── claude-code-review.yaml           # PR 자동 리뷰 (신규)
│
├── actions/
│   └── claude-code-runner/               # 재사용 가능한 복합 액션
│       ├── action.yaml
│       └── scripts/
│           ├── run_claude_code.py
│           └── parse_results.py
│
└── claude/                               # Claude 설정 디렉토리
    ├── CLAUDE.md                          # 프로젝트 컨텍스트
    ├── commands/                          # 커스텀 슬래시 명령어
    │   ├── fix-issue.md
    │   └── refactor-code.md
    └── prompts/
        ├── subagent_systemprompt.txt
        └── templates/
            ├── python_fix.md
            └── cpp_fix.md
```

### **2. 구체적 구현 방안**

#### **2.1 워크플로우 트리거 전략**

GitHub Actions의 다양한 트리거 활용:

```yaml
# claude-code-pr-automation.yaml
name: AI Code Automation
on:
  issues:
    types: [labeled]
  issue_comment:
    types: [created]
  workflow_dispatch:
    inputs:
      task_type:
        type: choice
        options:
          - refactor
          - fix-bug
          - add-feature
          - generate-tests
  workflow_run:
    workflows: ["CI"]
    types: [failed]
```

#### **2.2 Python 스크립트 개선 (run_claude_code.py)**

subprocess 처리와 JSON 파싱 개선:

```python
import subprocess
import json
import asyncio
from pathlib import Path
import os

class ClaudeCodeRunner:
    def __init__(self):
        self.context_file = Path(".github/claude/CLAUDE.md")
        self.max_retries = 3
        
    async def run_claude_command(self, prompt, options=None):
        """Claude Code CLI를 headless 모드로 실행"""
        cmd = [
            "claude",
            "-p",  # Headless mode
            "-",   # stdin에서 프롬프트 읽기
            "--output-format", "stream-json",
            "--max-turns", "1"
        ]
        
        # 추가 옵션 처리
        if options:
            if options.get('add_dirs'):
                for dir in options['add_dirs']:
                    cmd.extend(['--add-dir', dir])
                    
        # 컨텍스트 추가
        full_prompt = self._build_prompt_with_context(prompt)
        
        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdin=asyncio.subprocess.PIPE,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE
        )
        
        stdout, stderr = await process.communicate(input=full_prompt.encode())
        
        # JSON 스트림 파싱
        results = self._parse_json_stream(stdout.decode())
        
        return results
        
    def _parse_json_stream(self, output):
        """여러 JSON 객체를 포함한 스트림 파싱"""
        results = []
        for line in output.split('\n'):
            if line.strip():
                try:
                    results.append(json.loads(line))
                except json.JSONDecodeError:
                    continue
        return results
```

#### **2.3 자동 검증 및 피드백 루프**

AI 에이전트와 GitHub Actions의 조건부 실행 활용:

```yaml
# 워크플로우 내 검증 스텝
- name: Run tests and validation
  id: validation
  run: |
    # 언어별 테스트 실행
    if [ -f "pyproject.toml" ]; then
      ruff check . --fix
      pytest --tb=short
    elif [ -f "CMakeLists.txt" ]; then
      cmake -B build -DCMAKE_BUILD_TYPE=Debug
      cmake --build build
      ctest --test-dir build --output-on-failure
    fi
  continue-on-error: true

- name: AI feedback loop
  if: steps.validation.outcome == 'failure'
  run: |
    python .github/actions/claude-code-runner/scripts/run_claude_code.py \
      --task "fix-errors" \
      --error-log "${{ steps.validation.outputs.stderr }}" \
      --retry-count "${{ github.run_attempt }}"
```

#### **2.4 MCP (Model Context Protocol) 서버 활용**

MCP 서버를 통한 확장 기능 구현:

```python
# MCP 서버 설정 예시
mcp_config = {
    "servers": {
        "git": {
            "command": "npx",
            "args": ["@modelcontextprotocol/server-git"],
            "env": {"GIT_DIR": os.getcwd()}
        },
        "github": {
            "command": "npx", 
            "args": ["@modelcontextprotocol/server-github"],
            "env": {"GITHUB_TOKEN": os.environ.get("GITHUB_TOKEN")}
        }
    }
}
```

### **3. 보안 및 안정성 강화**

#### **3.1 권한 관리**

GitHub Actions의 models 권한 활용:

```yaml
permissions:
  contents: write
  issues: write
  pull-requests: write
  models: read  # AI 모델 접근 권한
```

#### **3.2 환경 변수 및 시크릿 관리**

```yaml
env:
  ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
  CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC: true  # 텔레메트리 비활성화
  BASH_DEFAULT_TIMEOUT_MS: 30000  # 타임아웃 설정
```

### **4. 단계별 구현 로드맵**

#### **Phase 1: 기본 인프라 구축 (1주)**
- Claude Code CLI 통합 스크립트 개발
- 기본 워크플로우 파일 생성
- CLAUDE.md 템플릿 작성

#### **Phase 2: 자동화 워크플로우 구현 (2주)**
- Issue 라벨 트리거 워크플로우
- CI 실패 자동 수정 워크플로우
- PR 자동 리뷰 워크플로우

#### **Phase 3: 피드백 루프 최적화 (1주)**
- 에러 파싱 및 재시도 로직
- 컨텍스트 관리 개선
- 성능 메트릭 수집

#### **Phase 4: 고급 기능 추가 (2주)**
- MCP 서버 통합
- 커스텀 슬래시 명령어
- 멀티 프로젝트 지원

### **5. 예상 효과**

| 메트릭 | 현재 | 예상 | 개선율 |
|:--|:--|:--|:--|
| **CI 실패 해결 시간** | 30분 | 5분 | 6x 빠름 |
| **코드 리뷰 시간** | 2시간 | 15분 | 8x 빠름 |
| **반복 작업 자동화율** | 20% | 80% | 4x 증가 |
| **개발자 인터럽트** | 10회/일 | 2회/일 | 5x 감소 |

### **6. 리스크 및 대응 방안**

1. **API 비용 관리**
   - 토큰 사용량 모니터링
   - 캐싱 전략 구현
   - 불필요한 호출 최소화

2. **컨텍스트 오버플로우**
   - 200K 토큰 제한 고려한 세션 관리
   - 작업 단위 세분화
   - 자동 컨텍스트 압축

3. **보안 이슈**
   - 코드 검토 단계 유지
   - 권한 최소화 원칙
   - 감사 로그 구현

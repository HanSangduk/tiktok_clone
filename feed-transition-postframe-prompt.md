# 작업: tiktok_clone 피드 sweep loop를 Transition + PostFrame 패턴으로 리팩토링

## 프로젝트 위치
/Users/straram/development/tiktok_clone/lib/features/feed/feed_screen.dart

## 배경 (정독 필수)

이 화면은 TikTok 스타일 vertical PageView 피드다.

이전 작업에서 `_evict` 함수의 `c.dispose()` 호출을
`WidgetsBinding.instance.addPostFrameCallback((_) => c.dispose())`로 감싸 끊김 현상은 해소됐다.
이유는 `dispose()`가 platform channel 동기 호출이라 UI 스레드를 5~30ms 블록하기 때문이었다.

이번 작업은 그 다음 단계로, `_syncPool` 함수 안의 **sweep loop**를 더 효율적인
**Transition (diff) 모델**로 갈아엎고, 그 과정에서 platform channel 호출 일부를
`addPostFrameCallback`으로 미루는 것이다.

## 현재 sweep 코드의 문제

위치: `feed_screen.dart`의 `_syncPool` 함수, 130~140줄 근처

```dart
// 5) sweep — pool 전체에 setVolume/play/pause 명시
_pool.forEach((k, c) {
  if (!c.value.isInitialized) return;
  if (k == newIdx) {
    c.setVolume(1.0);
    c.play();
  } else {
    c.setVolume(0);
    c.pause();
  }
});
```

문제점:
1. **매번 pool 전체 순회** — 5개 controller면 매 swipe마다 10번 platform channel 왕복
2. **불필요한 호출** — 이미 paused 상태인 4개에 또 pause() 호출 (state 캐시 비교 없음)
3. **O(N) 복잡도** — pool 크기 늘어나면 호출도 비례 증가
4. **방어적 self-healing 패턴** — sweep이 잘못된 state도 복구해주는 안전망이지만,
   정상 흐름에선 over-engineering

## 목표 패턴: Transition (Diff) + PostFrame

### 원칙 1: Diff만 처리
- 이전 active idx와 새 active idx, **딱 두 controller만 건드린다**
- 나머지는 이미 paused + volume 0 상태라고 가정 (invariant 유지)
- Platform channel 호출: O(N) → **O(1) = 최대 4번** (새 active 켜기 2번 + 이전 active 끄기 2번)

### 원칙 2: 사용자가 봐야 할 것만 즉시, 나머지는 PostFrame
- **새 active의 `play()`/`setVolume(1.0)`**: 사용자가 곧바로 봐야 하므로 즉시 호출
- **이전 active의 `pause()`/`setVolume(0)`**: 사용자가 인지 못 함, 다음 frame으로 미룸

### 원칙 3: Race 안전성
- postFrame 콜백 실행 시점에 `_prevActiveIdx`가 그 사이 또 바뀌었을 수 있음 → idempotent 가드
- `mounted` 가드로 화면 dispose 후 callback 보호
- controller가 evict로 사라졌을 수 있음 → null 체크

## 구현 가이드 (의사코드, 그대로 복붙 X — 비판적으로 검토할 것)

### 1) State 필드 추가
```dart
class _FeedScreenState extends ConsumerState<FeedScreen> {
  int? _prevActiveIdx;  // 새 필드. transition 모델의 진실 원천
  // 기존 _currentlyPlayingIdx와 통합 검토 필요 (아래 참조)
  ...
}
```

### 2) Sweep loop 블록 (현재 130~140줄)을 함수 호출로 교체
```dart
// _syncPool 안에서, 기존 5) sweep 블록 제거하고 아래로 대체
_applyActiveTransition(newIdx);
```

### 3) Transition 함수 신규 추가
```dart
void _applyActiveTransition(int newIdx) {
  if (_prevActiveIdx == newIdx) return;     // idempotent
  final oldIdx = _prevActiveIdx;
  _prevActiveIdx = newIdx;

  // ① 새 active는 즉시
  final next = _pool[newIdx];
  if (next != null && next.value.isInitialized) {
    next.setVolume(1.0);
    next.play();
  }

  // ② 이전 active 끄기는 다음 frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    if (_prevActiveIdx != newIdx) return;   // 그 사이 또 바뀌었으면 noop
    if (oldIdx == null) return;
    final prev = _pool[oldIdx];
    if (prev != null && prev.value.isInitialized) {
      prev.setVolume(0);
      prev.pause();
    }
  });
}
```

## 반드시 같이 정리할 invariant (자기 진단)

Transition 모델은 **"새 controller가 만들어질 때 이미 active 여부에 따라 state가 정확히 세팅돼있다"**
는 invariant를 전제로 한다. 다음을 확인하라:

### A. `_ensure` 함수 내부의 init 후 state 설정 (현재 211~212줄)
```dart
c.setVolume(i == _currentlyPlayingIdx ? 1.0 : 0.0);
if (i == _currentlyPlayingIdx) c.play();
```
- 이 코드가 `_currentlyPlayingIdx`를 보는데, transition 모델에선 `_prevActiveIdx`가 진실 원천
- 두 변수를 **하나로 통합**하거나, **항상 같은 값**을 가리키도록 강제해야 함
- 권장: `_currentlyPlayingIdx`를 제거하고 `_prevActiveIdx`로 통일

### B. `didChangeAppLifecycleState`의 `_currentlyPlayingIdx` 참조 (현재 68~77줄)
```dart
final active = _currentlyPlayingIdx;
if (active == null) return;
final ctrl = _pool[active];
```
- 이것도 `_prevActiveIdx`로 변경 필요

### C. `didHaveMemoryPressure`의 `_currentlyPlayingIdx` 참조 (현재 80~87줄)
```dart
final keep = _currentlyPlayingIdx;
```
- 동일하게 정리

### D. `_syncPool` 안의 다른 `_currentlyPlayingIdx` 참조 (현재 114줄)
```dart
_currentlyPlayingIdx = newIdx;
```
- transition 함수가 `_prevActiveIdx`를 세팅하므로, 이 라인은 제거 가능

## 절대 미루면 안 되는 것 (postFrame 금지선)

- **새 active의 `play()` / `setVolume(1.0)`**: 사용자가 영상을 즉시 봐야 하므로 즉시
- **gesture 처리, focus 변경, 사용자가 인지하는 모든 시각적 결과**
- 이미 `unawaited(...)`로 비동기 처리된 부분 (initialize 등)

## 작업 진행 방식 — 자문자답 루프

다음 사이클을 **결과가 안정될 때까지 반복**하라.

### 사이클 1회 = 5단계

1. **분석**: 변경 대상 코드와 인접 코드 정독. `_currentlyPlayingIdx`/`_prevActiveIdx` 참조 위치
   전수 조사 (grep 권장).

2. **자문 4가지** (변경 전):
   - Q1. invariant ("active가 아닌 controller는 항상 paused + volume 0")가 모든 진입점에서
         보장되는가? (init 직후, _ensure 후, evict 직전, app resume 직후 등)
   - Q2. `_prevActiveIdx`로 통합 시, 기존 `_currentlyPlayingIdx`를 보는 곳에서 의미 차이가 있는가?
         (예: "방금 settle된 idx" vs "현재 play 중인 idx" — 비동기 갭에서 다를 수 있음)
   - Q3. PostFrame 콜백 안에서 `_prevActiveIdx != newIdx` 가드만으로 race가 충분히 막히는가?
         (oldIdx pause를 미루는 사이 사용자가 oldIdx로 다시 swipe back할 경우 등)
   - Q4. `_evict`로 oldIdx의 controller가 사라진 상태에서 postFrame이 실행되면? null 체크 충분?

3. **적용**: Edit 도구로 변경. 한 번에 한 곳만. 순서 권장:
   - (a) `_prevActiveIdx` 필드 추가 + `_currentlyPlayingIdx` 통합 (이름 일관성 확보)
   - (b) `_applyActiveTransition` 함수 신규 추가
   - (c) `_syncPool`의 sweep 블록 → 함수 호출로 교체
   - (d) `_ensure`, lifecycle 콜백들의 변수 참조 정리
   - 각 (a)~(d) 사이에 코드가 컴파일 가능한 상태여야 함

4. **자검증 5가지** (변경 후):
   - V1. `flutter analyze` 통과 확인
   - V2. 모든 `_currentlyPlayingIdx` 참조가 일관되게 정리됐는지 grep으로 재확인
   - V3. 새 active → 이전 active → 다른 idx 순으로 가상의 swipe 시나리오를 머릿속으로 시뮬레이션,
         platform channel 호출 시점/횟수가 의도대로인지 추적
   - V4. 빠른 연속 swipe (5→6→7) 시나리오에서 postFrame race condition이 안 생기는지 검증
   - V5. App background → foreground 시나리오, memory pressure 시나리오에서 invariant가 유지되는지

5. **개선 또는 다음 후보로**: V1~V5에서 문제 발견 시 즉시 수정 후 V1~V5 반복.
   문제 없으면 완료.

### 종료 조건
- 위 5단계가 모두 통과
- 코드 컴파일 가능
- `flutter analyze` 깨끗
- sweep loop가 사라지고 transition 함수로 대체됨

## 검증 시나리오 체크리스트 (release/profile 모드에서 실기기 테스트용)

1. **정상 swipe**: 0→1→2→3 한 페이지씩 천천히. 영상 전환 부드러운가? 소리 즉시 전환되는가?
2. **빠른 연속 swipe**: 0→5 빠르게 fling. 중간 영상들 소리 새지 않고 마지막 영상만 재생되는가?
3. **느린 drag (50% 미만)**: 살짝 드래그 후 손 떼고 snap-back. 영상 계속 재생 유지되는가?
4. **스와이프 백**: 5→4→3 거꾸로. 이전 영상들이 정상 재생되는가?
5. **App background → foreground**: 다른 앱 갔다 돌아왔을 때 현재 영상만 재생되는가?
6. **Memory pressure**: (시뮬레이션 어려우면 생략 가능) didHaveMemoryPressure 후 invariant 유지?
7. **List 끝 도달**: loadMore 트리거되는 시점에 영상 전환 자연스러운가?

## 작업 후 금지 사항

- 새 문서 파일 생성 금지 (work_log P*.md는 글로벌 정책에 따라 자동 생성되는 건 OK)
- README 같은 거 새로 만들지 말 것
- 주석은 최소화. "왜 미뤘는지" 비자명한 곳에만 1줄
- `setPlaybackSpeed(0)` 같은 트릭 사용 금지 (Android ExoPlayer 호환 안 됨)
- 기존 `_evict`의 postFrame dispose 패턴 건드리지 말 것 (이미 안정적)

## 최종 산출물

1. 변경된 파일 목록 + diff 요약
2. 자문자답 루프 사이클별로 어떤 자문이 어떤 변경/거부로 이어졌는지 표
3. 위 검증 시나리오 체크리스트에 대한 코드 흐름 추적 결과
4. 통합/정리된 변수명과 그 이유 (예: `_currentlyPlayingIdx` → `_prevActiveIdx` 또는 반대)

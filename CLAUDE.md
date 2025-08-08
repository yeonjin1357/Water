# 물 마시기 리마인더 앱 프로젝트

## 프로젝트 개요

극도로 심플한 물 마시기 리마인더 앱 개발

## 기술 스택

- **Flutter** (Dart)
- 크로스 플랫폼 지원 (iOS/Android)
- 로컬 데이터 저장

## 차별화 전략: 극도의 미니멀리즘

기존 앱들이 너무 복잡한 점을 파고들어 "물 마시기에만 집중"하는 앱

### 핵심 원칙

- **딱 3개 화면**: 메인(물 추가), 설정, 통계
- 탭 한 번으로 250ml 추가
- 롱탭으로 커스텀 양 입력
- 불필요한 기능 제거 (칼로리, 카페인, 다이어트 연동 등)

## 주요 기능

1. **물 섭취 기록**
   - 원탭으로 빠른 기록
   - 일일 목표량 설정
2. **리마인더**
   - 주기적 알림
   - 시간대별 커스터마이징
3. **간단한 통계**
   - 일/주/월 통계
   - 목표 달성률

## 개발 방침

- 복잡한 기능보다 핵심 기능의 완성도에 집중
- 광고 없는 완전 무료 앱
- 직관적이고 깔끔한 UI/UX

## 경쟁 앱 분석

- 기존 앱들은 기능이 너무 많아 복잡함
- 단순히 물 마시기 습관만 기록하고 싶은 사용자층 존재
- 미니멀한 접근으로 차별화 가능

## 디자인 레퍼런스

### 1. Acqua Water Intake App

참고: https://dribbble.com/shots/22893437-Acqua-Water-Intake-App

### 2. Hydrify Water Tracker Reminder App

참고: https://dribbble.com/shots/23764426-Hydrify-Water-Tracker-Reminder-App-UI-Kit

#### Hydrify 주요 특징

- **그라데이션 배경**: 부드러운 파란색 그라데이션으로 깨끗하고 신선한 느낌
- **3D 일러스트레이션**: 입체적인 물방울과 유리컵 디자인으로 생동감 있는 UI
- **카드 기반 레이아웃**: 정보를 명확하게 구분하는 카드형 디자인
- **인터랙티브 요소**: 스와이프 제스처와 애니메이션이 풍부한 UX
- **깔끔한 통계 화면**: 차트와 그래프를 활용한 직관적인 데이터 시각화
- **다크모드 지원**: 눈의 피로를 줄이는 다크 테마 완벽 지원

### 핵심 UI 컨셉

1. **유리컵 메타포**

   - 메인 화면 중앙에 유리컵 일러스트
   - 물이 실제로 차오르는 듯한 시각적 피드백
   - 80% 달성률 등 퍼센티지 표시
   - 애니메이션으로 물이 부드럽게 차오르는 효과

2. **색상 팔레트 업데이트**

   - 메인 컬러: 민트그린 (#7FEFBD ~ #9CFFFA 그라데이션)
   - 서브 컬러: 파스텔 블루 (#87CEEB)
   - 물 표현: 투명도 있는 하늘색 (#87CEEB with 60% opacity)
   - 배경: 순백색 (#FFFFFF) 또는 아주 연한 그레이 (#FAFAFA)

3. **미니멀한 타이포그래피**
   - 레벨 표시: 작고 세련된 서체
   - 물 양 표시: 크고 굵은 숫자 (예: 2,000ml)
   - 부가 정보: 얇은 서체로 최소화

## 데이터 모델

### WaterIntake

- id: String
- amount: int (ml 단위)
- timestamp: DateTime
- note: String? (선택적 메모)

### UserSettings

- dailyGoal: int (기본 2000ml)
- reminderInterval: int (분 단위)
- reminderStartTime: TimeOfDay
- reminderEndTime: TimeOfDay
- defaultAmount: int (기본 250ml)
- isDarkMode: bool
- language: String (기본 'ko')

## 프로젝트 구조

```
lib/
├── models/       # 데이터 모델 클래스
├── screens/      # 화면 (main, settings, stats)
├── widgets/      # 재사용 가능한 컴포넌트
├── services/     # 로컬 저장소, 알림 서비스
├── utils/        # 헬퍼 함수, 날짜 처리 등
└── constants/    # 색상, 텍스트 상수, 테마
```

## 상태 관리

- **Provider 패턴** 사용 (복잡성 최소화)
- **전역 상태**: 일일 섭취량, 사용자 설정, 물 섭취 기록
- **로컬 상태**: UI 애니메이션, 임시 입력값, 폼 검증

## 데이터 저장

- **SharedPreferences**: 설정값, 간단한 사용자 선호도
- **SQLite (sqflite)**: 물 섭취 기록, 통계 데이터
- **백업**: 로컬 JSON 파일로 내보내기/가져오기 기능

## 성능 및 배터리 최적화

- 백그라운드 작업 최소화
- 알림은 시스템 스케줄러 활용 (flutter_local_notifications)
- 애니메이션은 60fps 유지하되 필요시에만 실행
- 메모리 누수 방지를 위한 dispose() 철저히 구현

## Dart 코딩 규칙

### 명명 규칙

- **클래스명**: PascalCase (예: `WaterIntake`)
- **파일명**: snake_case (예: `water_intake.dart`)
- **변수/함수**: camelCase (예: `dailyGoal`, `calculateProgress()`)
- **상수**: lowerCamelCase 또는 SCREAMING_SNAKE_CASE (예: `defaultAmount` 또는 `MAX_WATER_AMOUNT`)
- **Private 멤버**: 언더스코어로 시작 (예: `_privateMethod()`)

### 필수 준수 사항

```dart
// ✅ 좋은 예시
class WaterIntakeService {
  final DatabaseHelper _dbHelper;
  late final StreamController<int> _intakeController;

  // null safety 항상 고려
  Future<int?> getTodayIntake() async {
    try {
      final result = await _dbHelper.query();
      return result?.amount;
    } catch (e) {
      debugPrint('Error: $e');
      return null;
    }
  }

  // dispose 메서드 구현
  void dispose() {
    _intakeController.close();
  }
}

// ❌ 피해야 할 예시
class water_intake {  // 잘못된 명명
  var dbHelper;  // 타입 미지정

  getTodayIntake() {  // 반환 타입 미지정
    // try-catch 없음
    return dbHelper.query();
  }
  // dispose 없음
}
```

### 주요 체크리스트

1. **Null Safety**: 모든 변수에 null 가능성 명시 (`?`, `!`, `late`)
2. **타입 명시**: `var` 대신 명확한 타입 사용
3. **에러 처리**: try-catch 블록으로 예외 처리
4. **비동기 처리**: async/await 올바른 사용
5. **메모리 관리**: StreamController, AnimationController 등은 반드시 dispose
6. **const 활용**: 가능한 곳에서 const 생성자 사용
7. **주석**: 복잡한 로직에만 간단한 주석 추가

### 자주 하는 실수 방지

```dart
// setState 중복 호출 방지
if (mounted) {
  setState(() {
    // UI 업데이트
  });
}

// BuildContext 잘못된 사용 방지
// ❌ 비동기 후 context 사용
await someAsyncWork();
Navigator.push(context, ...);  // 위험!

// ✅ 올바른 사용
await someAsyncWork();
if (context.mounted) {
  Navigator.push(context, ...);
}

// List 초기화
// ❌
List<String> items = [];  // growable list

// ✅ 불변 리스트가 필요한 경우
const List<String> items = [];
// 또는
final List<String> items = List.unmodifiable([]);
```

## 개발 작업 원칙 (Claude Code 사용 시)

### 점진적 개발 접근

- **한 번에 하나의 기능**에만 집중
- 대량의 코드 변경 시 단계별로 나누어 작업
- 각 단계마다 검증 후 다음 단계 진행

### 작업량 제한

- 한 번에 **최대 100-150줄** 정도의 코드만 추가/수정
- 복잡한 기능은 여러 단계로 분할
- 큰 작업 요청 시 다음과 같이 응답:
  ```
  "현재 [기능명]까지 구현했습니다.
  전체 작업이 많아 단계적으로 진행 중입니다.
  계속 진행하시려면 말씀해 주세요."
  ```

### 품질 유지 방법

1. **작은 단위로 작업**: 한 번에 한 파일 또는 한 기능
2. **즉시 테스트**: 각 변경 후 바로 실행 확인
3. **단계별 커밋**: 의미 있는 단위로 구분
4. **명확한 구분**: UI, 로직, 데이터 레이어 분리 작업

## 개발 진행 상황 (2025-08-08 최종 업데이트)

### ✅ 완료된 작업

#### 1. **Phase 1: 유리컵 UI 구현**

- CustomPainter로 리얼한 유리컵 렌더링
- 물이 차오르는 부드러운 애니메이션 (800ms)
- 다층 웨이브로 자연스러운 물결 효과
- 물이 컵 모양을 정확히 따라 채워지도록 구현

#### 2. **메인 화면 UI 개선**

- Acqua 앱 디자인 레퍼런스 적용
- 단일 "Drink" 버튼으로 간소화
- 음료 설정 아이콘 (종류별 아이콘 변경)
- 하단 고정 히스토리 섹션

#### 3. **음료 설정 기능**

- 5가지 음료 선택 (Water, Tea, Coffee, Juice, Milk)
- 프리셋 양 선택 (100ml ~ 500ml)
- 커스텀 양 입력 가능
- 선택한 음료에 따라 아이콘/색상 변경

#### 4. **히스토리 기능**

- 메인 화면: 최근 기록 표시 (스크롤 가능)
- 각 항목 삭제 기능 (확인 다이얼로그)
- View All: Bottom Sheet로 전체 히스토리
- 날짜별 그룹핑 (Today, Yesterday, 날짜)
- 일일 총 섭취량 표시

#### 5. **Phase 2: 데이터 영구 저장**

- SQLite 데이터베이스 연동 (sqflite)
- DatabaseHelper 클래스 완성
- Provider와 DatabaseHelper 연동
- SharedPreferences로 설정값 저장/로드
- 앱 재시작 시 데이터 자동 로드
- 전체 과거 기록 조회 기능

#### 6. **Phase 3: 통계 화면 구현**

- fl_chart 라이브러리 활용한 차트 구현
- 상단 차트 (Drink Completion): 일일 달성률 표시
  - 바 차트/라인 차트 전환 가능
  - y축: 0~100% 고정
  - x축: 날짜 표시
- 하단 차트 (Hydrate): 일일 섭취량(ml) 표시
  - 바 차트/라인 차트 전환 가능
  - y축: 데이터에 따라 동적 조정
  - 모든 값을 L 단위로 통일 표시
- 음료 종류별 파이 차트
- 주간/월간/연간 통계 뷰
  - 주간: 7일 표시
  - 월간: 5개 주(W1~W5)로 그룹핑
  - 연간: 12개월 표시
- 터치 시 툴팁으로 상세 데이터 표시
- 미래 날짜로 이동 불가 처리
- 라인 차트 0 이하 렌더링 방지 (preventCurveOverShooting)

### 🔧 진행 중인 작업

- 없음 (Phase 3 완료)

### 📋 남은 작업

#### Phase 3: 통계 및 분석 ✅ (완료)

- [x] 일/주/월/년 통계 차트
- [x] 목표 달성률 계산
- [x] 음료별 섭취량 분석
- [ ] 연속 달성 일수 트래킹 (미구현)

#### Phase 4: 설정 화면

- [ ] 일일 목표량 변경
- [ ] 다크모드 실제 적용
- [ ] 언어 설정 (한/영)
- [ ] 데이터 백업/복원

#### Phase 5: 알림 기능

- [ ] flutter_local_notifications 설정
- [ ] 주기적 알림 스케줄링
- [ ] 시간대별 알림 커스터마이징
- [ ] 알림 on/off 설정

#### Phase 6: 추가 기능

- [ ] 챌린지 시스템 구현
- [ ] 위젯 추가 (홈 화면 위젯)
- [ ] 통계 공유 기능
- [ ] 앱 아이콘 및 스플래시 화면

### 최근 개선사항 (2025-08-08)

#### UI/UX 개선

- 홈 화면 우측 하단 통계 버튼 제거 (하단 탭바와 중복)
- 차트 터치 인터랙션 추가 (툴팁 표시)
- 미래 날짜 네비게이션 제한
- 라인 차트 곡선 최적화

#### 기술적 구현

- **차트 라이브러리**: fl_chart 5.0.0 사용
- **데이터 그룹핑**: 월간 데이터를 주 단위로, 연간 데이터를 월 단위로 그룹핑
- **동적 스케일링**: 하단 차트 y축을 데이터에 맞게 자동 조정
- **성능 최적화**: 불필요한 리빌드 방지, dispose 메서드 구현

### 기술 부채

- [ ] 에러 처리 강화
- [ ] 테스트 코드 작성
- [ ] 성능 최적화
- [ ] 코드 리팩토링 (중복 제거)
- [ ] 접근성 개선 (스크린 리더 지원)

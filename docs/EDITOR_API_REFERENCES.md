# 편집 기능 개선 — 공식 자료와 구현 결정

대상 버전: Quick Swap 0.3.6 (Factorio 2.0), 0.3.7 (Factorio 2.1).
편집 조작에 관한 API 결정은 0.3.4/0.3.5와 동일하다.

## 실제 단축키 표시

Factorio 공식 위키의 [Localisation 가이드](https://wiki.factorio.com/Tutorial:Localisation#Built-in_parameters)는
플레이어별 키 설정을 Lua에서 읽는 대신 `__CONTROL__name__` 치환을 사용하도록 설명한다.
이에 따라 가로 양방향·세로 양방향 네 Custom Input의 이름을 locale에 지정한다.
게임이 현재 입력 설정에 맞는 표기와 미지정 상태를 렌더링한다. 별도의 키 설정 복사본은 저장하지 않는다.

## 그룹 순서 변경

공식 [Logistic groups 소개](https://www.factorio.com/blog/post/fff-382)를 UI 구성의 참고로 사용했다.
기본 게임의 물류 그룹 UI와 모드용 사용자 정의 GUI는 같은 인터페이스가 아니다.

공개 API의 [LuaGuiElement.drag_target](https://lua-api.factorio.com/latest/classes/LuaGuiElement.html#drag_target)은
screen 최상위 창을 움직이는 기능이며, 내부 그룹이나 슬롯을 재정렬하는 기능이 아니다.
검토한 2.1.17 API에는 기본 물류 GUI의 드래그 정렬을 사용자 정의 섹션에 연결하는 인터페이스가 없다.

따라서 작은 위·아래 버튼과 공식 [swap_children](https://lua-api.factorio.com/latest/classes/LuaGuiElement.html#swap_children)을 사용한다.
그룹 데이터와 화면 순서를 함께 바꾸고 탐색 색인을 무효화한다. 그룹 ID는 변경하지 않는다.
순서를 바꿀 때 전체 GUI를 다시 만들지 않으며 첫 그룹의 위 버튼과 마지막 그룹의 아래 버튼은 비활성화한다.
이 조작은 기본 물류 UI의 드래그 조작을 그대로 복제한 것은 아니다.

## 아이템 위치 이동·교환 — 재확인 후 제거

공식 [2.0.35 변경 기록](https://forums.factorio.com/viewtopic.php?t=126984)은 기본 필터 GUI의
드래그 재정렬을 설명하지만, 사용자 정의 choose-elem-button에 이를 켜는 공개 옵션은 없다.

2026-09-13에 공식 [LuaGuiElement 문서](https://lua-api.factorio.com/latest/classes/LuaGuiElement.html)와
[GUI 이벤트 목록](https://lua-api.factorio.com/latest/events.html), 설치된 2.1.17의 runtime-api.json을 다시 확인했다.

- `drag_target`: screen 최상위 frame 이동용이다. 내부 물류 슬롯을 드래그 정렬하는 기능이 아니다.
- GUI 이벤트 목록에는 사용자 정의 슬롯의 드래그 시작·드롭·재정렬 이벤트가 없다.
- 2.1의 `inventory` 위젯은 LuaInventory를 표시하고 인벤토리 작업 이벤트를 제공한다.
  물류 필터 그룹의 드래그 재정렬 API나 기존 물류 섹션 편집기를 임베드하는 기능은 아니다.

따라서 사용자 요청대로 0.3.4/0.3.5에서 클릭 방식의 위치 편집 체크박스, 출발 선택·강조,
슬롯 이동·교환 함수와 안내 문구를 제거한다. 대체 드래그 조작은 구현하지 않는다.
일반 슬롯 클릭 선택과 우클릭 비우기, 실제 단축키 표시, 그룹 위·아래 순서 변경은 유지한다.
이전 버전에서 이미 적용한 배열의 아이템 좌표는 수정하지 않는다.

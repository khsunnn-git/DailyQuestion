# Daily Question Design System (Flutter)

## Included Tokens
- Spacing: `0, 2, 4, 6, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44, 48, 56, 64, 72, 80, 96, 112, 128, 160, 200`
- Radius: `0, 2, 4, 8, 16, 20, 24, 32, full(999)`
- Elevation:
  - Level1: `#0000000A`, `(0,2)`, blur `4`
  - Level2: `#00000014`, `(0,4)`, blur `8`
  - Level3: `#00000026`, `(0,8)`, blur `16`
- Typography: SUIT Variable
  - `Button/Small = 15, Medium(500), line-height 100%`
- Icon:
  - Sizes: `16, 20, 24, 40`
  - Base color: `Grey900 #111111`
- Buttons:
  - Hierarchy: Primary/Secondary/Tertiary/Outline/Noline/Text (+ `-R`)
  - Types: Text-only, Text-Icon, Icon-only
  - Sizes: XLarge/Large/Medium/Small
  - States: Default, Hovered, Disabled
- Controls:
  - Segmented: selected/default styles, pill radius, Level1 shadow
  - Tab: selected underline, 3/4/5 tab layout support tokens
  - Radio: sm(20), md(24), icon-only/icon+label token values
  - Toggle: icon-only(58) and icon+label token values
- Header/Navigation:
  - Header: back-title-edit layout (`390x65`)
  - Navigation-bar: 4-tab bottom navigation (`390x76`) with focused/unfocused states
- Popup/Badge/Tag:
  - Popup: alert/confirm/delete dialog base + dimmed overlay (`Dark 72%`)
  - Streak pill card: "연속 N일째 기록중" style card
  - Bucket badges: accent color chips
  - Bucket tags: 5 states (`add_default`, `1ormore_add`, `Delete_add`, `default`, `Delete`) with `height 38`
- Loading:
  - Size: `68`
  - Source: `https://lottiefiles.com/animations/loading-5ajWehbePd`
  - Fallback image token included
- Tooltip/Toast/Speechbubble:
  - Tooltip: 6 directions (`up/down` + `left/center/right`), `68x31`, dark 80%
  - Toast: 1-line (`242x36`), 2-line (`212x56`), `max-width 290`, Level2 shadow
  - Speechbubble: 4 directions (`left/right/up/down`), `primary/white` variants
- Inputs:
  - TextInput: `md(58)` / `sm(48)`, states (`default/focus/success/error/disabled`)
  - SelectField: `350x56`, states (`default/focus/disabled`)
  - TextArea: `bottomSheet(156)` / `textArea(402)` variants
  - TextButtonField: input + action button (`85x58`) combined component
- Dropdown/Menu:
  - Dropdown-item states: `default / hovered / selected`
  - Dropdown-menu sizes: `lg(110x148)`, `md(84x148)`, `sm(84x104)`
  - Hover background: `Grey50`, selected color: `Blue500`, check icon supported
  - Shadow: `lg=Level2`, `md/sm=Level3`
- Cards:
  - Daily Streak Check: `350x255`, radius `16`, Level1 shadow, 주간 점 상태(`default/missed/success`)
  - Record Preview: `350x458`, radius `24`, 날짜/질문/본문/태그 칩 구조
  - Insight Card: `342x197` base, 아이콘 + 제목 + 리포트 본문
  - Today's Records: `320x154`, states(`default/none`)
  - Today's Other Records: `350x205`, 본문 + 하단 작성자 라벨

## Brand Themes
- Blue (default)
- Green
- Brown
- Purple

## Note
- Green800 is fixed to `#006D3A` per latest design decision.
- Accent Cyan (banner) is fixed to `#D0F3F9`.

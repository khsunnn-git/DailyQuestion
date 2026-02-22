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

## Brand Themes
- Blue (default)
- Green
- Brown
- Purple

## Note
- Green800 is fixed to `#006D3A` per latest design decision.

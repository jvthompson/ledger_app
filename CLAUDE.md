# Ledger

Excel-style spreadsheet Flutter app, Windows desktop only. Sibling project to `C:\Dev\Projects\write\` (a Word-like app) — Ledger's menu bar/toolbar chrome is intentionally styled to match Write's, but no code is shared or imported between the two; do not modify Write from this project.

## Standing instructions

- **After finishing any plan or feature**, build a Windows release build and copy it to `C:\Ledger\`:
  ```
  flutter build windows
  ```
  Then copy the contents of `build\windows\x64\runner\Release\` to `C:\Ledger\` (overwrite existing files). Create `C:\Ledger\` if it doesn't exist.

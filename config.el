;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "Luca Rhee"
      user-mail-address "lucarhee@gmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 15)
      doom-variable-pitch-font (font-spec :family "Noto Sans CJK KR" :size 15)
      doom-big-font (font-spec :family "D2CodingLigature Nerd Font" :size 32))

;; 줄 번호
(setq display-line-numbers-type 'relative)

;; ─── 한글 폰트 ───────────────────────────────────────
;; doom-font 크기가 바뀔 때마다(초기 로드, doom/reload-font,
;; doom-big-font-mode 토글) 같이 재적용되도록 after-setting-font-hook에 건다.
;; (고정 :size로 박아두면 발표용 doom-big-font-mode를 켰을 때 한글만
;;  이전 크기로 남아 라틴 문자와 크기가 어긋난다.)
(defun +my/setup-cjk-fonts-h ()
  (let ((size (font-get (face-attribute 'default :font) :size)))
    ;; 고정폭 (코드블록) 한글
    (set-fontset-font t 'hangul
                      (font-spec :family "D2CodingLigature Nerd Font" :size size))
    ;; 심볼 fallback (org-modern 불릿, nerd-icons 등)
    (set-fontset-font t 'symbol
                      (font-spec :family "Symbols Nerd Font Mono") nil 'append)))
(add-hook 'after-setting-font-hook #'+my/setup-cjk-fonts-h)

;; 폰트가 섞이면(JetBrainsMono ↔ D2Coding) 메트릭 차이로 줄 높이가
;; 미묘하게 들쭉날쭉해 보이는 걸 보정 (테이블에서 특히 두드러짐)
(setq-default line-spacing 0.1)

;; ─── org +pretty 설정 ────────────────────────────────
(after! org
  (global-org-modern-mode))

(after! org-modern
  ;; 헤딩 bullets
  (setq org-modern-fold-stars '(("▶" . "▼") ("▷" . "▽") ("■" . "●") ("□" . "○") ("▣" . "◎")))


  ;; 테이블, 블록 등 스타일
  (setq org-modern-table nil
        org-modern-block t
        org-modern-keyword t
        org-modern-timestamp t))

;; 한글 조사가 붙어도 꾸밈이 적용되게 한다.
(after! org
  (setcar (nthcdr 1 org-emphasis-regexp-components)
          "-[:alnum:][:space:].,:!?;'\")}\\[가-힣")
  (org-set-emph-re 'org-emphasis-regexp-components
                   org-emphasis-regexp-components))

;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-nord)

;; [수정] 원래 파일엔 display-line-numbers-type이 위에서 'relative로,
;; 여기서 다시 t로 두 번 설정돼 있었음 (나중 설정이 이겨서 relative가 무시됨).
;; 상단에서 이미 relative로 설정했으므로 여기 있던 중복 라인은 삭제함.
;; (설명만 남겨둠: relative를 원하면 이 줄을 다시 추가하지 말 것)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
;; roam directory
(setq org-directory "~/org/")
(setq org-roam-directory (file-truename "~/org/roam/"))

;; ─── org-agenda: 어떤 파일들을 "일정/할일" 대상으로 볼지 ──────
;; roam/projects 아래 모든 프로젝트 파일 + roam/daily 아래 모든 데일리 노트 +
;; org-directory 루트의 inbox.org를 agenda 스캔 대상으로 포함.
;; => 프로젝트 파일에 SCHEDULED/DEADLINE을 걸어두면 org-agenda에 자동으로 뜬다.
;;    (매일 노트에 할일을 다시 옮겨 적을 필요 없음)
(after! org
  (setq org-agenda-files
        (append
         (directory-files-recursively (expand-file-name "roam/projects" org-directory) "\\.org$")
         (directory-files-recursively (expand-file-name "roam/daily" org-directory) "\\.org$")
         (list
          (expand-file-name "inbox.org" org-directory)))))

;; TODO 상태 흐름: TODO(할일) -> NEXT(다음 착수) -> DOING(진행중)
;; -> WAIT(대기, 이유 기록) -> REVIEW(검토 대기) -> DONE/CANCELED
(after! org
  (setq org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "DOING(g)" "WAIT(w@)" "REVIEW(r)"
           "|" "DONE(d!)" "CANCELED(c@)"))))

;; DONE 처리 시 완료 시각 기록, 로그/clock 내역은 별도 drawer에 접어서 보관
;; (본문이 로그로 지저분해지는 것 방지)
(after! org
  (setq org-log-done 'time
        org-log-into-drawer t
        org-clock-into-drawer t))

;; [버그 수정] 원본에는 ("admin" . ?a) 뒤에 닫는 괄호가 4개(")))))")였음.
;; 필요한 건 3개(pair 1 + 리스트 1 + setq 1)라서 괄호 하나가 남았고,
;; 이 상태로는 elisp 리더가 "Invalid read syntax" 에러를 내며
;; 이 지점 이후 config.el 전체(org-roam 설정, 캡처 템플릿, 키바인딩)가
;; 로드되지 않았을 가능성이 높음. 괄호 개수를 바로잡음.
;;
;; [추가] "course"(강좌) 태그를 새로 추가함. 기존엔 강좌 프로젝트를
;; writing/dev 중 어디에 넣어야 할지 애매했는데, 별도 타입으로 분리.
;; 한 프로젝트가 여러 성격을 가지면(예: 영상+글쓰기) 캡처 후 파일 상단
;; #+filetags 줄에 태그를 수동으로 더 추가하면 됨 (예: :project:video:writing:)
(after! org
  (setq org-tag-alist
        '(("project" . ?p)
          ("dev" . ?d)      ;; 개발 (웹/앱)
          ("video" . ?v)    ;; 영상 개발 (일상 에피소드)
          ("writing" . ?w)  ;; 글쓰기 (소설, 프로그래밍 책)
          ("course" . ?c)   ;; 강좌 제작
          ("image" . ?i)    ;; 이미지 개발
          ("research" . ?r) ;; 조사
          ("admin" . ?a))))  ;; 관리/정리 (프로젝트에 속하지 않는 잡무)

;; ─── org-agenda 커스텀 뷰 ────────────────────────────
;; SPC n a 로 org-agenda 진입 후, 아래 단축키로 바로 원하는 뷰 진입.
;;
;; "p" = 프로젝트 대시보드: project 태그 + 타입별 태그로 그룹핑해서
;;       "지금 각 프로젝트에 뭐가 남았는지"를 한 화면에서 훑어봄.
;;       (주간 리뷰 때 유용)
;;
;; "t" = 오늘 할일: 오늘 스케줄된 항목 + 아직 스케줄 안 된 프로젝트 TODO +
;;       project 태그가 없는(=프로젝트 외 잡무) TODO를 함께 보여줌.
;;       (매일 아침 루틴에서 사용)
(setq org-agenda-custom-commands
      '(("p" "프로젝트 대시보드 (타입별)"
         ((tags-todo "project+writing"
                     ((org-agenda-overriding-header "✍️  글쓰기 (소설 / 프로그래밍 책)")))
          (tags-todo "project+course"
                     ((org-agenda-overriding-header "🎓 강좌 제작")))
          (tags-todo "project+video"
                     ((org-agenda-overriding-header "🎬 영상 / 에피소드")))
          (tags-todo "project+dev"
                     ((org-agenda-overriding-header "💻 웹/앱 개발")))
          (tags-todo "project+image"
                     ((org-agenda-overriding-header "🎨 이미지")))))

        ("t" "오늘 할일 (프로젝트 + 잡무)"
         ((agenda "" ((org-agenda-span 1)
                      (org-agenda-overriding-header "📅 오늘 스케줄된 항목")))
          (tags-todo "project"
                     ((org-agenda-overriding-header "📂 프로젝트 TODO (아직 날짜 미지정)")
                      (org-agenda-todo-ignore-scheduled 'all)))
          (tags-todo "-project"
                     ((org-agenda-overriding-header "🧹 잡무 (프로젝트에 속하지 않는 할일)")))))))

(after! org-roam
  (require 'org-roam-dailies)

  (setq org-roam-dailies-directory "daily/")

  (setq org-roam-node-display-template
        "${title:60} ${tags:20}")

  ;; 프로젝트 노트 캡처 템플릿: 새 프로젝트 시작 시 이 템플릿으로 생성.
  ;; "단계별 목표" 아래 M1/M2... 형태로 마일스톤을 두고, 그 아래에
  ;; 실제 실행 TODO를 넣는 구조 (마일스톤 자체는 상태 추적용 헤딩,
  ;; 실행 항목은 TODO 키워드 + SCHEDULED로 agenda에 노출).
  ;; %^{Type|...} 프롬프트로 project 태그 외 타입 태그를 하나 고르게 함.
  (setq org-roam-capture-templates
        '(("p" "project" plain "%?"
           :target
           (file+head "projects/${slug}.org"
                      "#+title: ${title}
#+filetags: :project:%^{Type|dev|video|writing|course|image}:
#+category: ${title}

* 개요
- 목표(이유):
- 결과물 목록:
- 완료 조건:
- 제약 조건:

* 관련 링크
- 저장소:
- 관련 링크:

* 단계별 목표
** TODO M1

* 참고 설명
")
           :unnarrowed t)

          ("n" "note" plain "%?"
           :target
           (file+head "notes/${slug}.org"
                      "#+title: ${title}\n#+filetags: :note:\n")
           :unnarrowed t)))

  ;; 데일리 노트 템플릿.
  ;; "작업 목록"은 타입별 섹션(글/개발/그림/영상)에 더해
  ;; [추가] "기타 할일" 섹션을 새로 넣음 — 프로젝트에 속하지 않는
  ;; 잡무(약속, 행정 처리 등)를 담는 자리. 기존 템플릿엔 이 자리가
  ;; 없어서 잡무를 어디 적을지 애매했던 부분을 보완.
  (setq org-roam-dailies-capture-templates
        '(("d" "daily" plain ""
           :target
           (file+head "%<%Y-%m-%d>.org"
                      "#+title: %<%Y-%m-%d %a>
#+filetags: :daily:

* 작업 목록
** 글 작업
- [ ]
** 개발 작업
- [ ]
** 그림 작업
- [ ]
** 영상 작업
- [ ]
** 기타 할일 (프로젝트 외)
- [ ]

* 작업 기록
** 08:00 - 12:00
-
** 13:00 - 17:00
-
")
           :unnarrowed t)

          ("l" "log" entry
           "* %<%H:%M> %^{Project} :%^{Type|dev|video|writing|course|image}:\n%?"
           :target
           (file+head "%<%Y-%m-%d>.org"
                      "#+title: %<%Y-%m-%d %a>\n#+filetags: :daily:\n\n"))))

  (org-roam-db-autosync-mode))

(defun my/org-roam-find-project ()
  "Find or create an org-roam project note."
  (interactive)
  (org-roam-node-find
   nil nil
   (lambda (node)
     (member "project" (org-roam-node-tags node)))
   nil
   :templates (list (assoc "p" org-roam-capture-templates))))

;; [추가] index.org 진입점.
;; org-roam 노드로 만들지 않고 org-directory 루트에 두는 일반 org 파일로 함
;; (roam 검색 대상에 섞이지 않고, "고정된 홈 화면" 역할만 하도록).
;; 프로젝트 목록/상태를 사람이 직접 큐레이션하는 용도이며,
;; 실행할 할일 자체는 여전히 agenda(SPC n a)가 담당함.
;; 파일이 없으면 find-file이 새로 만들어줌.
(defun my/open-index ()
  "프로젝트 목록과 자주 쓰는 진입점을 모아둔 index.org를 연다."
  (interactive)
  (find-file (expand-file-name "index.org" org-directory)))

(map! :leader
      (:prefix ("n" . "notes")
       :desc "Find node"        "f" #'org-roam-node-find
       :desc "Insert node"      "i" #'org-roam-node-insert
       :desc "Project note"     "p" #'my/org-roam-find-project
       :desc "Today diary"      "d" #'org-roam-dailies-goto-today
       :desc "Capture today"    "D" #'org-roam-dailies-capture-today
       :desc "Index"            "I" #'my/open-index
       :desc "Agenda"           "a" #'org-agenda))

;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `with-eval-after-load' block, otherwise Doom's defaults may override your
;; settings. E.g.
;;
;;   (with-eval-after-load 'PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look them up).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; Don't ask when you exit.
(setq confirm-kill-emacs nil)

;; js/ts settings
(setq js-indent-level 2)
(setq typescript-ts-mode-indent-offset 2)

(after! web-mode
  (setq web-mode-markup-indent-offset 2
        web-mode-code-indent-offset 2
        web-mode-css-indent-offset 2))

;; normal일 때 영문으로 자동 전환
;; insert일 때 한글 자동 전환
(defvar my/default-im "com.apple.keylayout.ABC")
(defvar my/korean-im "com.apple.inputmethod.Korean.390Sebulshik")

(defun my/im-select (im)
  (call-process "im-select" nil nil nil im))

(add-hook 'evil-insert-state-entry-hook
          (lambda () (my/im-select my/korean-im)))

(add-hook 'evil-insert-state-exit-hook
          (lambda () (my/im-select my/default-im)))

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
;; accept.
(setq doom-font (font-spec :family "JetBrainsMono Nerd Font" :size 15)
      doom-variable-pitch-font (font-spec :family "Noto Sans CJK KR" :size 15)
      doom-big-font (font-spec :family "D2CodingLigature Nerd Font" :size 32))

;; 줄 번호
(setq display-line-numbers-type 'relative)

;; ─── 한글 폰트 ───────────────────────────────────────
;; doom-font 크기가 바뀔 때마다(초기 로드, doom/reload-font,
;; doom-big-font-mode 토글) 같이 재적용되도록 after-setting-font-hook에 건다.
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
;; 미묘하게 들쭉날쭉해 보이는 걸 보정
(setq-default line-spacing 0.1)

;; ─── org +pretty 설정 ────────────────────────────────
(after! org
  (global-org-modern-mode))

(after! org-modern
  (setq org-modern-fold-stars '(("▶" . "▼") ("▷" . "▽") ("■" . "●") ("□" . "○") ("▣" . "◎")))
  (setq org-modern-table nil
        org-modern-block t
        org-modern-keyword t
        org-modern-timestamp t))

;; 한글 조사가 붙어도 꾸밈(*굵게*는 등)이 적용되게 한다.
(after! org
  (setcar (nthcdr 1 org-emphasis-regexp-components)
          "-[:alnum:][:space:].,:!?;'\")}\\[가-힣")
  (org-set-emph-re 'org-emphasis-regexp-components
                   org-emphasis-regexp-components))

(setq doom-theme 'doom-nord)


;;; ════════════════════════════════════════════════════════════════
;;; ORG 워크플로
;;; ════════════════════════════════════════════════════════════════
;;
;; 원칙 (자세한 이유는 매뉴얼 참고)
;;  1. 할일(TODO)은 "한 곳"에만 있다:
;;       프로젝트 일 → projects/<이름>/tasks.org
;;       프로젝트 외 일 → tasks.org,  약속/반복 → calendar.org
;;       아직 모르겠음 → inbox.org (나중에 refile)
;;  2. daily 노트는 할일 목록이 아니라 "기록"이다 (agenda 대상 아님).
;;  3. roam/notes 는 프로젝트가 끝나도 남을 지식.
;;     프로젝트가 끝나면 버려도 되는 자료는 projects/<이름>/ 안에 둔다.
;;  4. "오늘 뭐 하지?"는 파일을 뒤지지 않고 agenda(SPC n t)가 답한다.
;;
;; ~/org/
;; ├── index.org  inbox.org  tasks.org  calendar.org  projects.org
;; ├── projects/<slug>/{index,plan,tasks,...}.org
;; ├── roam/daily/  roam/notes/
;; └── archive/

(setq org-directory "~/org/")

;; org-roam 디렉토리를 ~/org 전체로 둔다.
;; → 각 프로젝트의 index.org(파일 상단에 :ID: 있음)도 roam 노드가 되어
;;   roam 노트에서 [[id:..]]로 링크 걸 수 있고, 프로젝트 index에서
;;   백링크(SPC n r r)로 "이 프로젝트와 관련된 노트"를 모아 볼 수 있다.
;; ID가 없는 파일(tasks.org, outline.org 등)은 노드가 되지 않으므로
;; 노드 검색(SPC n f)이 지저분해지지 않는다.
(setq org-roam-directory (file-truename "~/org/"))

(defun my/org-path (&rest parts)
  "org-directory 아래 경로를 만든다. (my/org-path \"projects\" \"x\")"
  (expand-file-name (mapconcat #'identity parts "/") org-directory))

(defun my/project-dirs ()
  "projects/ 아래 프로젝트 디렉토리 목록."
  (let ((root (my/org-path "projects")))
    (when (file-directory-p root)
      (seq-filter #'file-directory-p
                  (directory-files root t "\\`[^.]")))))

;; ─── agenda 대상 파일 ───────────────────────────────
;; - inbox / tasks / calendar + projects/ 아래 모든 .org
;; - roam/daily 는 넣지 않는다 (기록용. 쌓일수록 agenda가 느려지고,
;;   같은 할일이 데일리와 프로젝트 파일에 중복되는 원인이 됨)
;; - archive/ 는 넣지 않는다 (끝난 일은 화면에서 사라져야 함)
;; - org-agenda를 열 때마다 다시 계산 → 새 프로젝트를 만들어도
;;   Emacs 재시작 없이 바로 agenda에 잡힌다.
(defun my/agenda-files ()
  (seq-filter
   #'file-exists-p
   (append (list (my/org-path "inbox.org")
                 (my/org-path "tasks.org")
                 (my/org-path "calendar.org"))
           (let ((root (my/org-path "projects")))
             (when (file-directory-p root)
               (directory-files-recursively root "\\.org\\'"))))))

(defun my/refresh-agenda-files (&rest _)
  (setq org-agenda-files (my/agenda-files)))

(after! org
  (my/refresh-agenda-files)
  (advice-add 'org-agenda :before #'my/refresh-agenda-files)
  (advice-add 'org-todo-list :before #'my/refresh-agenda-files))

;; ─── TODO 상태 ──────────────────────────────────────
;; TODO   언젠가 할 일 (아직 손 안 댐)
;; NEXT   바로 다음에 착수할 일 — 프로젝트당 1~2개만
;; DOING  지금 하는 중 (clock-in 하면 자동으로 DOING)
;; WAIT   남/외부 때문에 막힘 (들어갈 때 이유 메모)
;; REVIEW 내가 할 건 끝, 검토/피드백 대기 (편집자, 코드리뷰, 감수)
;; DONE / CANCELED
(after! org
  (setq org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "DOING(g)" "WAIT(w@/!)" "REVIEW(r)"
           "|" "DONE(d!)" "CANCELED(c@)"))
        org-log-done 'time
        org-log-into-drawer t
        org-clock-into-drawer t
        org-clock-in-switch-to-state "DOING"
        ;; 마일스톤 태그는 하위 할일로 상속되지 않게
        org-tags-exclude-from-inheritance '("milestone")))

;; ─── 태그 ───────────────────────────────────────────
;; project + 타입 태그 하나. 프로젝트 파일 상단 #+filetags 로 자동 상속되므로
;; 개별 할일에 태그를 손으로 달 필요가 없다.
;;   novel  소설            course 전자책/강좌(프로그래밍 책 포함)
;;   dev    웹/앱 개발      image  이미지      video 영상
;;   admin  프로젝트 외 잡무(tasks.org 전체에 자동)
;; 예전 writing(프로젝트 타입) 태그는 novel / course 로 나뉘었고,
;; writing 은 이제 "글"(데일리의 짧은 글, 글 노트)을 뜻한다.
(after! org
  (setq org-tag-alist
        '(("project" . ?p)
          ("novel"   . ?n)
          ("course"  . ?c)
          ("dev"     . ?d)
          ("image"   . ?i)
          ("video"   . ?v)
          ("admin"   . ?a)
          ("milestone" . ?m)
          ("writing" . ?w)    ;; 글 (데일리의 짧은 글, 글 노트)
          ("research" . ?r))))

;; ─── refile: inbox에 던진 것을 제자리로 옮기기 (SPC m r r) ─────
(defun my/refile-files ()
  (seq-filter
   #'file-exists-p
   (append (list (my/org-path "tasks.org")
                 (my/org-path "calendar.org"))
           (mapcar (lambda (d) (expand-file-name "tasks.org" d))
                   (my/project-dirs)))))

(after! org
  (setq org-refile-targets '((my/refile-files :maxlevel . 2))
        ;; 모든 프로젝트의 파일 이름이 tasks.org라서 파일명 대신 #+title로 구분
        org-refile-use-outline-path 'title
        org-outline-path-complete-in-steps nil
        org-refile-allow-creating-parent-nodes 'confirm))

;; ─── 보관(archive) ─────────────────────────────────
;; 기본값은 같은 폴더의 <파일>_archive. 프로젝트 tasks.org는 템플릿에서
;; #+archive: 로 ~/org/archive/<slug>.org 를 지정해 둔다.
(after! org
  (setq org-archive-location
        (concat (my/org-path "archive") "/%s_archive::")))

;; ─── agenda 화면 ───────────────────────────────────
(after! org-agenda
  (setq org-agenda-skip-scheduled-if-done t
        org-agenda-skip-deadline-if-done t
        org-deadline-warning-days 7
        org-agenda-block-separator ?─
        ;; 프로젝트는 왼쪽 category 열로 이미 보이므로 태그 열은 간결하게
        org-agenda-hide-tags-regexp "\\`\\(project\\|milestone\\|admin\\|daily\\|writing\\)\\'"
        ;; 왼쪽 열에 #+category(=프로젝트 slug)를 보여줘서
        ;; "이 할일이 어느 프로젝트 것인지" 바로 보이게 한다.
        org-agenda-prefix-format
        '((agenda . " %i %-14:c%?-12t% s")
          (todo   . " %i %-14:c")
          (tags   . " %i %-14:c")
          (search . " %i %-14:c"))))

(defun my/skip-unless-in-writing-section ()
  "데일리의 '* 글' 섹션 아래가 아닌 항목은 agenda에서 건너뛴다."
  (let ((next (save-excursion (or (outline-next-heading) (point-max)))))
    (save-excursion
      (unless (and (org-up-heading-safe)
                   (equal (org-get-heading t t t t) "글"))
        next))))

(setq org-agenda-custom-commands
      '(;; 매일 아침/작업 중: "지금 뭘 하지?"
        ("d" "오늘"
         ((agenda "" ((org-agenda-span 1)
                      (org-agenda-start-day nil)
                      (org-agenda-overriding-header "📅 오늘 (일정 · SCHEDULED · 마감)")))
          (todo "DOING|NEXT"
                ((org-agenda-overriding-header "▶ 진행 중 / 다음 행동")))
          (todo "WAIT|REVIEW"
                ((org-agenda-overriding-header "⏸ 대기 · 검토 중")))
          (tags "LEVEL=1"
                ((org-agenda-files (list (expand-file-name "inbox.org" org-directory)))
                 (org-agenda-overriding-header "📥 Inbox — 분류 필요")))))

        ;; 주간 리뷰 / "프로젝트별로 뭐가 남았나"
        ("p" "프로젝트 대시보드"
         ((tags-todo "project+novel"
                     ((org-agenda-overriding-header "✍️  소설")))
          (tags-todo "project+course"
                     ((org-agenda-overriding-header "📚 전자책 / 강좌")))
          (tags-todo "project+dev"
                     ((org-agenda-overriding-header "💻 개발")))
          (tags-todo "project+image|project+video"
                     ((org-agenda-overriding-header "🎨 이미지 / 영상")))
          (tags-todo "-project"
                     ((org-agenda-files (list (expand-file-name "tasks.org" org-directory)
                                              (expand-file-name "calendar.org" org-directory)))
                      (org-agenda-overriding-header "🧹 프로젝트 외 할일")))))

        ;; 데일리에 쓴 짧은 글 모아보기 (왼쪽 열 = 날짜, 최근 것이 아래)
        ;; 노트로 승격했거나 처음부터 노트로 쓴 글은 SPC n S
        ("W" "데일리 글 모아보기"
         ((tags "writing+LEVEL=2"
                ;; 로그에 writing 분류로 남긴 한 줄은 빼고, '글' 섹션의 글만
                ((org-agenda-files
                  (directory-files-recursively
                   (expand-file-name "roam/daily" org-directory) "\\.org\\'"))
                 (org-agenda-skip-function #'my/skip-unless-in-writing-section)
                 (org-agenda-prefix-format " %-12:c ")
                 (org-agenda-overriding-header "✏️  데일리의 짧은 글")))))

        ;; 주간 리뷰: 지난 7일 한 일 + 앞으로 2주 + 막힌 것 + inbox
        ("w" "주간 리뷰"
         ((agenda "" ((org-agenda-span 7)
                      (org-agenda-start-day "-7d")
                      (org-agenda-start-on-weekday nil)
                      (org-agenda-show-log t)
                      (org-agenda-log-mode-items '(closed clock))
                      (org-agenda-overriding-header "🔙 지난 7일 (완료 · 작업 시간)")))
          (agenda "" ((org-agenda-span 14)
                      (org-agenda-start-day "+0d")
                      (org-agenda-start-on-weekday nil)
                      (org-agenda-overriding-header "🔜 앞으로 2주")))
          (todo "WAIT|REVIEW"
                ((org-agenda-overriding-header "⏸ 대기 · 검토 — 재촉할 것 있나?")))
          (tags "LEVEL=1"
                ((org-agenda-files (list (expand-file-name "inbox.org" org-directory)))
                 (org-agenda-overriding-header "📥 Inbox — 비우기")))))))

(defun my/agenda-today () (interactive) (org-agenda nil "d"))
(defun my/agenda-projects () (interactive) (org-agenda nil "p"))
(defun my/agenda-weekly () (interactive) (org-agenda nil "w"))


;;; ─── 캡처 (SPC X) ─────────────────────────────────
(defun my/read-project (&optional prompt)
  "프로젝트 디렉토리 하나를 골라 절대경로를 돌려준다."
  (let ((names (mapcar #'file-name-nondirectory (my/project-dirs))))
    (unless names (user-error "프로젝트가 없습니다. SPC n p 로 먼저 만드세요"))
    (my/org-path "projects" (completing-read (or prompt "프로젝트: ") names nil t))))

(defun my/capture--goto-top-heading (prompt)
  "현재 버퍼의 1단계 헤딩 중 하나를 골라 그 위로 이동. 없으면 파일 끝."
  (widen)
  (goto-char (point-min))
  (let (heads)
    (while (re-search-forward "^\\* " nil t)
      (push (cons (org-get-heading t t t t) (line-beginning-position)) heads))
    (setq heads (nreverse heads))
    (if (null heads)
        (goto-char (point-max))
      (goto-char (cdr (assoc (completing-read prompt heads nil t) heads))))))

(defun my/capture-project-task-target ()
  "캡처 타겟: 프로젝트 → 마일스톤을 고르면 그 아래 TODO로 들어간다."
  (let ((file (expand-file-name "tasks.org" (my/read-project "어느 프로젝트? "))))
    (set-buffer (org-capture-target-buffer file))
    (my/capture--goto-top-heading "어느 마일스톤 아래? ")))

(defun my/capture-admin-task-target ()
  "캡처 타겟: tasks.org 의 분류(생활/행정/연락...)를 고른다."
  (set-buffer (org-capture-target-buffer (my/org-path "tasks.org")))
  (my/capture--goto-top-heading "분류: "))

;; ─── 캡처 창에서 vim 식으로 저장/종료 ─────────────────
;; 캡처 창(SPC X …, SPC n W/l)은 파일이 아니라 임시 버퍼라서 :w 가 실패하고,
;; 그대로 :q 하면 캡처가 취소돼 쓴 글이 사라진다. 그래서 캡처 창에서는
;;   :w        저장만 (창은 계속 열림)     :wq  :x  ZZ  → 저장하고 닫기
;;   :q        내용이 있으면 저장할지 묻기   :q!  ZQ      → 버리고 닫기
;; (C-c C-c / C-c C-k 도 그대로 동작)
(defun my/capture-buffer-p ()
  (bound-and-true-p org-capture-mode))

(defun my/capture-save-in-place ()
  "캡처 창을 닫지 않고 지금까지 쓴 내용을 대상 파일에 저장."
  (let ((base (buffer-base-buffer)))
    (when (and base (buffer-file-name base))
      (with-current-buffer base (save-buffer))
      (message "저장됨 (닫으려면 :wq)"))))

(defun my/evil-capture-finalize-a (orig &rest args)
  (if (my/capture-buffer-p) (org-capture-finalize) (apply orig args)))

(defun my/evil-capture-write-a (orig &rest args)
  (if (my/capture-buffer-p) (my/capture-save-in-place) (apply orig args)))

(defun my/evil-capture-quit-a (orig &optional force &rest args)
  (cond ((not (my/capture-buffer-p)) (apply orig force args))
        (force (org-capture-kill))
        ((y-or-n-p "쓴 내용을 저장할까요? ") (org-capture-finalize))
        (t (org-capture-kill))))

(after! evil
  (advice-add 'evil-save-and-close :around #'my/evil-capture-finalize-a)          ; :wq
  (advice-add 'evil-save-modified-and-close :around #'my/evil-capture-finalize-a) ; :x ZZ
  (advice-add 'evil-write :around #'my/evil-capture-write-a)                      ; :w
  (advice-add 'evil-quit :around #'my/evil-capture-quit-a))                       ; :q :q! ZQ

(after! org
  (setq org-capture-templates
        '(;; 기본값. 고민되면 무조건 이것 → 나중에 refile
          ("i" "Inbox (일단 던져두기)" entry (file "inbox.org")
           "* TODO %?\n%U\n")
          ;; 어느 프로젝트 일인지 확실할 때
          ("k" "프로젝트 작업" entry (function my/capture-project-task-target)
           "* TODO %?\n")
          ;; 프로젝트 외 할일
          ("t" "할일 (프로젝트 외)" entry (function my/capture-admin-task-target)
           "* TODO %?\n")
          ;; 날짜/시간이 정해진 약속
          ("e" "일정 (약속)" entry (file+headline "calendar.org" "약속")
           "* %^{일정}\n%^T\n%?"))))


;;; ─── 새 프로젝트 만들기 (SPC n p) ─────────────────
;; 타입별로 projects/<slug>/ 아래 파일 묶음을 만든다.
;;  공통: index.org(시작 페이지, roam 노드) plan.org(왜/범위/단계) tasks.org(할일)
;;  타입별 추가 파일은 아래 표 참고.
(defconst my/project-types
  ;; 키      표시 이름       추가 파일                     마일스톤
  '(("novel"  "소설"        ("outline" "characters" "world")
     ("M1 설정·플롯 확정" "M2 초고" "M3 퇴고"))
    ("course" "전자책/강좌"  ("outline" "research")
     ("M1 목차·커리큘럼 확정" "M2 초고/녹화" "M3 편집·출간"))
    ("dev"    "개발"        ("design")
     ("M1 MVP" "M2 공개 배포"))
    ("image"  "이미지"      ("assets")
     ("M1 콘셉트·레퍼런스" "M2 제작" "M3 납품·게시"))
    ("video"  "영상"        ("script" "assets")
     ("M1 기획·대본" "M2 촬영·제작" "M3 편집·게시"))))

(defconst my/project-file-titles
  '(("index" . "") ("plan" . "계획") ("tasks" . "작업")
    ("outline" . "목차") ("characters" . "인물") ("world" . "세계관")
    ("research" . "조사") ("design" . "설계") ("assets" . "에셋")
    ("script" . "대본·샷리스트")))

(defun my/project--header (name title slug type)
  (let ((sub (cdr (assoc name my/project-file-titles))))
    (format "#+title: %s\n#+filetags: :project:%s:\n#+category: %s\n"
            (if (string-empty-p sub) title (format "%s · %s" title sub))
            type slug)))

(defun my/project--body (name title slug type label extras milestones)
  (pcase name
    ("index"
     (concat
      "\n* 한 줄 요약\n\n"
      "* 왜 / 무엇을 / 언제 끝나나\n"
      "- 왜 하는가:\n"
      "- 결과물:\n"
      "- 완료 조건 (이게 되면 끝):\n\n"
      "* 현재 상태\n"
      "- 단계: M1\n"
      "- 막힌 것:\n\n"
      "* 파일\n"
      (mapconcat (lambda (f)
                   (format "- [[file:%s.org][%s]]" f
                           (cdr (assoc f my/project-file-titles))))
                 (append '("plan" "tasks") extras) "\n")
      "\n\n* 관련 노트\n"
      "# roam 노트에서 이 프로젝트로 링크하면(SPC n i) 백링크(SPC n r r)에 모인다.\n"))
    ("plan"
     (concat
      "\n* 범위\n** 하는 것\n- \n** 하지 않는 것\n- \n\n"
      "* 단계\n"
      "# 대략적인 흐름만. 실제 마감 날짜의 원본은 tasks.org의 DEADLINE.\n"
      (mapconcat (lambda (m) (format "** %s\n- " m)) milestones "\n")
      "\n\n* 위험과 대응\n- \n\n"
      "* 결정 기록\n"
      "# [날짜] 결정 — 이유. \"왜 이렇게 했지?\"에 미래의 내가 답을 찾는 곳.\n"))
    ("tasks"
     (concat
      (format "#+archive: %s::* %s 보관\n"
              (my/org-path "archive" (concat slug ".org")) title)
      "\n# 마일스톤 = 1단계 헤딩 (:milestone:, 마감은 DEADLINE)\n"
      "# 실행 단위 = 그 아래 TODO. 바로 착수할 1~2개만 NEXT.\n"
      "# 마일스톤이 끝나면 헤딩에서 SPC m A 로 통째로 보관.\n\n"
      ;; 첫 마일스톤에만 NEXT 하나: 오늘 화면에 바로 떠서 "첫 행동"을 정하게 만든다.
      (format "* %s :milestone:\n** NEXT 첫 행동을 구체적으로 정해서 이 줄을 고치기\n"
              (car milestones))
      (mapconcat (lambda (m) (format "\n* %s :milestone:\n" m))
                 (cdr milestones) "")))
    ("outline"
     (if (equal type "novel")
         (concat
          "#+columns: %40ITEM %STATUS %POV %WORDS{+}\n"
          "# 장 상태는 TODO가 아니라 STATUS 속성으로 (agenda 오염 방지)\n"
          "# 전체 현황 표: 헤딩에서 C-c C-x C-c (column view), q로 닫기\n\n"
          "* 로그라인\n\n* 구조\n** 1막\n** 2막\n** 3막\n\n"
          "* 장\n** 1장\n:PROPERTIES:\n:STATUS: 구상\n:POV:\n:WORDS: 0\n:END:\n")
       (concat
        "#+columns: %40ITEM %STATUS %PAGES{+}\n"
        "# 장/강의 상태는 STATUS 속성으로: 구상 → 초고 → 수정 → 완료\n\n"
        "* 대상 독자 / 수강생\n- 사전 지식:\n- 끝나면 할 수 있는 것:\n\n"
        "* 목차\n** 1장\n:PROPERTIES:\n:STATUS: 구상\n:PAGES: 0\n:END:\n"
        "- 학습 목표:\n- 예제/실습:\n")))
    ("characters"
     (concat
      "\n* 주요 인물\n** 이름\n:PROPERTIES:\n:역할: 주인공\n:END:\n"
      "- 원하는 것:\n- 두려워하는 것:\n- 변화(아크):\n\n* 조연\n"))
    ("world" "\n* 장소\n\n* 규칙 / 설정\n\n* 연표\n")
    ("research"
     (concat
      "\n# 이 프로젝트에만 쓰는 자료는 여기에.\n"
      "# 다른 프로젝트에서도 쓸 지식이면 roam 노트로 만들고 여기엔 링크만.\n\n"
      "* 자료\n\n* 예제 / 실습 아이디어\n\n* 참고 문헌\n"))
    ("design"
     (concat
      "\n* 요구사항\n\n* 아키텍처\n\n* 데이터 모델\n\n"
      "* 결정 기록 (ADR)\n\n* 환경 / 배포\n- 저장소:\n- 배포 주소:\n"))
    ("assets"
     (concat
      "\n* 레퍼런스\n\n* 에셋 목록\n| 파일 | 상태 | 비고 |\n|------+------+------|\n|      |      |      |\n\n"
      "* 출력 규격\n- 해상도/비율:\n- 포맷:\n"))
    ("script"
     (concat
      "\n* 대본\n\n* 샷 리스트\n| # | 장면 | 길이 | 상태 |\n|---+------+------+------|\n|   |      |      |      |\n"))
    (_ "\n")))

(defun my/projects-list-add (id title label)
  "projects.org 의 '진행 중' 아래에 새 프로젝트 링크를 추가."
  (let ((file (my/org-path "projects.org")))
    (with-current-buffer (find-file-noselect file)
      (goto-char (point-min))
      (if (re-search-forward "^\\* 진행 중" nil t)
          (org-end-of-subtree t t)
        (goto-char (point-max)))
      (unless (bolp) (insert "\n"))
      (insert (format "- [[id:%s][%s]] (%s) — 시작 %s\n"
                      id title label (format-time-string "%Y-%m-%d")))
      (save-buffer))))

(defun my/slug (title)
  "TITLE을 폴더명으로 쓰기 좋은 slug(소문자, 하이픈 구분)로 변환."
  (let ((s (downcase title)))
    (setq s (replace-regexp-in-string "[^[:alnum:]가-힣]+" "-" s))
    (replace-regexp-in-string "^-+\\|-+$" "" s)))

(defun my/new-project ()
  "타입을 고르면 projects/<slug>/ 에 파일 묶음을 만들고 index.org를 연다."
  (interactive)
  (require 'org-id)
  (let* ((choice (completing-read
                  "타입: "
                  (mapcar (lambda (e) (format "%s — %s" (car e) (nth 1 e)))
                          my/project-types)
                  nil t))
         (type (car (split-string choice " ")))
         (spec (assoc type my/project-types))
         (label (nth 1 spec))
         (extras (nth 2 spec))
         (milestones (nth 3 spec))
         (title (read-string "프로젝트 이름: "))
         (default-slug (my/slug title))
         (slug (read-string (format "폴더명/slug (영문 권장, agenda에 표시됨) [%s]: "
                                    default-slug)
                            nil nil default-slug))
         (dir (my/org-path "projects" slug))
         (id (org-id-new)))
    (when (file-exists-p dir)
      (user-error "이미 있는 프로젝트입니다: %s" dir))
    (make-directory dir t)
    (dolist (name (append '("index" "plan" "tasks") extras))
      (with-temp-file (expand-file-name (concat name ".org") dir)
        (when (equal name "index")
          (insert (format ":PROPERTIES:\n:ID:       %s\n:END:\n" id)))
        (insert (my/project--header name title slug type))
        (insert (my/project--body name title slug type label extras milestones))))
    (my/projects-list-add id title label)
    (let ((index (expand-file-name "index.org" dir)))
      (when (require 'org-roam nil t)
        (org-roam-db-update-file index))
      (find-file index))
    (message "새 프로젝트 %s 생성. 다음: tasks.org 에서 첫 NEXT 정하기" slug)))

(defun my/find-project ()
  "프로젝트를 고르고, 그 안의 파일을 고른다 (기본 index.org)."
  (interactive)
  (let* ((dir (my/read-project))
         (files (directory-files dir nil "\\.org\\'"))
         (file (completing-read "파일 [index.org]: " files nil t nil nil "index.org")))
    (find-file (expand-file-name file dir))))

(defun my/project-tasks ()
  "프로젝트를 골라 tasks.org 를 바로 연다."
  (interactive)
  (find-file (expand-file-name "tasks.org" (my/read-project))))

(defun my/archive-project ()
  "끝난(또는 접은) 프로젝트 폴더를 archive/ 로 옮긴다. agenda에서 사라진다."
  (interactive)
  (let* ((dir (directory-file-name (my/read-project "보관할 프로젝트: ")))
         (dest (my/org-path "archive" (file-name-nondirectory dir))))
    (when (file-exists-p dest)
      (user-error "archive 에 같은 이름이 이미 있습니다: %s" dest))
    (when (yes-or-no-p (format "%s 를 archive/ 로 옮길까요? " (file-name-nondirectory dir)))
      ;; 열린 버퍼를 저장하고 닫아서 옛 경로를 가리키는 버퍼가 남지 않게
      (dolist (buf (buffer-list))
        (let ((f (buffer-file-name buf)))
          (when (and f (string-prefix-p (file-name-as-directory dir) f))
            (with-current-buffer buf (save-buffer))
            (kill-buffer buf))))
      (make-directory (my/org-path "archive") t)
      (rename-file dir dest)
      (when (fboundp 'org-roam-db-sync) (org-roam-db-sync))
      (message "보관 완료. projects.org 에서 '완료'로 옮겨 적으세요."))))


;;; ─── 처음 한 번: 기본 파일 만들기 (M-x my/org-bootstrap) ─────
(defconst my/org-root-files
  '(("inbox.org" .
     "#+title: Inbox\n#+category: inbox\n\n# 여기 쌓인 건 매일 저녁/주간 리뷰에서 비운다.\n# 헤딩에서 SPC m r r (refile) → 프로젝트 tasks.org 나 tasks.org 로.\n\n")
    ("tasks.org" .
     "#+title: 할일 (프로젝트 외)\n#+filetags: :admin:\n#+category: 할일\n\n* 생활\n* 행정·돈\n* 연락\n* 공부·관리\n* 언젠가\n")
    ("calendar.org" .
     "#+title: 일정\n#+category: 일정\n\n# 날짜/시간이 고정된 것만. 할일이 아니라 '그 시간에 그 장소에 있어야 하는 것'.\n\n* 약속\n* 반복\n# 예) ** 주간 리뷰\n#     <2026-10-25 Sun 20:00 +1w>\n")
    ("projects.org" .
     "#+title: 프로젝트 목록\n\n# 사람이 보는 목록. 새 프로젝트(SPC n p)는 자동으로 '진행 중'에 추가된다.\n# 상태가 바뀌면 줄을 다른 섹션으로 옮긴다 (주간 리뷰 때).\n\n* 진행 중\n* 보류\n* 언젠가 할 프로젝트\n* 완료\n")
    ("index.org" .
     "#+title: 대시보드\n#+startup: showall\n\n* 바로가기\n- [[file:inbox.org][📥 Inbox]] · [[file:tasks.org][🧹 할일]] · [[file:calendar.org][📅 일정]] · [[file:projects.org][📂 프로젝트 목록]]\n\n* 이번 주 초점\n# 주간 리뷰 때 1~3개. 여기 적은 것이 그 주의 우선순위.\n1. \n\n* 루틴\n- 아침: SPC n t (오늘) → 초점 고르기 → SPC n j 데일리\n- 작업: 할일에서 SPC m c i (clock-in) … 끝나면 SPC n l 로그\n- 저녁: Inbox 비우기, 데일리 '마무리'\n- 일요일: SPC n w (주간 리뷰)\n\n* 자주 보는 노트\n")))

(defun my/org-bootstrap ()
  "~/org 기본 폴더와 파일을 만든다. 이미 있는 파일은 건드리지 않는다."
  (interactive)
  (dolist (d '("projects" "roam/daily" "roam/notes" "archive"))
    (make-directory (my/org-path d) t))
  (dolist (f my/org-root-files)
    (let ((path (my/org-path (car f))))
      (unless (file-exists-p path)
        (with-temp-file path (insert (cdr f))))))
  (message "~/org 준비 완료"))


;;; ─── org-roam: daily / notes ──────────────────────
(after! org-roam
  (require 'org-roam-dailies)
  (setq org-roam-dailies-directory "roam/daily/")
  (setq org-roam-file-exclude-regexp (list "data/" "\\`archive/" "/archive/"))
  (setq org-roam-node-display-template
        (concat "${title:60} " (propertize "${tags:30}" 'face 'org-tag)))

  ;; 지식 노트. "프로젝트가 끝나도 남길 것"만.
  (setq org-roam-capture-templates
        '(("n" "노트 (생각/개념)" plain "%?"
           :target (file+head "roam/notes/${slug}.org"
                              "#+title: ${title}\n#+filetags: :note:\n")
           :unnarrowed t)
          ("r" "자료 정리 (책/글/강의/영상)" plain
           "* 출처\n- %^{출처 (URL 또는 서지)}\n\n* 핵심\n%?\n\n* 내 생각 / 어디에 쓸까\n"
           :target (file+head "roam/notes/${slug}.org"
                              "#+title: ${title}\n#+filetags: :ref:\n")
           :unnarrowed t)
          ;; 처음부터 한 편으로 쓸 글 (에세이, 블로그 초안). 짧은 글은 데일리(SPC n W)로
          ("w" "글 (한 편)" plain "%?"
           :target (file+head "roam/notes/${slug}.org"
                              "#+title: ${title}\n#+date: %<%Y-%m-%d>\n#+filetags: :writing:\n")
           :unnarrowed t)))

  ;; 데일리 = 그날의 "기록". 할일 원본이 아니다.
  ;;  - 오늘의 초점: agenda에서 고른 1~3개를 이름만 적는다 (TODO 키워드 X)
  ;;  - 로그: SPC n l 로 시간과 분류가 붙은 항목이 쌓인다
;;  - 글: SPC n W 로 짧은 글(단상, 일기, 초안 조각)을 시간과 함께 남긴다.
;;        길게 다듬고 싶어지면 그 헤딩에서 SPC n e 로 roam 노트로 승격
  ;;  - 메모: 떠오른 생각. 오래 남길 가치가 있으면 roam 노트로 승격
  ;;  - 마무리: 3줄 회고 → 내일 첫 작업을 정해 두면 아침이 빨라진다
  (defconst my/daily-head
    "#+title: %<%Y-%m-%d %a>
#+filetags: :daily:

* 오늘의 초점
1.

* 로그

* 글

* 메모

* 마무리
- 한 것:
- 막힌 것:
- 내일 첫 작업:
")

  (setq org-roam-dailies-capture-templates
        `(("d" "daily" plain ""
           :target (file+head "%<%Y-%m-%d>.org" ,my/daily-head)
           :unnarrowed t)
          ("l" "log" entry
           "* %<%H:%M> %^{무엇을 했나} :%^{분류|novel|course|dev|image|video|writing|admin}:\n%?"
           :target (file+head+olp "%<%Y-%m-%d>.org" ,my/daily-head ("로그")))
          ;; 짧은 글. 제목은 비워도 된다 (Enter). C-c C-c 로 저장, C-c C-k 로 취소
          ("w" "글" entry
           "* %<%H:%M> %^{제목 (비워도 됨)} :writing:\n%?"
           :target (file+head+olp "%<%Y-%m-%d>.org" ,my/daily-head ("글"))
           :empty-lines-after 1)))

  ;; 승격(SPC n e)한 글이 ~/org 루트가 아니라 roam/notes 로 가게
  (setq org-roam-extract-new-file-path "roam/notes/${slug}.org")

  (org-roam-db-autosync-mode))

(defun my/daily-today ()
  "오늘 데일리 노트를 연다 (없으면 템플릿으로 생성)."
  (interactive)
  (require 'org-roam-dailies)
  (org-roam-dailies-capture-today t "d"))

(defun my/daily-log ()
  "오늘 데일리의 '로그' 아래에 시간이 찍힌 기록을 추가."
  (interactive)
  (require 'org-roam-dailies)
  (org-roam-dailies-capture-today nil "l"))

(defun my/daily-write ()
  "오늘 데일리의 '글' 아래에 짧은 글을 쓴다."
  (interactive)
  (require 'org-roam-dailies)
  (org-roam-dailies-capture-today nil "w"))

(defun my/writing--strip-time ()
  "현재 헤딩 앞의 'HH:MM ' 을 지우고, 남은 제목을 돌려준다.
제목이 비어 있으면 첫 줄 본문이나 날짜로 제목을 묻는다."
  (org-back-to-heading t)
  (let* ((raw (org-get-heading t t t t))
         (title (string-trim
                 (replace-regexp-in-string "\\`[0-9][0-9]:[0-9][0-9] *" "" raw))))
    (when (string-empty-p title)
      (setq title (read-string "글 제목: ")))
    (org-edit-headline title)
    title))

(defun my/promote-writing ()
  "데일리의 글 헤딩을 roam/notes 의 독립 노트로 옮기고, 데일리엔 링크를 남긴다.
태그(:writing:)는 노트의 filetags 로 옮겨진다."
  (interactive)
  (require 'org-roam)
  (unless (derived-mode-p 'org-mode) (user-error "org 파일에서 실행하세요"))
  (let* ((date (file-name-base (or (buffer-file-name) "")))
         (title (my/writing--strip-time))
         (id (org-id-get-create)))
    (org-set-property "CREATED" date)
    (org-roam-extract-subtree)
    ;; 잘라낸 자리에 링크
    (insert (format "- 노트로 옮김: [[id:%s][%s]]\n" id title))
    (save-buffer)
    (message "'%s' → roam/notes 로 승격" title)))

(defun my/writings ()
  "데일리에 쓴 짧은 글 목록."
  (interactive)
  (org-agenda nil "W"))

(defun my/find-writing-note ()
  "글 노트(:writing: 태그)만 골라서 찾는다. 없는 제목이면 '글 (한 편)'으로 새로 만든다."
  (interactive)
  (require 'org-roam)
  (org-roam-node-find
   nil nil
   (lambda (node) (member "writing" (org-roam-node-tags node)))
   nil :templates (seq-filter (lambda (tp) (equal (car tp) "w"))
                              org-roam-capture-templates)))

(defun my/open-index ()
  "전체 대시보드 index.org 를 연다."
  (interactive)
  (find-file (my/org-path "index.org")))


;;; ─── 키 바인딩 (SPC n …) ──────────────────────────
(map! :leader
      (:prefix ("n" . "notes")
       ;; 하루의 흐름
       :desc "오늘 (agenda)"       "t" #'my/agenda-today
       :desc "오늘 데일리"          "j" #'my/daily-today
       :desc "데일리에 로그"        "l" #'my/daily-log
       :desc "데일리에 글"          "W" #'my/daily-write
       :desc "글 → 노트로 승격"     "e" #'my/promote-writing
       :desc "데일리 글 모아보기"    "s" #'my/writings
       :desc "글 노트 찾기/쓰기"     "S" #'my/find-writing-note
       :desc "주간 리뷰"            "w" #'my/agenda-weekly
       :desc "프로젝트 대시보드"     "b" #'my/agenda-projects
       :desc "Agenda 메뉴"         "a" #'org-agenda
       ;; 프로젝트
       :desc "새 프로젝트"          "p" #'my/new-project
       :desc "프로젝트 파일 열기"    "P" #'my/find-project
       :desc "프로젝트 tasks.org"   "T" #'my/project-tasks
       :desc "대시보드 index.org"   "I" #'my/open-index
       ;; 지식 노트
       :desc "노트 찾기/만들기"      "f" #'org-roam-node-find
       :desc "노트 링크 삽입"        "i" #'org-roam-node-insert))

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

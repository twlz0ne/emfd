;;; emfd.el --- Emacs wrapper around mdfind -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Gong Qijian <gongqijian@gmail.com>

;; Author: Gong Qijian <gongqijian@gmail.com>
;; Created: 2022/03/31
;; Version: 0.1.0
;; Package-Requires: ((emacs "26.1"))
;; URL: https://github.com/twlz0ne/emfd
;; Keywords: cli

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Emacs wrapper around mdfind.

;;; Code:

(require 'subr-x)
(require 'cl-lib)

(defvar emfd-metadata-attribute-keys
  '(;; filesystem attributes
    (fmtime          . "kMDItemFSContentChangeDate")
    (fctime          . "kMDItemFSCreationDate")
    (exists          . "kMDItemFSExists")
    (invisble        . "kMDItemFSInvisible")
    (exthidden       . "kMDItemFSIsExtensionHidden")
    (readable        . "kMDItemFSIsReadable")
    (writeable       . "kMDItemFSIsWriteable")
    (label           . "kMDItemFSLabel")
    (name            . "kMDItemFSName")
    (ncount          . "kMDItemFSNodeCount")
    (oid             . "kMDItemFSOwnerGroupID")
    (uid             . "kMDItemFSOwnerUserID")
    (size            . "kMDItemFSSize")
    (path            . "kMDItemPath")

    ;; common attributes
    (attrtime        . "kMDItemAttributeChangeDate")
    (audience        . "kMDItemAudiences")
    (author          . "kMDItemAuthors")
    (authoraddr      . "kMDItemAuthorAddresses")
    (city            . "kMDItemCity")
    (comment         . "kMDItemComment")
    (contactkeyword  . "kMDItemContactKeywords")
    (ctime           . "kMDItemContentCreationDate")
    (mtime           . "kMDItemContentModificationDate")
    (tag             . "kMDItemUserTags")
    (type            . "kMDItemContentType")
    (utype           . "kMDItemContentTypeTree")
    (contributor     . "kMDItemContributors")
    (copyright       . "kMDItemCopyright")
    (country         . "kMDItemCountry")
    (coverage        . "kMDItemCoverage")
    (creator         . "kMDItemCreator")
    (desc            . "kMDItemDescription")
    (dispname        . "kMDItemDisplayName")
    (duedate         . "kMDItemDueDate")
    (second          . "kMDItemDurationSeconds")
    (email           . "kMDItemEmailAddresses")
    (app             . "kMDItemEncodingApplications")
    (memo            . "kMDItemFinderComment")
    (font            . "kMDItemFonts")
    (headline        . "kMDItemHeadline")
    (id              . "kMDItemIdentifier")
    (raddr           . "kMDItemInstantMessageAddresses")
    (instr           . "kMDItemInstructions")
    (keyword         . "kMDItemKeywords")
    (kind            . "kMDItemKind")
    (lang            . "kMDItemLanguages")
    (utime           . "kMDItemLastUsedDate")
    (page            . "kMDItemNumberOfPages")
    (local           . "kMDItemNamedLocation")
    (org             . "kMDItemOrganizations")
    (pageh           . "kMDItemPageHeight")
    (pagew           . "kMDItemPageWidth")
    (participants    . "kMDItemParticipants")
    (phones          . "kMDItemPhoneNumbers")
    (projects        . "kMDItemProjects")
    (publisher       . "kMDItemPublishers")
    (recipient       . "kMDItemRecipients")
    (recipientaddr   . "kMDItemRecipientAddresses")
    (rights          . "kMDItemRights")
    (secure          . "kMDItemSecurityMethod")
    (rating          . "kMDItemStarRating")
    (province        . "kMDItemStateOrProvince")
    (content         . "kMDItemTextContent")
    (title           . "kMDItemTitle")
    (ver             . "kMDItemVersion")
    (from            . "kMDItemWhereFroms"))
  "Metadata attribute Keys.

References:

https://developer.apple.com/library/archive/documentation/CoreServices/Reference/MetadataAttributesRef/Reference/CommonAttrs.html#//apple_ref/doc/uid/TP40001694-SW1
https://github.com/darlinghq/darling/blob/master/src/frameworks/CoreServices/src/Metadata/MDItem.c")

(defvar emfd-content-type-alist
  '(
    ;; basic
    
    ("public.folder"            . ("folder" "dir"))
    ("public.volume"            . ("volume" "vol"))
    ("public.symlink"           . ("symlink"))
    ("public.unix-executable"   . ("unix-bin" "ubin"))
    ("public.archive"           . ("archive"))
    ("public.disk-image"        . ("disk" "disk-image"))

    ;; plain text

    ("public.text"              . ("text"))
    ("public.plain-text"        . ("txt" "ptext" "plain-text"))
    ("public.utf8-plain-text"   . ("utf8" "utxt8"))
    ("public.utf16-plain-text"  . ("utf16" "utxt6" "utxt"))
    ("public.rtf"               . ("rtf"))
    ("public.css"               . ("css"))
    ("public.html"              . ("html" "htm"))
    ("public.xml"               . ("xml"))
    ("org.orgmode.org"          . ("org"))
    ("net.daringfireball.markdown" . ("markdown" "md"))

    ;; source & script

    ("public.source-code"       . ("src" "stxt" "source" "code" "source-code"))
    ("public.c-source"          . ("c"))
    ("public.objective-c-source" . ("m"))
    ("public.c-plus-plus-c-source" . ("cc" "cpp" "cxx" "c++"))
    ("public.objective-c-plus-​plus-source" . ("mm"))
    ("public.c-header"          . ("h"))
    ("public.c-plus-plus-header" . ("hh" "hpp" "h++"))
    ("com.sun.java-source"      . ("java"))
    ("public.script"            . ("script"))
    ("public.assembly-source"   . ("s" "asm"))
    ("com.apple.symbol-export"  . ("exp"))
    ("com.netscape.javascript-​source" . ("js" "javascript"))
    ("public.shell-script"      . ("sh"))
    ("public.csh-script"        . ("csh"))
    ("public.perl-script"       . ("pl" "pm" "perl"))
    ("public.python-script"     . ("py" "python"))
    ("public.ruby-script"       . ("rb" "rbw" "ruby"))
    ("public.php-script"        . ("php" "php3" "php4" "ph3" "ph4" "phtml"))
    ("com.apple.applescript.text" . ("applescript"))
    ("com.apple.applescript.​script" . ("scpt" "osas"))

    ;; archives

    ("public.object-code"       . ("o"))
    ("com.microsoft.windows-​executable" . ("exe"))
    ("com.microsoft.windows-​dynamic-link-library" "dll")
    ("com.sun.java-class"       . ("class"))
    ("com.sun.java-archive"     . ("jar"))
    ("com.apple.quartz-​composer-composition" . ("qtz"))
    ("org.gnu.gnu-tar-archive"  . ("gtar"))
    ("public.tar-archive"       . ("tar"))
    ("org.gnu.gnu-zip-archive"  . ("gz" "gzip"))
    ("org.gnu.gnu-zip-tar-archive" . ("tgz" "targz" "gztar" "gziptar"))
    ("com.pkware.zip-archive"   . ("zip"))

    ;; images

    ("public.image"             . ("image" "img"))
    ("public.jpeg"              . ("jpg" "jpeg"))
    ("public.png"               . ("png"))
    ("public.xbitmap-image"     . ("xbmp" "xbitmap"))
    ("com.apple.icns"           . ("icon" "icns"))
    ("com.compuserve.gif"       . ("gif"))
    ("com.microsoft.ico"        . ("ico" "msicon" "ms-icon"))
    ("com.microsoft.bmp"        . ("bmp"))

    ;; video

    ("public.movie"             . ("movie" "mov"))
    ("public.video"             . ("video" "vid"))
    ("public.avi"               . ("avi"))
    ("public.mpeg"              . ("mpeg" "mpg"))
    ("public.mpeg-4"            . ("mp4" "mpeg4" "mpg4"))
    ("public.3gpp"              . ("3gp" "3gpp"))
    ("public.3gpp2"             . ("3gp2" "3g2"))
    ("com.microsoft.waveform-​audio" . ("wav" "wave"))
    ("com.microsoft.windows-​media-wma" . ("wma"))

    ;; audio

    ("public.audio"             . ("audio" "aud"))
    ("public.mp3"               . ("mp3" "mpg3" "mpeg3"))
    ("public.mpeg-4-audio"      . ("m4a"))
    ("com.apple.protected-​mpeg-4-audio" . ("m4p" "m4b"))
    ("com.apple.bundle"         . ("bundle" "bndl"))
    ("com.apple.application"    . ("app" "application"))
    ("com.apple.plugin"         . ("plugin"))
    ("com.microsoft.advanced-​systems-format" . ("asf"))
    ("com.microsoft.windows-​media-wmv" . ("wmv"))

    ;; fonts

    ("public.font"              . ("font"))
    ("public.true-font"         . ("ttf" "true-font"))
    ("public.opentype-font"     . ("otf" "opentype-font"))

    ;; office & design

    ("com.apple.keynote.key"    . ("keynote"))
    ("com.adobe.pdf"            . ("pdf"))
    ("com.adobe.postscript"     . ("ps" "postscript"))
    ("com.adobe.encapsulated-​postscript" . ("epx"))
    ("com.adobe.photoshop-​image" . ("psd"))
    ("com.adobe.illustrator.ai-​image" . ("ai"))
    ("com.microsoft.word.doc"   . ("doc" "msword" "msdoc"))
    ("com.microsoft.excel.xls"  . ("xls" "ms-excel" "msexcel"))
    ("com.microsoft.powerpoint.​ppt" . ("ppt" "powerpoint"))
    )
  "A list of (CONTENT-TYPE-ID . SHORTNAME-LIST).

Determine the type of a file:

   mdls /path/to/file | grep -E 'kMDItemKind|kMDItemContentType'

System-Declared Uniform Type Identifiers:

https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html")

(when (file-exists-p "~/.emfdrc.el")
  (load "~/.emfdrc.el"))



;; tokens

(defvar emfd-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?. "_   " table)
    table))

(defvar emfd--comparison-modifiers '(?c ?d))

(defun emfd--scan-comparison-modifiers (point)
  "Scan comparison modifiers after POINT."
  (let ((new-point point))
    (while (and (< (- new-point point) 3)
                (memq (char-after new-point) emfd--comparison-modifiers))
      (setq new-point (1+ new-point)))
    (if (or (eq ?\s (char-after new-point)) (= (point-max) new-point))
        new-point
      point)))

(defun emfd--read-token ()
  "Return a token and move point forward."
  (let ((new-point
         (if (looking-at "\s*[!()]")
             (match-end 0)
           (scan-sexps (point) 1))))
    (when new-point
      (if (eq ?: (char-after new-point))
          (setq new-point (1+ new-point))
        (if (eq ?\" (char-before new-point))
            ;; Value comparison modifiers in the end of quoted word
            (setq new-point (emfd--scan-comparison-modifiers new-point))))
      (prog1 (string-trim (buffer-substring-no-properties (point) new-point)
                          "[\s\t]" "[\s\t]")
        (goto-char new-point)))))

(defun emfd--identify-token (token)
  "Identify TOKEN string."
  (cond
   ((string= token "[c]")       (cons 'ignore-case token))
   ((string= token "[d]")       (cons 'ignore-diacritic token))
   ((string= token "&&" )       (cons 'op-and token))
   ((string= token "||" )       (cons 'op-or token))
   ((string= token "!"  )       (cons 'op-not token))
   ((string= token "("  )       (cons 'group-begin token))
   ((string= token ")"  )       (cons 'group-end token))
   ((string-suffix-p ":" token) (cons 'attribute (string-trim-right token ":")))
   (t                           (cons 'value token))))

(defun emfd--parse-query (string)
  "Parse the query STRING."
  (with-temp-buffer
    (with-syntax-table emfd-syntax-table
      (insert string)
      (goto-char (point-min))
      (let (token tokens)
        (while (setq token (emfd--read-token))
          (push (emfd--identify-token token) tokens))
        (reverse tokens)))))



;;; date & time

(defvar emfd-now-offset-matcher
  (rx (seq bos
           (group (any "+" "-"))
           (group (+ num))
           (group (any "y" "m" "d" "w" "h" "M" "s"))
           eos))
  "Regexp to match now offset time.")

(defvar emfd-now-offset-range-matcher
  (rx (seq bos
           (group (+ num))
           (opt (group (any "y" "m" "d" "w" "h" "M" "s")))
           "-"
           (group (+ num))
           (group (any "y" "m" "d" "w" "h" "M" "s"))
           eos))
  "Regexp to match now offset time range offset[unit]?-offset[unit].")

(defvar emfd-date-time-matcher
  (rx (seq bos
           (opt (group (any "+" "-")))
           (group (= 4 num)) (or "-" "/")
           (group (repeat 1 2 (any num))) (or "-" "/")
           (group (repeat 1 2 (any num))) " "
           (group (repeat 1 2 (any num))) (opt ":")
           (opt (group(repeat 1 2 (any num)))) (opt ":")
           (opt (group(repeat 1 2 (any num))))
           eos))
  "Regexp to match date time [+-]?yyyy/mm?/dd? hh?[:mm?:ss?].")

(defvar emfd-date-time-range-matcher
  (rx (seq bos
           (group (= 4 num)) "/"
           (group (repeat 1 2 (any num))) "/"
           (group (repeat 1 2 (any num))) " "
           (group (repeat 1 2 (any num))) (opt ":")
           (opt (group(repeat 1 2 (any num)))) (opt ":")
           (opt (group(repeat 1 2 (any num))))
           "-"
           (group (= 4 num)) "/"
           (group (repeat 1 2 (any num))) "/"
           (group (repeat 1 2 (any num))) " "
           (group (repeat 1 2 (any num))) (opt ":")
           (opt (group(repeat 1 2 (any num)))) (opt ":")
           (opt (group(repeat 1 2 (any num))))
           eos))
  "Regexp to match date time range yyyy/mm?/dd? hh?[:mm?:ss?]-yyyy/mm?/dd? hh?[:mm?:ss?].")

(defvar emfd-date-only-matcher
  (rx (seq bos
           (opt (group (any "+" "-")))
           (group (= 4 num)) (opt "/")
           (opt (group (repeat 1 2 (any num)))) (opt "/")
           (opt (group (repeat 1 2 (any num))))
           eos))
  "Regexp to match date yyyy[/mm?/dd?]")

(defvar emfd-date-only-range-matcher
  (rx (seq bos
           (group (= 4 num)) (opt "/")
           (opt (group (repeat 1 2 (any num)))) (opt "/")
           (opt (group (repeat 1 2 (any num))))
           "-"
           (group (= 4 num)) (opt "/")
           (opt (group (repeat 1 2 (any num)))) (opt "/")
           (opt (group (repeat 1 2 (any num))))
           eos))
  "Regexp to match date range only yyyy[/mm?/dd?]-yyyy[/mm?/dd?]")

(defvar emfd-time-only-matcher
  (rx (seq bos
           (opt (group (any "+" "-")))
           (group (repeat 1 2 (any num))) (opt ":")
           (opt (group(repeat 1 2 (any num)))) (opt ":")
           (opt (group(repeat 1 2 (any num))))
           eos))
  "Regexp to match time [+-]?hh?:[mm?:ss?].")

(defvar emfd-time-only-range-matcher
  (rx (seq bos
           (group (repeat 1 2 (any num))) (opt ":")
           (opt (group(repeat 1 2 (any num)))) (opt ":")
           (opt (group(repeat 1 2 (any num))))
           "-"
           (group (repeat 1 2 (any num))) (opt ":")
           (opt (group(repeat 1 2 (any num)))) (opt ":")
           (opt (group(repeat 1 2 (any num))))
           eos))
  "Regexp to match time range only hh?:[mm?:ss?]-hh?:[mm?:ss?].")

(defvar emfd--time-attributes '(ctime atime mtime cmin amin mmin)
  "Time keywords.")

(defun emfd--build-now-offset-expression (attribute op num unit)
  (concat attribute " " op " $time.now(-"
          (number-to-string
           (* num
              (pcase unit
                ("s" 1)
                ("M" 60)
                ("h" 3600)
                ("d" 86400)
                ("w" 604800)
                ("m" 2592000)
                ("y" 31536000)
                (_ (error "Unknown unit: %s" unit)))))
          ")"))

(defun emfd--build-date-time-expression (attribute timestr)
  "Build date time query expression from string TIMESTR."
  (cond
   ((string-match emfd-now-offset-matcher timestr)
    (let ((op (assoc (match-string 1 timestr) '(("-" . ">=") ("+" . "<="))))
          (num (match-string 2 timestr))
          (unit (match-string 3 timestr)))
      (emfd--build-now-offset-expression attribute (cdr op)
                                         (string-to-number num) unit)))
   ((string-match emfd-now-offset-range-matcher timestr)
    (let ((num1 (match-string 1 timestr))
          (unit1 (match-string 2 timestr))
          (num2 (match-string 3 timestr))
          (unit2 (match-string 4 timestr)))
      (concat
       (emfd--build-now-offset-expression attribute ">="
                                          (string-to-number num1)
                                          (or unit1 unit2))
       " && "
       (emfd--build-now-offset-expression attribute "<="
                                          (string-to-number num2)
                                          unit2))))
   (t (user-error "No implement."))))

(defvar emfd-file-size-matcher
  (rx (seq bos
           (group (any "+" "-"))
           (group (+ num))
           (opt (group (any "t" "g" "m" "k")))
           eos))
  "Regexp to match file size expression.")

(defvar emfd-file-size-range-matcher
  (rx (seq bos
           (group (+ num))
           (opt (group (any "t" "g" "m" "k")))
           "-"
           (group (+ num))
           (opt (group (any "t" "g" "m" "k")))
           eos))
  "Regexp to match file size range expression.")

(defvar emfd-file-size-map '(("k" . 1024)
                             ("m" . 1048576)
                             ("g" . 1073741824)
                             ("t" . 1099511627776))
  "File size map.")

(defun emfd--caculate-file-size (num &optional unit)
  "Return file size string based on NUM and UNIT."
  (number-to-string (* (string-to-number num)
                       (or (cdr (assoc unit emfd-file-size-map)) 1))))

(defun emfd--build-file-size-expression (attribute sizestr)
  "Build file size query expresion from string SIZESTR."
  (cond
   ((string-match emfd-file-size-matcher sizestr)
    (let ((op (assoc (match-string 1 sizestr) '(("-" . "<=") ("+" . ">="))))
          (num (match-string 2 sizestr))
          (unit (match-string 3 sizestr)))
      (concat attribute " " (cdr op) " " (emfd--caculate-file-size num unit))))
   ((string-match emfd-file-size-range-matcher sizestr)
    (let ((num1 (match-string 1 sizestr))
          (unit1 (match-string 2 sizestr))
          (num2 (match-string 3 sizestr))
          (unit2 (match-string 4 sizestr)))
      (concat attribute " >= "
              (emfd--caculate-file-size num1 (or unit1 unit2))
              " && "
              attribute " <= "
              (emfd--caculate-file-size num2 unit2))))))

(defun emfd--is-time-attribute-p (arg)
  (memq arg emfd--time-attributes))

(defun emfd--is-comparison-modifier-p (arg)
  (memq arg '(ignore-case ignore-diacritic)))

(defun emfd--is-combination-operator-p (arg)
  (memq arg '(op-and op-or op-not)))

(defun emfd--build-query (tokens)
  "Build query string from TOKENS."
  (let (token queries)
    (while tokens
      (setq token (pop tokens))
      (push (pcase (car token)
              ('attribute
               (let* ((attr (assoc (intern (cdr token)) emfd-metadata-attribute-keys))
                      (attr-name (cdr attr))
                      (mod (when (emfd--is-comparison-modifier-p (caar tokens))
                             (cdr (pop tokens))))
                      (query-word (if (eq 'value (caar tokens))
                                      (cdr (pop tokens))
                                    (error "A query word is expected."))))
                 (pcase (car attr)
                   ('type
                    (if-let (ct (cl-rassoc
                                 (downcase query-word)
                                 emfd-content-type-alist
                                 :test (lambda (it list) (member it list))))
                        (concat attr-name " ==" mod " " (car ct))
                      (error "Unknown type: %S" query-word)))
                   ('size (emfd--build-file-size-expression attr-name query-word))
                   ((and it (guard (memq it emfd--time-attributes)))
                    (emfd--build-date-time-expression attr-name query-word))
                   (_ (concat attr-name " ==" mod " " query-word)))))
              ((and op (guard (or (memq op '(group-begin group-end))
                                  (emfd--is-combination-operator-p op))))
               (cdr token)))
            queries))
    (string-join (reverse queries) " ")))



(defun emfd (args64)
  (let ((expr (string-trim (base64-decode-string args64))))
    (when (getenv "opt_dry_run")
      (message "[emacs] query options: %s" expr))
    (princ (emfd--build-query (emfd--parse-query expr)))))

(provide 'emfd)

;;; emfd.el ends here

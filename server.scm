;#!/usr/bin/csi -script
(use posix srfi-18 awful html-tags nunican shell json-abnf srfi-1)
(load "../chicken-scheme-mplayer/mplayer-interface.scm")
(enable-ajax #t)

(define-css "/browser.css"
  (lambda ()
    (++ (css-body (++ (line-height 28)
		      (font-family "Verdana")))
	(css-a (color "black"))
	(class "add" (color "green")))))

(define-css "/playlist.css"
  (lambda ()
    (++ (class "player-buttons" (color "green"))
	(class "current" (color "red"))
	(css-body (++ (line-height 28)
		      (font-family "Verdana"))))))

(define (path->id s)
    (string-fold
     (lambda (c o)
       (string-append o (if (or (char=? #\space c) (char=? #\/ c) (char=? #\. c)
				(char=? #\' c) (char=? #\( c) (char=? #\) c))
			    ""
			    (->string c)))) "" s))

(define (read-meta-info path)
  (vector-ref (parser (capture ,(++ "exiftool -json \"" path "\""))) 0))

(define (get-title meta-info)
  (cdar (filter (lambda (e) (string=? (car e) "Title")) meta-info)))

(define *pl* '())
(define *meta-info* '())
(define *pos* 0)
(define *loaded* #f)

(define (add-track pl path)
  (append pl (list path)))

(define (add-meta-info meta-list path)
  (append meta-list (list (read-meta-info path))))

(define (advance-track pos)
  (+ pos 1))

(define (backtrack-track pos)
  (- pos 1))

(define (play-current!)
  (when (not *loaded*)
	(begin (set! *loaded* #t)
	       (mplayer-load (list-ref *pl* *pos*)))))

(define (stop-playback!)
  (when *loaded*
	(begin (mplayer-quit)
	       (set! *loaded* #f))))

(define (go-next!)
  (stop-playback!)
  (set! *pos* (advance-track *pos*))
  (play-current!))

(define (go-previous!)
  (stop-playback!)
  (set! *pos* (backtrack-track *pos*))
  (play-current!))

(define-page (regexp "/path/.*")
  (lambda (path)
    (let ((in-path (substring path 5 (string-length path))))
      (++ (<a> href: (++ "/path"
			 (substring in-path 0
				    (string-index-right
				     (substring in-path 0
						(- (string-length in-path) 1))
				     #\/))
			 "/")
			 "up")
	  (<br>)
	  (<br>)
	  (fold (lambda (e o)
		  (let ((e-path (++ in-path e)))
		    (ajax (path->id e-path) (++ "#" (path->id e-path)) 'click
			  (lambda ()
			    (set! *pl* (add-track *pl* e-path))
			    (set! *meta-info*
				  (add-meta-info *meta-info* e-path)))
			  success: "parent.frames[1].location.reload()")
		    (++ o
			(<a> href: "#self" class: "add"
			     id: (path->id e-path) "add")
			" "
			(<a> href: (++ "/path" e-path "/") e)
			(<br>))))
		""
		(sort (directory in-path) string<)))))
  css: '("/browser.css"))

(define-page "/playlist"
  (lambda ()
    (define (reload) "window.location.reload()")
    (ajax "play" 'play 'click
	  (lambda ()
	    (play-current!))
	  success: (reload))
    (ajax "stop" 'stop 'click
	  (lambda ()
	    (stop-playback!)))
    (ajax "pause" 'pause 'click
	  (lambda ()
	    (mplayer-pause)))
    (ajax "next" 'next 'click
	  (lambda ()
	    (go-next!))
	  success: (reload))
    (ajax "prev" 'prev 'click
	  (lambda ()
	    (go-previous!))
	  success: (reload))
    (++ (<a> href: "#self" class: "player-buttons" id: "play" "play") " "
	(<a> href: "#self" class: "player-buttons" id: "pause" "pause") " "
	(<a> href: "#self" class: "player-buttons" id: "next" "next") " "
	(<a> href: "#self" class: "player-buttons" id: "prev" "prev") " "
	(<a> href: "#self" class: "player-buttons" id: "stop" "stop") " "
	(<br>)
	(<br>)
	(let ((i 0))
	  (fold (lambda (e o)
		  (set! i (+ i 1))
		  (++ o
		      (if (= i (+ *pos* 1))
			  (<span> class: "current"
				  (get-title (list-ref *meta-info* (- i 1))))
			  (get-title (list-ref *meta-info* (- i 1))))
		      (<br>)))
		""
		*pl*))))
  css: '("/playlist.css"))


;(awful-start (lambda () #t) dev-mode: #t port: 8084)
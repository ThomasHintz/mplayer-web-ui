;#!/usr/bin/csi -script
(use posix srfi-18 awful html-tags nunican)
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
	(css-body (++ (line-height 28)
		      (font-family "Verdana"))))))

(define (path->id s)
    (string-fold
     (lambda (c o)
       (string-append o (if (or (char=? #\space c) (char=? #\/ c) (char=? #\. c)
				(char=? #\' c) (char=? #\( c) (char=? #\) c))
			    ""
			    (->string c)))) "" s))

(define *pl* '())

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
			    (set! *pl* (cons e-path *pl*)))
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
    (ajax "play" 'play 'click
	  (lambda ()
	    (mplayer-load (car *pl*))))
    (ajax "stop" 'stop 'click
	  (lambda ()
	    (mplayer-stop)))
    (ajax "pause" 'pause 'click
	  (lambda ()
	    (mplayer-pause)))
    (++ (<a> href: "#self" class: "player-buttons" id: "play" "play") " "
	(<a> href: "#self" class: "player-buttons" id: "pause" "pause") " "
	(<a> href: "#self" class: "player-buttons" id: "next" "next") " "
	(<a> href: "#self" class: "player-buttons" id: "prev" "prev") " "
	(<a> href: "#self" class: "player-buttons" id: "stop" "stop") " "
	(<br>)
	(<br>)
	(fold (lambda (e o)
		(++ o
		    e
		    (<br>)))
	      ""
	      *pl*)))
  css: '("/playlist.css"))


;(awful-start (lambda () #t) dev-mode: #t port: 8084)
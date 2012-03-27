;#!/usr/bin/csi -script
(use posix awful html-tags)

(define (mplayer-load path)
  (let-values
      (((in out pid)
	(process (string-append "mplayer -slave -identify -noquiet -input file=cmds " path))))
    (port-for-each (lambda (v)
		     (if (string=? v "ID_EXIT=QUIT")
			 (process-wait pid)
			 #f))
		   (lambda ()
		     (read-line in)))))

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
		  (++ o
		      (<a> href: (++ "/path" in-path e "/") e)
		      (<br>)))
		""
		(sort (directory in-path) string<))))))

;(awful-start (lambda () #t) dev-mode: #t port: 8084)
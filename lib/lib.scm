(define call/cc call-with-current-continuation)
(define (list . x) x)
(define (cadr x) (car (cdr x)))
(define (caar x) (car (car x)))
(define (cddr x) (cdr (cdr x)))
(define (cdar x) (cdr (car x)))
(define force (lambda (promise) (promise)))
(define make-promise
  (lambda (p)
    (let ((val #f) (set? #f))
      (lambda ()
        (if (not set?)
            (let ((x (p)))
              (if (not set?)
                  (begin (set! val x)
                         (set! set? #t)))))
        val))))
(define-syntax delay
  (syntax-rules ()
    ((_ exp) (make-promise (lambda () exp)))))
(define-syntax letl
  (syntax-rules()
    (
      (_ x ((y z) ...) b ...)
      ((letrec ((x (lambda (y ...) b ...))) x)
         z ...))))
(define (length l)
   (letrec ((aux
             (lambda (l n)
               (if (equal? l '())
                    n
                   (aux (cdr l) (+ n 1))
                )
              )))
              (aux l 0)))
(define (list-tail l n)
  (if (= n 0)
       l
      (list-tail (cdr l) (- n 1))
  ))
(define dynamic-wind #f)
(let ((winders '()))
  (define common-tail
    (lambda (x y)
      (let ((lx (length x)) (ly (length y)))
        (do ((x (if (> lx ly) (list-tail x (- lx ly)) x) (cdr x))
             (y (if (> ly lx) (list-tail y (- ly lx)) y) (cdr y)))
            ((eq? x y) x)))))
  (define do-wind
    (lambda (new)
      (let ((tail (common-tail new winders)))
        (letl f ((l winders))
          (if (not (eq? l tail))
              (begin
                (set! winders (cdr l))
                ((cdar l))
                (f (cdr l)))))
        (letl f ((l new))
          (if (not (eq? l tail))
              (begin
                (f (cdr l))
                ((caar l))
                (set! winders l)))))))
  (set! call/cc
    (let ((c call/cc))
      (lambda (f)
        (c (lambda (k)
             (f (let ((save winders))
                  (lambda (x)
                    (if (not (eq? save winders)) (do-wind save))
                    (k x)))))))))
  (set! call-with-current-continuation call/cc)
  (set! dynamic-wind
    (lambda (in body out)
      (in)
      (set! winders (cons (cons in out) winders))
      (let ((ans (body)))
        (set! winders (cdr winders))
        (out)
        ans)))) 
(define k-scheme-env (current-environment))        

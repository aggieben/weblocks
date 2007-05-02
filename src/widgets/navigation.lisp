
(in-package :weblocks)

(export '(navigation init-navigation make-navigation))

(defclass navigation ()
  ((panes :accessor navigation-panes
	  :initform nil
	  :initarg :panes
	  :documentation "An association list of names and
	  widgets. The names will act as menu entries and attributized
	  names will go into the URL. When a particular entry is
	  clicked, its corresponding pane will be rendered.")
   (current-pane :initform nil
		 :initarg :current-pane
		 :documentation "A name that identifies currently
                  selected entry.")))

(defmethod initialize-instance :after ((obj navigation) &rest initargs &key &allow-other-keys)
  (with-slots (panes current-pane) obj
    (when (null current-pane)
      (setf current-pane (caar panes)))))

(defmethod render ((obj navigation) &rest args)
  (with-slots (panes current-pane) obj
    (with-html
      (when (current-pane-widget obj)
	(render (current-pane-widget obj)))
      (:div :class "renderer menu"
	    (with-extra-tags
	      (if (null panes)
		  (htm
		   (:div :class "empty-menu" "No menu entries"))
		  (htm
		   (:ul
		    (mapc (lambda (item)
			    (htm
			     (:li (render-link
				   (make-action (lambda ()
						  (setf current-pane (car item))))
				   (car item)))))
			  panes)))))))))

(defun current-pane-widget (obj)
  (with-slots (panes current-pane) obj
    (cdar (member current-pane panes :key #'car :test #'string-equal))))

(defun init-navigation (nav &rest args)
  "A helper function to make a navigation widget

ex:

\(init-navigation
   \"test1\" (make-instance ...)
   \"test2\" (make-instance ...)"
  (loop for count from 1
        for x in args
        for y in (cdr args)
     when (oddp count)
     do (push-end `(,x . ,y) (navigation-panes nav)))
  (with-slots (current-pane) nav
    (when (null current-pane)
      (setf current-pane (caar (navigation-panes nav))))))

(defun make-navigation (&rest args)
  "Instantiates 'navigation' widget via 'make-instance' and forwards it
along with 'args' to 'init-navigation'."
  (let ((nav (make-instance 'navigation)))
    (apply #'init-navigation nav args)
    nav))


(in-package :weblocks-test)

;;; test defwidget
(deftest defwidget-1
    (macroexpand-1
     '(defwidget foo (bar)
       ((slot1 :initarg :slot1) (slot2 :initform nil))))
  (defclass foo (bar)
    ((slot1 :initarg :slot1)
     (slot2 :initform nil))
    (:metaclass widget-class))
  t)

(deftest defwidget-2
    (macroexpand-1
     '(defwidget foo ()
       ((slot1 :initarg :slot1) (slot2 :initform nil))))
  (defclass foo (widget)
    ((slot1 :initarg :slot1)
     (slot2 :initform nil))
    (:metaclass widget-class))
  t)

;;; test widget-public-dependencies-aux
(deftest widget-public-dependencies-aux-1
    (weblocks::widget-public-dependencies-aux 'non-existant-widget-name)
  nil)

(deftest widget-public-dependencies-aux-2
    (format nil "~A" (weblocks::widget-public-dependencies-aux 'navigation))
  "(stylesheets/navigation.css)")

;;; test widget-public-dependencies
(deftest widget-public-dependencies-1
    (format nil "~A" (widget-public-dependencies (make-instance 'navigation)))
  "(stylesheets/navigation.css)")

(deftest widget-public-dependencies-2
    (with-request :get nil
      (format nil "~A" (widget-public-dependencies (make-instance 'gridedit :data-class 'employee))))
  "(stylesheets/datagrid.css scripts/datagrid.js stylesheets/gridedit.css)")

(deftest widget-public-dependencies-3
    (with-request :get nil
      (widget-public-dependencies 'test))
  nil)

;;; test render-widget-body
(deftest-html render-widget-body-1
    (render-widget-body (lambda (&rest args)
			  (with-html (:p "blah"))))
  (:p "blah"))

(deftest-html render-widget-body-2
    (render-widget-body "test")
  (:p "test"))

(deftest-html render-widget-body-3
    (render-widget-body "test" :id "foo" :class "bar")
  (:p :id "foo" :class "bar" "test"))

;; helper function
(defun dummy-symbol-function (&rest args)
  (with-html (:p "test")))

(deftest-html render-widget-body-4
    (render-widget-body 'dummy-symbol-function)
  (:p "test"))

;;; test widget-css-classes
(deftest widget-css-classes-1
    (widget-css-classes #'identity)
  "widget function")

(deftest widget-css-classes-2
    (widget-css-classes 'identity)
  "widget function identity")

(deftest widget-css-classes-3
    (widget-css-classes "test")
  "widget string")

(deftest widget-css-classes-4
    (with-request :get nil
      (widget-css-classes (make-instance 'gridedit
					 :data-class 'employee)))
  "widget datagrid gridedit")

;;; test with-widget-header
(deftest-html with-widget-header-1
    (with-request :get nil
      (with-widget-header (make-instance 'dataform :data *joe*)
	(lambda (obj &rest args)
	  (with-html (:p "test")))
	:prewidget-body-fn (lambda (&rest args) (with-html (:p "hello")))
	:postwidget-body-fn (lambda (&rest args) (with-html (:p "world")))))
  (:div :class "widget dataform" :id "widget-123"
	(:p "hello")
	(:p "test")
	(:p "world")))

;;; test widget-name specialization for widgets
(deftest widget-name-1
    (widget-name #'identity)
  nil)

(deftest widget-name-2
    (widget-name "identity")
  nil)

(deftest widget-name-3
    (widget-name 'identity)
  identity)

;;; test widget-args specialization for widgets
(deftest widget-args-1
    (widget-args #'identity)
  nil)

(deftest widget-args-2
    (widget-args "identity")
  nil)

(deftest widget-args-3
    (widget-args 'identity)
  nil)

;;; test composite-widgets specialization for widgets
(deftest composite-widgets-1
    (composite-widgets #'identity)
  nil)

(deftest composite-widgets-2
    (composite-widgets "identity")
  nil)

(deftest composite-widgets-3
    (composite-widgets 'identity)
  nil)

;;; render function as a widget
(deftest-html render-function-1
    (with-request :get nil
      (render-widget (lambda (&rest args)
		       (with-html (:p "blah")))))
  (:div :class "widget function"
	(:p "blah")))

;;; render some other widget without a name
(deftest-html render-widget-1
    (with-request :get nil
      (render-widget (make-instance 'dataform :data *joe*)))
  (:div :class "widget dataform" :id "widget-123"
	#.(data-header-template
	   "abc123"
	   '((:li :class "name" (:span :class "label" "Name:&nbsp;") (:span :class "value" "Joe"))
	     (:li :class "manager" (:span :class "label" "Manager:&nbsp;")
	      (:span :class "value" "Jim"))))))

;;; render some widget with a name
(deftest-html render-widget-2
    (with-request :get nil
      (render-widget (make-instance 'dataform :data *joe* :name "Test Widget")))
  (:div :class "widget dataform" :id "test-widget"
	#.(data-header-template
	   "abc123"
	   '((:li :class "name" (:span :class "label" "Name:&nbsp;") (:span :class "value" "Joe"))
	     (:li :class "manager" (:span :class "label" "Manager:&nbsp;")
	      (:span :class "value" "Jim"))))))

(deftest-html render-widget-3
    (with-request :get nil
      (render-widget (make-instance 'dataform :data *joe*) :inlinep t))
  #.(data-header-template "abc123"
     '((:li :class "name" (:span :class "label" "Name:&nbsp;") (:span :class "value" "Joe"))
       (:li :class "manager" (:span :class "label" "Manager:&nbsp;") (:span :class "value" "Jim")))))

(deftest render-widget-4
    (let ((*weblocks-output-stream* (make-string-output-stream)))
      (declare (special *weblocks-output-stream*))
      (with-request :get nil
	(render-widget (make-instance 'dataform :data *joe*))
	(format nil "~A" weblocks::*page-public-dependencies*)))
  "(stylesheets/dataform.css)")

(deftest render-widget-5
    (with-request :get nil
      (progv '(*weblocks-output-stream*) (list (make-string-output-stream))
	(let ((w (make-instance 'dataform :data *joe*))
	      res1 res2)
	  (setf res1 (widget-rendered-p w))
	  (render-widget w :inlinep t)
	  (setf res2 (widget-rendered-p w))
	  (values res1 res2))))
  nil t)

;;; test mark-dirty
(deftest mark-dirty-1
    (multiple-value-bind (res errors)
	(ignore-errors (mark-dirty (lambda () nil)))
      (values res (null errors)))
  nil nil)

(deftest mark-dirty-2
    (with-request :get nil
      (progv '(*weblocks-output-stream*) (list (make-string-output-stream))
	(let ((weblocks::*dirty-widgets* nil)
	      (w (make-instance 'composite :name "test")))
	  (declare (special weblocks::*dirty-widgets*))
	  (render-widget w)
	  (mark-dirty w)
	  (widget-name (car weblocks::*dirty-widgets*)))))
  "test")

(deftest mark-dirty-3
    (with-request :get nil
      (let ((weblocks::*dirty-widgets* nil)
	    (w (make-instance 'composite :name "test")))
	(declare (special weblocks::*dirty-widgets*))
	(mark-dirty w)
	(widget-name (car weblocks::*dirty-widgets*))))
  nil)

(deftest mark-dirty-4
    (with-request :get nil
      (setf (session-value 'weblocks::root-composite) (create-site-layout))	
      (let ((weblocks::*dirty-widgets* nil))
	(declare (special weblocks::*dirty-widgets*))
	(mark-dirty (make-instance 'composite :name "test"
				   :propagate-dirty '((root-inner test-nav-1 test2 test2-leaf)))
		    :putp t)
	(mapcar #'widget-name weblocks::*dirty-widgets*)))
  nil)

(deftest mark-dirty-5
    (with-request :get nil
      (progv '(*weblocks-output-stream*) (list (make-string-output-stream))
	(setf (session-value 'weblocks::root-composite) (create-site-layout))	
	(let* ((weblocks::*dirty-widgets* nil)
	       (path '((root-inner test-nav-1 test2 test2-leaf)))
	       (w (make-instance 'composite :name "test"
					    :propagate-dirty path)))
	  (declare (special weblocks::*dirty-widgets*))
	  (render-widget w)
	  (render-widget (find-widget-by-path (car path)))
	  (mark-dirty w :putp t)
	  (mapcar #'widget-name weblocks::*dirty-widgets*))))
  (test2-leaf "test"))

(deftest mark-dirty-6
    (with-request :get nil
      (let ((weblocks::*dirty-widgets* nil)
	    (w (make-instance 'composite :name "test")))
	(declare (special weblocks::*dirty-widgets*))
	(setf (widget-rendered-p w) t)
	(widget-name (car weblocks::*dirty-widgets*))))
  nil)

;;; test widget-dirty-p
(deftest widget-dirty-p-1
    (let ((weblocks::*dirty-widgets* nil)
	  (w (make-instance 'composite :name "test")))
      (declare (special weblocks::*dirty-widgets*))
      (widget-dirty-p w))
  nil)

(deftest widget-dirty-p-2
    (with-request :get nil
      (progv '(*weblocks-output-stream*) (list (make-string-output-stream))
	(let ((weblocks::*dirty-widgets* nil)
	      (w (make-instance 'composite :name "test")))
	  (declare (special weblocks::*dirty-widgets*))
	  (render-widget w)
	  (mark-dirty w)
	  (not (null (widget-dirty-p w))))))
  t)

;;; test that (setf slot-value-using-class) method is modified for
;;; widgets to automatically mark them as dirty
(deftest setf-slot-value-using-class-1
    (with-request :get nil
      (progv '(*weblocks-output-stream*) (list (make-string-output-stream))
	(let ((weblocks::*dirty-widgets* nil)
	      (w (make-instance 'dataform)))
	  (declare (special weblocks::*dirty-widgets*))
	  (render-widget w)
	  (setf (slot-value w 'weblocks::ui-state) :form)
	  (widget-name (car weblocks::*dirty-widgets*)))))
  "widget-123")

(deftest setf-slot-value-using-class-2
    (with-request :get nil
      (progv '(*weblocks-output-stream*) (list (make-string-output-stream))
	(let ((weblocks::*dirty-widgets* nil)
	      (w (make-instance 'dataform)))
	  (declare (special weblocks::*dirty-widgets*))
	  (render-widget w)
	  weblocks::*dirty-widgets*)))
  nil)

;;; test find-widget-by-path
(deftest find-widget-by-path-1
    (find-widget-by-path '(hello) nil)
  nil)

(deftest find-widget-by-path-2
    (find-widget-by-path nil 'hello)
  hello)

(deftest find-widget-by-path-3
    (with-request :get nil
      (setf (session-value 'weblocks::root-composite) (create-site-layout))
      (let ((res (find-widget-by-path '(root-inner test-nav-1 test2 test2-leaf))))
	(values (widget-name res)
		(type-of res))))
  test2-leaf composite)

(deftest find-widget-by-path-4
    (with-request :get nil
      (setf (session-value 'weblocks::root-composite) (create-site-layout))
      (find-widget-by-path '(doesnt exist)))
  nil)

;;; test customized widget printing
(deftest widget-printing-1
    (progv '(*package*) (list (find-package :weblocks-test))
      (format nil "~s" (make-instance 'weblocks::navigation)))
  "#<NAVIGATION NIL>")

(deftest widget-printing-2
    (progv '(*package*) (list (find-package :weblocks-test))
      (format nil "~s" (make-instance 'weblocks::dataform :name 'users)))
  "#<DATAFORM USERS>")


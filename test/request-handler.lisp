
(in-package :weblocks-test)

;;; testing handle-client-request
(deftest handle-client-request-0
    (with-request :get nil
      (setf (slot-value *request* 'hunchentoot::script-name) "/hello/world/bar.txt")
      (multiple-value-bind (res err)
	  (ignore-errors
	    (handle-client-request))
	res))
  nil)

(deftest handle-client-request-1
    (with-request :get nil
      (let (weblocks::*webapp-name* result1 result2 result3
				    (weblocks::*render-debug-toolbar* nil))
	;; set up our mini-application with one dataform widget
	(declare (special weblocks::*webapp-name*))
	(defwebapp 'hello)
	(setf (slot-value *request* 'hunchentoot::uri) "/foo/bar")
	(defun init-user-session (comp)
	  (push (make-instance 'dataform :data *joe*) (composite-widgets comp)))
	;; handle the first request (make sure data is drawn)
	(setf result1 (handle-client-request))
	;; unbind init-user-session to make sure root-composite persists
	(fmakunbound 'init-user-session)
	;; fake user clicking on "modify"
	(setf (slot-value *request* 'get-parameters) `((,weblocks::*action-string* . "abc123")))
	;; handle another request, this time AJAX (make sure form is drawn)
	(setf (slot-value *request* 'hunchentoot::headers-in)
	    (cons '("X-Requested-With" . "blah") (slot-value *request* 'hunchentoot::headers-in)))
	(setf result2 (handle-client-request))
	(values (null (session-value "debug-reset-sessions")) result1 result2)))
  t
  #.(with-request-template "~
<div class='widget dataform' id='id-123'>~
<div class='view data employee'>~
<div class='extra-top-1'><!-- empty --></div>~
<div class='extra-top-2'><!-- empty --></div>~
<div class='extra-top-3'><!-- empty --></div>~
<h1><span class='action'>Viewing:&nbsp;</span><span class='object'>Employee</span></h1>~
<ul>~
<li class='name'><span class='label text'>Name:&nbsp;</span><span class='value'>Joe</span></li>~
<li class='manager'><span class='label text'>Manager:&nbsp;</span><span class='value'>Jim</span></li>~
</ul>~
<div class='submit'><a class='modify' ~
                       href='/foo/bar?action=abc123' ~
                       onclick='initiateAction(\"abc123\", \"weblocks-session=1%3ATEST\"); ~
                       return false;'>Modify</a></div>~
<div class='extra-bottom-1'><!-- empty --></div>~
<div class='extra-bottom-2'><!-- empty --></div>~
<div class='extra-bottom-3'><!-- empty --></div>~
</div>~
</div>"
      :widget-stylesheets '("dataform")
      :title "Hello - Bar")
  #.(format nil "{\"widgets\":~
{\"id-123\":~
\"<form class='view form employee' action='' method='post' ~
      onsubmit='initiateFormAction(\\\"abc124\\\", $(this), \\\"weblocks-session=1%3ATEST\\\"); ~
                return false;'>~
<div class='extra-top-1'><!-- empty --></div>~
<div class='extra-top-2'><!-- empty --></div>~
<div class='extra-top-3'><!-- empty --></div>~
<fieldset><h1><span class='action'>Modifying:&nbsp;</span>~
<span class='object'>Employee</span>~
</h1>~
<h2 class='form-fields-title'>Form fields:</h2>~
<ul><li class='name'><label class='input'>~
<span class='slot-name'><span class='extra'>Name:&nbsp;~
<em class='required-slot'>(required)&nbsp;</em></span></span>~
<input type='text' name='name' value='Joe' maxlength='40' />~
</label>~
</li>~
<li class='manager'><label class='input'>~
<span class='slot-name'><span class='extra'>Manager:&nbsp;</span></span>~
<input type='text' name='manager' value='Jim' maxlength='40' />~
</label>~
</li>~
</ul>~
<div class='submit'>~
<input name='submit' type='submit' class='submit' value='Submit' onclick='disableIrrelevantButtons(this);' />~
<input name='cancel' type='submit' class='submit cancel' value='Cancel' ~
onclick='disableIrrelevantButtons(this);' />~
</div>~
<input name='action' type='hidden' value='abc124' />~
</fieldset>~
<div class='extra-bottom-1'><!-- empty --></div>~
<div class='extra-bottom-2'><!-- empty --></div>~
<div class='extra-bottom-3'><!-- empty --></div>~
</form>\"},~
\"on-load\":null}"))

;;; make sure debug toolbar is rendered when appropriate
(deftest handle-client-request-2
    (with-request :get nil
      (let (weblocks::*webapp-name* result1 result2
				    (weblocks::*render-debug-toolbar* t))
	;; set up our mini-application with one dataform widget
	(declare (special weblocks::*webapp-name*))
	(defwebapp 'hello)
	;; note: we need to add debug dependencies manually
	;; here. Normally they would get added by start-weblocks, but
	;; we're not calling start-weblocks here
	(setf *application-dependencies*
	      (append *application-dependencies*
		      (dependencies "debug-toolbar")
		      (list (make-local-dependency :script "weblocks-debug"))))
	(setf (slot-value *request* 'hunchentoot::uri) "/foo/bar")
	(defun init-user-session (comp)
	  (setf (composite-widgets comp) (list (lambda () nil))))
	;; handle the first request (make sure data is drawn)
	(setf result1 (handle-client-request))
	(fmakunbound 'init-user-session)
	(values result1 (not (null (session-value "debug-reset-sessions"))))))
  #.(with-request-template
	    "~
<div class='widget function'>~
</div>" :render-debug-toolbar-p t
:title "Hello - Bar")
  t)

;;; make sure navigation controls are modified by request uri
(deftest handle-client-request-3
    (with-request :get nil
      (let (weblocks::*webapp-name* result
				    (weblocks::*render-debug-toolbar* nil))
	;; set up our mini-application with one navigation widget
	(declare (special weblocks::*webapp-name*))
	(defwebapp 'hello)
	(defun init-user-session (comp)
	  (setf (composite-widgets comp) (list (make-navigation "test-nav"
								"test1" (lambda (&rest args)
									  (with-html (:div "hi1")))
								"test2" (lambda (&rest args)
									  (with-html (:div "hi2")))))))
	;; set the URI
	(setf (slot-value *request* 'hunchentoot::uri) "/test2?action=blah")
	;; handle the request
	(setf result (handle-client-request))
	(fmakunbound 'init-user-session)
	result))
  #.(with-request-template
	    "~
<div class='widget navigation' id='test-nav'>~
<div class='widget function'>~
<div>hi2</div>~
</div>~
<div class='view menu'>~
<div class='extra-top-1'><!-- empty --></div>~
<div class='extra-top-2'><!-- empty --></div>~
<div class='extra-top-3'><!-- empty --></div>~
<h1>Test Nav</h1>~
<ul>~
<li><a href='/'>Test1</a></li>~
<li class='selected-item'><span>Test2</span></li>~
</ul>~
<div class='extra-bottom-1'><!-- empty --></div>~
<div class='extra-bottom-2'><!-- empty --></div>~
<div class='extra-bottom-3'><!-- empty --></div>~
</div>~
</div>"
      :widget-stylesheets '("navigation")
      :title "Hello - Test2"))

(deftest handle-client-request-4
    (with-request :get nil
      (let ((weblocks::*render-debug-toolbar* nil)
	    weblocks::*webapp-name* result1 result2 result3)
	;; set the uri
	(setf (slot-value *request* 'hunchentoot::uri) "/")
	;; make sure we handle cookies
	(setf *session* nil)
	(catch 'hunchentoot::handler-done
	  (handle-client-request))
	(string-downcase (header-out "Location"))))
  "http://nil/?weblocks-session=1%3atest")

(deftest handle-client-request-5
    (with-request :get nil
      (let ((res 0)
	    *on-pre-request* *on-post-request* weblocks::*webapp-name*)
	;; set up our mini-application
	(declare (special weblocks::*webapp-name*))
	(defwebapp 'hello)
	(defun init-user-session (comp) nil)
	;; start the session
	(start-session)
	;; do the test
	(push (lambda ()
		(incf res))
	      (request-hook :application :pre-action))
	(push (lambda ()
		(incf res))
	      (request-hook :application :post-action))
	(handle-client-request)
	;; tear down the application
	(fmakunbound 'init-user-session)
	res))
  2)

(deftest handle-client-request-6
    (with-request :get nil
      (let ((res 0) weblocks::*webapp-name*)
	;; set up our mini-application
	(declare (special weblocks::*webapp-name* *request-hook*))
	(defwebapp 'hello)
	(defun init-user-session (comp) nil)
	;; start the session
	(start-session)
	;; do the test
	(push (lambda ()
		(incf res))
	      (request-hook :session :pre-render))
	(push (lambda ()
		(incf res))
	      (request-hook :session :post-render))
	(handle-client-request)
	;; tear down the application
	(fmakunbound 'init-user-session)
	res))
  2)

(deftest handle-client-request-7
    (with-request :get nil
      (let ((res 0) weblocks::*webapp-name*)
	(declare (special weblocks::*webapp-name* *request-hook*))
	;; start the session
	(start-session)
	;; set up our mini-application
	(defwebapp 'hello)
	(defun init-user-session (comp)
	  (declare (special *request-hook*))
	  (push (lambda ()
		  (incf res))
		(request-hook :request :pre-action))
	  (push (lambda ()
		  (incf res))
		(request-hook :request :post-render)))
	;; do the test
	(handle-client-request)
	;; tear down the application
	(fmakunbound 'init-user-session)
	res))
  2)

(deftest handle-client-request-8
    (with-request :get `(("pure" . true) (,weblocks::*action-string* . "abc123"))
      (let ((res 0) weblocks::*webapp-name*)
	(declare (special weblocks::*webapp-name* *request-hook*))
	;; start the session
	(start-session)
	;; action
	(make-action (lambda (&rest args)
		       (incf res)))
	;; set up our mini-application
	(defwebapp 'hello)
	(defun init-user-session (comp)
	  (declare (special *request-hook))
	  (push (lambda ()
		  (incf res))
		(request-hook :request :pre-action))
	  (push (lambda ()
		  (incf res))
		(request-hook :request :post-render)))
	;; do the test
	(ignore-errors
	  (handle-client-request))
	;; tear down the application
	res))
  1)

(deftest handle-client-request-9
    (with-request :get nil
      (let ((weblocks::*render-debug-toolbar* nil)
            weblocks::*webapp-name* result1)
	;; set up our mini-application with one dataform widget
	(declare (special weblocks::*webapp-name*))
	(defwebapp 'hello)
	(defun init-user-session (comp)
	  (setf (composite-widgets comp)
		(list (lambda ()
			(declare (special *current-page-description*))
			(setf *current-page-description* "Some Page")))))
	;; handle the first request (make sure data is drawn)
	(setf result1 (handle-client-request))
	(fmakunbound 'init-user-session)
	result1))
  #.(with-request-template
	"<div class='widget function'></div>"
      :title "Hello - Some Page"))

(deftest handle-client-request-10
    (with-request :get '(("action" . "abc123"))
      (let ((weblocks::*render-debug-toolbar* nil)
	    weblocks::*webapp-name* (res 0))
	;; set up mini application
	(declare (special weblocks::*webapp-name*  *request-hook*))
	(defwebapp 'hello)
	(start-session)
	;; set the uri
	(setf (slot-value *request* 'hunchentoot::uri) "/")
	;; prepare action
	(make-action (lambda (&rest args)
		       nil)
		     "abc123")
	;; prepare hooks
	(push (lambda ()
		  (incf res))
		(request-hook :session :pre-action))
	(push (lambda ()
		(incf res))
	      (request-hook :session :post-action))
	;; prepare dummy app
	(setf (root-composite) (make-instance 'composite))
	;; make sure we redirect to hide ugly URLs
	(catch 'hunchentoot::handler-done
	  (handle-client-request))
	;; clean up app
	(fmakunbound 'init-user-session)
	;; result
	(values (string-downcase (header-out "Location")) res)))
  "http://nil/?weblocks-session=1%3atest" 2)

(deftest handle-client-request-11
    (with-request :get '(("action" . "abc123"))
      (make-request-ajax)
      (let ((weblocks::*render-debug-toolbar* nil)
	    weblocks::*webapp-name*)
	;; set up mini application
	(declare (special weblocks::*webapp-name*))
	(defwebapp 'hello)
	(start-session)
	;; set the uri
	(setf (slot-value *request* 'hunchentoot::uri) "/")
	;; prepare action
	(make-action (lambda (&rest args)
		       nil)
		     "abc123")
	;; prepare dummy app
	(setf (root-composite) (make-instance 'composite))
	;; make sure we redirect to hide ugly URLs
	(catch 'hunchentoot::handler-done
	  (handle-client-request))
	;; clean up app
	(fmakunbound 'init-user-session)
	;; result
	(header-out "Location")))
  nil)

(deftest handle-client-request-12
    (with-request :get nil
      (let ((weblocks::*render-debug-toolbar* nil)
	    weblocks::*webapp-name*)
	;; set up mini application
	(declare (special weblocks::*webapp-name*))
	(defwebapp 'hello)
	(start-session)
	;; set the uri
	(setf (slot-value *request* 'hunchentoot::uri) "/")
	;; prepare dummy app
	(setf (root-composite) (make-instance 'composite))
	;; make sure we redirect to hide ugly URLs
	(catch 'hunchentoot::handler-done
	  (handle-client-request))
	;; clean up app
	(fmakunbound 'init-user-session)
	;; result
	(header-out "Location")))
  nil)

(defmethod begin-transaction :after (store)
  (declare (special *res*))
  (when (and (eql store *default-store*)
	     (boundp '*res*))
    (incf *res*)))

(defmethod commit-transaction :after (store)
  (declare (special *res*))
  (when (and (eql store *default-store*)
	     (boundp '*res*))
    (incf *res*)))

(defmethod rollback-transaction :after (store)
  (declare (special *res*))
  (when (and (eql store *default-store*)
	     (boundp '*res*))
    (decf *res*)))

(deftest handle-client-request-13
    (with-request :post '(("action" . "abc123"))
      (let ((weblocks::*render-debug-toolbar* nil)
	    weblocks::*webapp-name* (*res* 0))
	;; set up mini application
	(declare (special weblocks::*webapp-name*  *request-hook* *res*))
	(make-request-ajax)
	(defwebapp 'hello)
	(start-session)
	;; set the uri
	(setf (slot-value *request* 'hunchentoot::uri) "/")
	;; prepare action
	(make-action (lambda (&rest args)
		       nil)
		     "abc123")
	;; prepare dummy app
	(setf (root-composite) (make-instance 'composite))
	;; handle the request
	(catch 'hunchentoot::handler-done
	  (handle-client-request))
	;; clean up app
	(fmakunbound 'init-user-session)
	;; result
	*res*))
  2)

(deftest handle-client-request-14
    (with-request :get '(("action" . "abc123"))
      (let ((weblocks::*render-debug-toolbar* nil)
	    weblocks::*webapp-name* (*res* 0))
	;; set up mini application
	(declare (special weblocks::*webapp-name*  *request-hook* *res*))
	(make-request-ajax)
	(defwebapp 'hello)
	(start-session)
	;; set the uri
	(setf (slot-value *request* 'hunchentoot::uri) "/")
	;; prepare action
	(make-action (lambda (&rest args)
		       (error "foo"))
		     "abc123")
	;; prepare dummy app
	(setf (root-composite) (make-instance 'composite))
	;; handle the request
	(catch 'hunchentoot::handler-done
	  (ignore-errors
	    (handle-client-request)))
	;; clean up app
	(fmakunbound 'init-user-session)
	;; result
	*res*))
  0)

;;; test remove-session-from-uri
(deftest remove-session-from-uri-1
    (with-request :get nil
      (weblocks::remove-session-from-uri "/pub/test/blah"))
  "/pub/test/blah")

(deftest remove-session-from-uri-2
    (with-request :get '(("action" . "test"))
      (weblocks::remove-session-from-uri "/pub/test/blah"))
  "/pub/test/blah?action=test")

(deftest remove-session-from-uri-3
    (with-request :get '(("action" . "test") ("weblocks-session" "123"))
      (weblocks::remove-session-from-uri "/pub/test/blah"))
  "/pub/test/blah?action=test")

;;; test remove-action-from-uri
(deftest remove-action-from-uri-1
    (with-request :get '(("action" . "test") ("weblocks-session" . "123"))
      (weblocks::remove-action-from-uri "/pub/test/blah"))
  "/pub/test/blah?weblocks-session=123")

;;; test render-dirty-widgets
(deftest render-dirty-widgets-1
    (with-request :get nil
      (let ((weblocks::*dirty-widgets* (list (make-instance 'composite)
					     (make-instance 'composite :name 'foo-bar)
					     (lambda (&rest args)
					       (with-html (:p "test")))))
	    (*weblocks-output-stream* (make-string-output-stream))
	    (*on-ajax-complete-scripts* (list "testjs")))
	(declare (special weblocks::*dirty-widgets*
			  *weblocks-output-stream* *on-ajax-complete-scripts*))
	(weblocks::render-dirty-widgets)
	(get-output-stream-string *weblocks-output-stream*)))
  #.(format nil "~
{~
\"widgets\":~
{~
\"id-123\":\"\",~
\"foo-bar\":\"\",~
null:\"<p>test</p>\"~
},~
\"on-load\":[\"testjs\"]~
}"))


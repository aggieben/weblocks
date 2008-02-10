
(in-package :weblocks)

(export '(dropdwon dropdown-presentation
	  dropdown-presentation-welcome-name))

;;; Dropdown
(defclass dropdown-presentation (form-presentation choices-presentation-mixin)
  ((welcome-name :initform nil
		 :initarg :welcome-name
		 :accessor dropdown-presentation-welcome-name
		 :documentation "If not null, uses this value to
		 present a welcome message in the form of [Select
		 Welcome-Name] as the first choice. By default uses
		 the view field label.")))

(defmethod render-view-field-value (value (presentation dropdown-presentation)
				    (field form-view-field) (view form-view) widget obj
				    &rest args &key intermediate-values &allow-other-keys)
  (declare (ignore args))
  (multiple-value-bind (intermediate-value intermediate-value-p)
      (form-field-intermediate-value field intermediate-values)
    (render-dropdown (attributize-name (view-field-slot-name field))
		     (obtain-presentation-choices presentation obj)
		     :welcome-name (if value
				       (if (form-view-field-required-p field)
					   nil "None")
				       (or (dropdown-presentation-welcome-name presentation)
					   (view-field-label field)))
		     :selected-value (if intermediate-value-p
					 intermediate-value
					 (when value
					   (attributize-name value))))))

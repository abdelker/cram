;;;
;;; Copyright (c) 2018, Christopher Pollok <cpollok@uni-bremen.de>
;;; All rights reserved.
;;;
;;; Redistribution and use in source and binary forms, with or without
;;; modification, are permitted provided that the following conditions are met:
;;;
;;;     * Redistributions of source code must retain the above copyright
;;;       notice, this list of conditions and the following disclaimer.
;;;     * Redistributions in binary form must reproduce the above copyright
;;;       notice, this list of conditions and the following disclaimer in the
;;;       documentation and/or other materials provided with the distribution.
;;;     * Neither the name of the Institute for Artificial Intelligence/
;;;       Universitaet Bremen nor the names of its contributors may be used to
;;;       endorse or promote products derived from this software without
;;;       specific prior written permission.
;;;
;;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
;;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;;; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
;;; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
;;; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
;;; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
;;; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
;;; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
;;; POSSIBILITY OF SUCH DAMAGE.

(in-package :pr2-em)

(defun get-container-pose-and-transform (name btr-environment)
  (let* ((name-rosified (roslisp-utilities:rosify-underscores-lisp-name name))
         (urdf-pose (get-urdf-link-pose name-rosified btr-environment))
         (pose (cram-tf:ensure-pose-in-frame
                (cl-transforms-stamped:pose->pose-stamped
                 cram-tf:*fixed-frame*
                 0.0
                 urdf-pose)
                cram-tf:*robot-base-frame*
                :use-zero-time t))
         (transform (cram-tf:pose-stamped->transform-stamped pose name-rosified)))
    (list pose transform)))

;; TODO: incorporate DISTANCE property of designator in GET-OBJECT-GRASPING-POSES
(def-fact-group environment-manipulation (desig:action-grounding)

  (<- (desig:action-grounding ?action-designator (open-container ?arm
                                                                 ?gripper-opening
                                                                 ?distance
                                                                 ?left-reach-poses
                                                                 ?right-reach-poses
                                                                 ?left-grasp-poses
                                                                 ?right-grasp-poses
                                                                 (?left-lift-pose)
                                                                 (?right-lift-pose)
                                                                 (?left-2nd-lift-pose)
                                                                 (?right-2nd-lift-pose)
                                                                 ?joint-name
                                                                 ?handle-link
                                                                 ?environment-obj))
    (spec:property ?action-designator (:type :opening))
    (spec:property ?action-designator (:object ?container-designator))
    (spec:property ?container-designator (:type ?container-type))
    (man-int:object-type-subtype :container ?container-type)
    (spec:property ?container-designator (:urdf-name ?container-name))
    (spec:property ?container-designator (:part-of ?btr-environment))
    (-> (spec:property ?action-designator (:arm ?arm))
        (true)
        (man-int:robot-free-hand ?_ ?arm))
    (spec:property ?action-designator (:distance ?distance))
    ;; infer joint information
    ;; joint-name
    (lisp-fun get-container-link ?container-name ?btr-environment ?container-link)
    (lisp-fun get-handle-link ?container-name ?btr-environment ?handle-link-object)
    (lisp-fun cl-urdf:name ?handle-link-object ?handle-link-string)
    (lisp-fun roslisp-utilities:lispify-ros-underscore-name ?handle-link-string :keyword
              ?handle-link)
    (lisp-fun get-connecting-joint ?container-link ?connecting-joint)
    (lisp-fun cl-urdf:name ?connecting-joint ?joint-name)
    ;; environment
    (btr:bullet-world ?world)
    (lisp-fun btr:object ?world ?btr-environment ?environment-obj)
    ;; infer missing information like ?gripper-opening, opening trajectory
    (lisp-fun man-int:get-object-type-gripper-opening ?container-type ?gripper-opening)
    (lisp-fun get-container-pose-and-transform ?container-name ?btr-environment
              (?container-pose ?container-transform))
    (lisp-fun man-int:get-object-grasping-poses ?container-name
              :container-prismatic :left :open ?container-transform ?left-poses)
    (lisp-fun man-int:get-object-grasping-poses ?container-name
              :container-prismatic :right :open ?container-transform ?right-poses)
    (lisp-fun cram-mobile-pick-place-plans::extract-pick-up-manipulation-poses
              ?arm ?left-poses ?right-poses
              (?left-reach-poses ?right-reach-poses
                                 ?left-grasp-poses ?right-grasp-poses
                                 ?left-lift-poses ?right-lift-poses))
     (-> (lisp-pred identity ?left-lift-poses)
        (equal ?left-lift-poses (?left-lift-pose ?left-2nd-lift-pose))
        (equal (NIL NIL) (?left-lift-pose ?left-2nd-lift-pose)))
    (-> (lisp-pred identity ?right-lift-poses)
        (equal ?right-lift-poses (?right-lift-pose ?right-2nd-lift-pose))
        (equal (NIL NIL) (?right-lift-pose ?right-2nd-lift-pose))))

  (<- (desig:action-grounding ?action-designator (open-container2 ?arm
                                                                  ?gripper-opening
                                                                  ?distance
                                                                  ?left-reach-segment
                                                                  ?right-reach-segment
                                                                  ?left-grasp-segment
                                                                  ?right-grasp-segment
                                                                  ?left-open-segment
                                                                  ?right-open-segment
                                                                  ?left-retract-segment
                                                                  ?right-retract-segment
                                                                  ?joint-name
                                                                  ?handle-link
                                                                  ?environment-obj))
    (spec:property ?action-designator (:type :opening2))
    (spec:property ?action-designator (:object ?container-designator))
    (spec:property ?container-designator (:type ?container-type))
    (man-int:object-type-subtype :container ?container-type)
    (spec:property ?container-designator (:urdf-name ?container-name))
    (spec:property ?container-designator (:part-of ?btr-environment))
    (-> (spec:property ?action-designator (:arm ?arm))
        (true)
        (man-int:robot-free-hand ?_ ?arm))
    (spec:property ?action-designator (:distance ?distance))
    ;; infer joint information
    ;; joint-name
    (lisp-fun get-container-link ?container-name ?btr-environment ?container-link)
    (lisp-fun get-handle-link ?container-name ?btr-environment ?handle-link-object)
    (lisp-fun cl-urdf:name ?handle-link-object ?handle-link-string)
    (lisp-fun roslisp-utilities:lispify-ros-underscore-name ?handle-link-string :keyword
              ?handle-link)
    (lisp-fun get-connecting-joint ?container-link ?connecting-joint)
    (lisp-fun cl-urdf:name ?connecting-joint ?joint-name)
    ;; environment
    (btr:bullet-world ?world)
    (lisp-fun btr:object ?world ?btr-environment ?environment-obj)
    ;; infer missing information like ?gripper-opening, opening trajectory
    (lisp-fun man-int:get-object-type-gripper-opening ?container-type ?gripper-opening)
    (equal ?objects (?container-designator))
    (-> (== ?arm :left)
        (and
         (lisp-fun man-int::make-empty-trajectory
                   (:reaching :grasping :opening :retracting)
                   (?right-reach-segment
                    ?right-grasp-segment
                    ?right-open-segment
                    ?right-retract-segment))
         (lisp-fun man-int::get-action-trajectory :opening :left :open
                   ?objects :opening-distance ?distance
                   (?left-reach-segment
                    ?left-grasp-segment
                    ?left-open-segment
                    ?left-retract-segment)))
        (and
         (lisp-fun man-int::make-empty-trajectory
                   (:reaching :grasping :opening :retracting)
                   (?left-reach-segment
                    ?left-grasp-segment
                    ?left-open-segment
                    ?left-retract-segment))
         (lisp-fun man-int::get-action-trajectory :opening :right :open
                   ?objects :opening-distance ?distance
                   (?right-reach-segment
                    ?right-grasp-segment
                    ?right-open-segment
                    ?right-retract-segment)))))

  (<- (desig:action-grounding ?action-designator (close-container2 ?arm
                                                                   ?gripper-opening
                                                                   ?distance
                                                                   ?left-reach-segment
                                                                   ?right-reach-segment
                                                                   ?left-grasp-segment
                                                                   ?right-grasp-segment
                                                                   ?left-close-segment
                                                                   ?right-close-segment
                                                                   ?left-retract-segment
                                                                   ?right-retract-segment
                                                                   ?joint-name
                                                                   ?handle-link
                                                                   ?environment-obj))
    (spec:property ?action-designator (:type :closing2))
    (spec:property ?action-designator (:object ?container-designator))
    (spec:property ?container-designator (:type ?container-type))
    (man-int:object-type-subtype :container ?container-type)
    (spec:property ?container-designator (:urdf-name ?container-name))
    (spec:property ?container-designator (:part-of ?btr-environment))
    (-> (spec:property ?action-designator (:arm ?arm))
        (true)
        (man-int:robot-free-hand ?_ ?arm))
    (spec:property ?action-designator (:distance ?distance))
    ;; infer joint information
    ;; joint-name
    (lisp-fun get-container-link ?container-name ?btr-environment ?container-link)
    (lisp-fun get-handle-link ?container-name ?btr-environment ?handle-link-object)
    (lisp-fun cl-urdf:name ?handle-link-object ?handle-link-string)
    (lisp-fun roslisp-utilities:lispify-ros-underscore-name ?handle-link-string :keyword
              ?handle-link)
    (lisp-fun get-connecting-joint ?container-link ?connecting-joint)
    (lisp-fun cl-urdf:name ?connecting-joint ?joint-name)
    ;; environment
    (btr:bullet-world ?world)
    (lisp-fun btr:object ?world ?btr-environment ?environment-obj)
    ;; infer missing information like ?gripper-opening, closing trajectory
    (lisp-fun man-int:get-object-type-gripper-opening ?container-type ?gripper-opening)
    (equal ?objects (?container-designator))
    (-> (== ?arm :left)
        (and
         (lisp-fun man-int::make-empty-trajectory
                   (:reaching :grasping :closing :retracting)
                   (?right-reach-segment
                    ?right-grasp-segment
                    ?right-close-segment
                    ?right-retract-segment))
         (lisp-fun man-int::get-action-trajectory :closing :left :close
                   ?objects :opening-distance ?distance
                   (?left-reach-segment
                    ?left-grasp-segment
                    ?left-close-segment
                    ?left-retract-segment)))
        (and
         (lisp-fun man-int::make-empty-trajectory
                   (:reaching :grasping :closing :retracting)
                   (?left-reach-segment
                    ?left-grasp-segment
                    ?left-close-segment
                    ?left-retract-segment))
         (lisp-fun man-int::get-action-trajectory :closing :right :close
                   ?objects :opening-distance ?distance
                   (?right-reach-segment
                    ?right-grasp-segment
                    ?right-close-segment
                    ?right-retract-segment)))))
  
  (<- (desig:action-grounding ?action-designator (close-container ?arm
                                                                  ?gripper-opening
                                                                  ?distance
                                                                  ?left-reach-poses
                                                                  ?right-reach-poses
                                                                  ?left-grasp-poses
                                                                  ?right-grasp-poses
                                                                  (?left-lift-pose)
                                                                  (?right-lift-pose)
                                                                  (?left-2nd-lift-pose)
                                                                  (?right-2nd-lift-pose)
                                                                  ?joint-name
                                                                  ?handle-link
                                                                  ?environment-obj))
    (spec:property ?action-designator (:type :closing))
    (spec:property ?action-designator (:object ?container-designator))
    (spec:property ?container-designator (:type ?container-type))
    (man-int:object-type-subtype :container ?container-type)
    (spec:property ?container-designator (:urdf-name ?container-name))
    (spec:property ?container-designator (:part-of ?btr-environment))
    (-> (spec:property ?action-designator (:arm ?arm))
        (true)
        (man-int:robot-free-hand ?_ ?arm))
    (spec:property ?action-designator (:distance ?distance))
    ;; infer joint information
    ;; joint-name
    (lisp-fun get-container-link ?container-name ?btr-environment ?container-link)
    (lisp-fun get-handle-link ?container-name ?btr-environment ?handle-link-object)
    (lisp-fun cl-urdf:name ?handle-link-object ?handle-link-string)
    (lisp-fun roslisp-utilities:lispify-ros-underscore-name ?handle-link-string :keyword
              ?handle-link)
    (lisp-fun get-connecting-joint ?container-link ?connecting-joint)
    (lisp-fun cl-urdf:name ?connecting-joint ?joint-name)
    ;; environment
    (btr:bullet-world ?world)
    (lisp-fun btr:object ?world ?btr-environment ?environment-obj)
    ;; infer missing information like ?gripper-opnening, closing trajectory
    (lisp-fun man-int:get-object-type-gripper-opening ?container-type ?gripper-opening)
    (lisp-fun get-container-pose-and-transform ?container-name ?btr-environment
              (?container-pose ?container-transform))
    (lisp-fun man-int:get-object-grasping-poses ?container-name
              :container-prismatic :left :close ?container-transform ?left-poses)
    (lisp-fun man-int:get-object-grasping-poses ?container-name
              :container-prismatic :right :close ?container-transform ?right-poses)
    (lisp-fun cram-mobile-pick-place-plans::extract-pick-up-manipulation-poses
              ?arm ?left-poses ?right-poses
              (?left-reach-poses ?right-reach-poses
                                 ?left-grasp-poses ?right-grasp-poses
                                 ?left-lift-poses ?right-lift-poses))
    (-> (lisp-pred identity ?left-lift-poses)
        (equal ?left-lift-poses (?left-lift-pose ?left-2nd-lift-pose))
        (equal (NIL NIL) (?left-lift-pose ?left-2nd-lift-pose)))
    (-> (lisp-pred identity ?right-lift-poses)
        (equal ?right-lift-poses (?right-lift-pose ?right-2nd-lift-pose))
        (equal (NIL NIL) (?right-lift-pose ?right-2nd-lift-pose)))))

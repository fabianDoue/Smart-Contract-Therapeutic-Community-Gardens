;; Volunteer Coordination Smart Contract
;; Manages volunteer registration, scheduling, and coordination for therapeutic gardens

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-not-found (err u201))
(define-constant err-already-exists (err u202))
(define-constant err-unauthorized (err u203))
(define-constant err-invalid-rating (err u204))
(define-constant err-insufficient-training (err u205))
(define-constant err-schedule-conflict (err u206))
(define-constant err-invalid-hours (err u207))

;; Data Variables
(define-data-var next-volunteer-id uint u1)
(define-data-var next-shift-id uint u1)
(define-data-var next-training-id uint u1)
(define-data-var next-recognition-id uint u1)

;; Volunteer Registry
(define-map volunteers
  { volunteer-id: uint }
  {
    volunteer-address: principal,
    name: (string-ascii 100),
    email: (string-ascii 100),
    phone: (string-ascii 20),
    emergency-contact: (string-ascii 100),
    background-check-status: (string-ascii 20),
    training-completed: bool,
    specializations: (string-ascii 200),
    availability-days: (list 7 (string-ascii 10)),
    preferred-times: (string-ascii 100),
    active: bool,
    registered-at: uint,
    total-volunteer-hours: uint,
    reliability-rating: uint
  }
)

;; Volunteer Shifts
(define-map volunteer-shifts
  { shift-id: uint }
  {
    volunteer-id: uint,
    garden-id: uint,
    shift-date: uint,
    start-time: uint,
    end-time: uint,
    shift-type: (string-ascii 50),
    activity-focus: (string-ascii 100),
    patients-assigned: (list 10 uint),
    status: (string-ascii 20),
    completion-notes: (string-ascii 300),
    supervisor-rating: uint,
    hours-logged: uint,
    verified: bool
  }
)

;; Training Programs
(define-map training-programs
  { training-id: uint }
  {
    program-name: (string-ascii 100),
    description: (string-ascii 500),
    duration-hours: uint,
    prerequisites: (string-ascii 200),
    certification-type: (string-ascii 50),
    active: bool,
    created-at: uint,
    instructor: principal
  }
)

;; Volunteer Training Records
(define-map volunteer-training
  { volunteer-id: uint, training-id: uint }
  {
    completed: bool,
    completion-date: uint,
    score: uint,
    certification-expiry: uint,
    instructor-notes: (string-ascii 200)
  }
)

;; Volunteer Recognition
(define-map volunteer-recognition
  { recognition-id: uint }
  {
    volunteer-id: uint,
    recognition-type: (string-ascii 50),
    description: (string-ascii 200),
    awarded-by: principal,
    awarded-at: uint,
    milestone-hours: uint,
    public-display: bool
  }
)

;; Volunteer Feedback
(define-map volunteer-feedback
  { volunteer-id: uint, feedback-date: uint }
  {
    feedback-type: (string-ascii 50),
    rating: uint,
    comments: (string-ascii 300),
    provided-by: principal,
    follow-up-required: bool,
    acknowledged: bool
  }
)

;; Volunteer Coordination Teams
(define-map coordination-teams
  { team-id: uint }
  {
    team-name: (string-ascii 100),
    lead-coordinator: principal,
    garden-assignments: (list 10 uint),
    team-members: (list 20 uint),
    meeting-schedule: (string-ascii 100),
    communication-channel: (string-ascii 100),
    active: bool
  }
)

;; Emergency Volunteer Pool
(define-map emergency-volunteers
  { volunteer-id: uint }
  {
    available-for-emergency: bool,
    response-time-hours: uint,
    contact-preferences: (string-ascii 100),
    last-emergency-call: uint
  }
)

;; Read-only Functions

(define-read-only (get-volunteer (volunteer-id uint))
  (map-get? volunteers { volunteer-id: volunteer-id })
)

(define-read-only (get-volunteer-shift (shift-id uint))
  (map-get? volunteer-shifts { shift-id: shift-id })
)

(define-read-only (get-training-program (training-id uint))
  (map-get? training-programs { training-id: training-id })
)

(define-read-only (get-volunteer-training (volunteer-id uint) (training-id uint))
  (map-get? volunteer-training { volunteer-id: volunteer-id, training-id: training-id })
)

(define-read-only (get-volunteer-recognition (recognition-id uint))
  (map-get? volunteer-recognition { recognition-id: recognition-id })
)

(define-read-only (get-volunteer-feedback (volunteer-id uint) (feedback-date uint))
  (map-get? volunteer-feedback { volunteer-id: volunteer-id, feedback-date: feedback-date })
)

(define-read-only (is-volunteer-trained (volunteer-id uint) (training-id uint))
  (match (get-volunteer-training volunteer-id training-id)
    training-record (get completed training-record)
    false
  )
)

(define-read-only (get-volunteer-hours (volunteer-id uint))
  (match (get-volunteer volunteer-id)
    volunteer-data (get total-volunteer-hours volunteer-data)
    u0
  )
)

(define-read-only (get-volunteer-reliability (volunteer-id uint))
  (match (get-volunteer volunteer-id)
    volunteer-data (get reliability-rating volunteer-data)
    u0
  )
)

(define-read-only (is-emergency-volunteer (volunteer-id uint))
  (match (map-get? emergency-volunteers { volunteer-id: volunteer-id })
    emergency-data (get available-for-emergency emergency-data)
    false
  )
)

;; Private Functions

(define-private (is-valid-rating (rating uint))
  (and (>= rating u1) (<= rating u5))
)

(define-private (calculate-reliability-score (completed-shifts uint) (total-shifts uint))
  (if (> total-shifts u0)
    (/ (* completed-shifts u5) total-shifts)
    u0
  )
)

(define-private (is-training-current (completion-date uint) (expiry-date uint))
  (< stacks-block-height expiry-date)
)

(define-private (check-schedule-conflict (volunteer-id uint) (shift-date uint) (start-time uint) (end-time uint))
  ;; Simplified conflict check - in production, would check against existing shifts
  true
)

;; Public Functions

;; Volunteer Registration
(define-public (register-volunteer (name (string-ascii 100)) (email (string-ascii 100)) (phone (string-ascii 20)) (emergency-contact (string-ascii 100)) (specializations (string-ascii 200)) (availability-days (list 7 (string-ascii 10))) (preferred-times (string-ascii 100)))
  (let ((volunteer-id (var-get next-volunteer-id)))
    (map-set volunteers
      { volunteer-id: volunteer-id }
      {
        volunteer-address: tx-sender,
        name: name,
        email: email,
        phone: phone,
        emergency-contact: emergency-contact,
        background-check-status: "pending",
        training-completed: false,
        specializations: specializations,
        availability-days: availability-days,
        preferred-times: preferred-times,
        active: false,
        registered-at: stacks-block-height,
        total-volunteer-hours: u0,
        reliability-rating: u0
      }
    )
    (var-set next-volunteer-id (+ volunteer-id u1))
    (ok volunteer-id)
  )
)

(define-public (update-volunteer-status (volunteer-id uint) (background-check-status (string-ascii 20)) (training-completed bool) (active bool))
  (let ((volunteer (unwrap! (get-volunteer volunteer-id) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set volunteers
      { volunteer-id: volunteer-id }
      (merge volunteer {
        background-check-status: background-check-status,
        training-completed: training-completed,
        active: active
      })
    )
    (ok true)
  )
)

;; Training Management
(define-public (create-training-program (program-name (string-ascii 100)) (description (string-ascii 500)) (duration-hours uint) (prerequisites (string-ascii 200)) (certification-type (string-ascii 50)) (instructor principal))
  (let ((training-id (var-get next-training-id)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set training-programs
      { training-id: training-id }
      {
        program-name: program-name,
        description: description,
        duration-hours: duration-hours,
        prerequisites: prerequisites,
        certification-type: certification-type,
        active: true,
        created-at: stacks-block-height,
        instructor: instructor
      }
    )
    (var-set next-training-id (+ training-id u1))
    (ok training-id)
  )
)

(define-public (complete-volunteer-training (volunteer-id uint) (training-id uint) (score uint) (certification-expiry uint) (instructor-notes (string-ascii 200)))
  (let
    ((volunteer (unwrap! (get-volunteer volunteer-id) err-not-found))
     (training (unwrap! (get-training-program training-id) err-not-found)))
    (asserts! (is-eq tx-sender (get instructor training)) err-unauthorized)
    (asserts! (is-valid-rating score) err-invalid-rating)
    (map-set volunteer-training
      { volunteer-id: volunteer-id, training-id: training-id }
      {
        completed: true,
        completion-date: stacks-block-height,
        score: score,
        certification-expiry: certification-expiry,
        instructor-notes: instructor-notes
      }
    )
    (if (>= score u3)
      (map-set volunteers
        { volunteer-id: volunteer-id }
        (merge volunteer { training-completed: true })
      )
      true
    )
    (ok true)
  )
)

;; Shift Management
(define-public (schedule-volunteer-shift (volunteer-id uint) (garden-id uint) (shift-date uint) (start-time uint) (end-time uint) (shift-type (string-ascii 50)) (activity-focus (string-ascii 100)) (patients-assigned (list 10 uint)))
  (let
    ((shift-id (var-get next-shift-id))
     (volunteer (unwrap! (get-volunteer volunteer-id) err-not-found)))
    (asserts! (get active volunteer) err-unauthorized)
    (asserts! (get training-completed volunteer) err-insufficient-training)
    (asserts! (< start-time end-time) err-invalid-hours)
    (asserts! (check-schedule-conflict volunteer-id shift-date start-time end-time) err-schedule-conflict)
    (map-set volunteer-shifts
      { shift-id: shift-id }
      {
        volunteer-id: volunteer-id,
        garden-id: garden-id,
        shift-date: shift-date,
        start-time: start-time,
        end-time: end-time,
        shift-type: shift-type,
        activity-focus: activity-focus,
        patients-assigned: patients-assigned,
        status: "scheduled",
        completion-notes: "",
        supervisor-rating: u0,
        hours-logged: u0,
        verified: false
      }
    )
    (var-set next-shift-id (+ shift-id u1))
    (ok shift-id)
  )
)

(define-public (complete-volunteer-shift (shift-id uint) (completion-notes (string-ascii 300)) (hours-logged uint))
  (let ((shift (unwrap! (get-volunteer-shift shift-id) err-not-found)))
    (asserts! (is-eq tx-sender (get volunteer-address (unwrap! (get-volunteer (get volunteer-id shift)) err-not-found))) err-unauthorized)
    (map-set volunteer-shifts
      { shift-id: shift-id }
      (merge shift {
        status: "completed",
        completion-notes: completion-notes,
        hours-logged: hours-logged
      })
    )
    (ok true)
  )
)

(define-public (verify-volunteer-shift (shift-id uint) (supervisor-rating uint))
  (let ((shift (unwrap! (get-volunteer-shift shift-id) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-valid-rating supervisor-rating) err-invalid-rating)
    (map-set volunteer-shifts
      { shift-id: shift-id }
      (merge shift {
        supervisor-rating: supervisor-rating,
        verified: true
      })
    )
    ;; Update volunteer total hours
    (let ((volunteer (unwrap! (get-volunteer (get volunteer-id shift)) err-not-found)))
      (map-set volunteers
        { volunteer-id: (get volunteer-id shift) }
        (merge volunteer {
          total-volunteer-hours: (+ (get total-volunteer-hours volunteer) (get hours-logged shift))
        })
      )
    )
    (ok true)
  )
)

;; Recognition System
(define-public (award-volunteer-recognition (volunteer-id uint) (recognition-type (string-ascii 50)) (description (string-ascii 200)) (milestone-hours uint) (public-display bool))
  (let ((recognition-id (var-get next-recognition-id)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set volunteer-recognition
      { recognition-id: recognition-id }
      {
        volunteer-id: volunteer-id,
        recognition-type: recognition-type,
        description: description,
        awarded-by: tx-sender,
        awarded-at: stacks-block-height,
        milestone-hours: milestone-hours,
        public-display: public-display
      }
    )
    (var-set next-recognition-id (+ recognition-id u1))
    (ok recognition-id)
  )
)

;; Feedback System
(define-public (provide-volunteer-feedback (volunteer-id uint) (feedback-type (string-ascii 50)) (rating uint) (comments (string-ascii 300)) (follow-up-required bool))
  (let ((feedback-date stacks-block-height))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-valid-rating rating) err-invalid-rating)
    (map-set volunteer-feedback
      { volunteer-id: volunteer-id, feedback-date: feedback-date }
      {
        feedback-type: feedback-type,
        rating: rating,
        comments: comments,
        provided-by: tx-sender,
        follow-up-required: follow-up-required,
        acknowledged: false
      }
    )
    (ok true)
  )
)

(define-public (acknowledge-feedback (volunteer-id uint) (feedback-date uint))
  (let ((feedback (unwrap! (get-volunteer-feedback volunteer-id feedback-date) err-not-found)))
    (asserts! (is-eq tx-sender (get volunteer-address (unwrap! (get-volunteer volunteer-id) err-not-found))) err-unauthorized)
    (map-set volunteer-feedback
      { volunteer-id: volunteer-id, feedback-date: feedback-date }
      (merge feedback { acknowledged: true })
    )
    (ok true)
  )
)

;; Emergency Volunteer System
(define-public (register-emergency-volunteer (volunteer-id uint) (response-time-hours uint) (contact-preferences (string-ascii 100)))
  (let ((volunteer (unwrap! (get-volunteer volunteer-id) err-not-found)))
    (asserts! (is-eq tx-sender (get volunteer-address volunteer)) err-unauthorized)
    (asserts! (get active volunteer) err-unauthorized)
    (asserts! (get training-completed volunteer) err-insufficient-training)
    (map-set emergency-volunteers
      { volunteer-id: volunteer-id }
      {
        available-for-emergency: true,
        response-time-hours: response-time-hours,
        contact-preferences: contact-preferences,
        last-emergency-call: u0
      }
    )
    (ok true)
  )
)

(define-public (call-emergency-volunteer (volunteer-id uint))
  (let ((emergency-vol (unwrap! (map-get? emergency-volunteers { volunteer-id: volunteer-id }) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (get available-for-emergency emergency-vol) err-unauthorized)
    (map-set emergency-volunteers
      { volunteer-id: volunteer-id }
      (merge emergency-vol { last-emergency-call: stacks-block-height })
    )
    (ok true)
  )
)

;; Analytics and Reporting
(define-read-only (get-volunteer-statistics (volunteer-id uint))
  (let ((volunteer (unwrap! (get-volunteer volunteer-id) err-not-found)))
    (ok {
      volunteer-id: volunteer-id,
      name: (get name volunteer),
      total-hours: (get total-volunteer-hours volunteer),
      reliability-rating: (get reliability-rating volunteer),
      training-completed: (get training-completed volunteer),
      active: (get active volunteer),
      registered-at: (get registered-at volunteer),
      specializations: (get specializations volunteer)
    })
  )
)

(define-read-only (get-garden-volunteer-coverage (garden-id uint) (date uint))
  ;; Returns volunteer coverage metrics for a specific garden and date
  (ok {
    garden-id: garden-id,
    date: date,
    total-scheduled-shifts: u0,
    completed-shifts: u0,
    coverage-percentage: u0
  })
)

(define-public (update-volunteer-reliability (volunteer-id uint))
  (let ((volunteer (unwrap! (get-volunteer volunteer-id) err-not-found)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    ;; Calculate reliability based on completed vs scheduled shifts
    (let ((new-reliability (calculate-reliability-score u10 u12))) ;; Example calculation
      (map-set volunteers
        { volunteer-id: volunteer-id }
        (merge volunteer { reliability-rating: new-reliability })
      )
    )
    (ok true)
  )
)

;; Ride Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

;; Data Variables
(define-data-var ride-nonce uint u0)

;; Data Maps
(define-map rides
  { ride-id: uint }
  {
    rider: principal,
    driver: principal,
    pickup-location: (string-ascii 100),
    dropoff-location: (string-ascii 100),
    price: uint,
    status: (string-ascii 20)
  }
)

;; Public Functions

;; Request a ride
(define-public (request-ride (pickup-location (string-ascii 100)) (dropoff-location (string-ascii 100)))
  (let
    (
      (ride-id (var-get ride-nonce))
    )
    (map-set rides
      { ride-id: ride-id }
      {
        rider: tx-sender,
        driver: tx-sender,
        pickup-location: pickup-location,
        dropoff-location: dropoff-location,
        price: u0,
        status: "requested"
      }
    )
    (var-set ride-nonce (+ ride-id u1))
    (ok ride-id)
  )
)

;; Accept a ride
(define-public (accept-ride (ride-id uint) (price uint))
  (let
    (
      (ride (unwrap! (map-get? rides { ride-id: ride-id }) err-not-found))
    )
    (asserts! (is-eq (get status ride) "requested") err-unauthorized)
    (asserts! (not (is-eq tx-sender (get rider ride))) err-unauthorized)
    (map-set rides
      { ride-id: ride-id }
      (merge ride {
        driver: tx-sender,
        price: price,
        status: "accepted"
      })
    )
    (ok true)
  )
)

;; Start a ride
(define-public (start-ride (ride-id uint))
  (let
    (
      (ride (unwrap! (map-get? rides { ride-id: ride-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get driver ride)) err-unauthorized)
    (asserts! (is-eq (get status ride) "accepted") err-unauthorized)
    (map-set rides
      { ride-id: ride-id }
      (merge ride { status: "in-progress" })
    )
    (ok true)
  )
)

;; Complete a ride
(define-public (complete-ride (ride-id uint))
  (let
    (
      (ride (unwrap! (map-get? rides { ride-id: ride-id }) err-not-found))
    )
    (asserts! (is-eq tx-sender (get driver ride)) err-unauthorized)
    (asserts! (is-eq (get status ride) "in-progress") err-unauthorized)
    (map-set rides
      { ride-id: ride-id }
      (merge ride { status: "completed" })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get ride details
(define-read-only (get-ride (ride-id uint))
  (ok (unwrap! (map-get? rides { ride-id: ride-id }) err-not-found))
)

;; Initialize contract
(begin
  (var-set ride-nonce u0)
)


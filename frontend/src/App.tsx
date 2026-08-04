import { useEffect, useState } from 'react'
import {
  AlertCircle,
  ArrowDownAZ,
  ArrowRight,
  Clock3,
  Database,
  LoaderCircle,
  PackageCheck,
  RefreshCw,
  RotateCcw,
  Server,
} from 'lucide-react'
import './App.css'
import {
  API_URL,
  getHealth,
  getShipments,
  resetShipmentStatuses,
  updateShipmentStatus,
  type HealthResponse,
  type Shipment,
  type ShipmentListResponse,
  type ShipmentSort,
  type ShipmentStatus,
} from './api'

const statusLabels: Record<ShipmentStatus, string> = {
  created: 'Created',
  picked_up: 'Picked up',
  in_transit: 'In transit',
  delivered: 'Delivered',
  failed: 'Failed',
}

const updatedAtFormatter = new Intl.DateTimeFormat(undefined, {
  dateStyle: 'medium',
  timeStyle: 'short',
})

function orderShipments(items: Shipment[], sort: ShipmentSort): Shipment[] {
  if (sort === 'reference') {
    return items
  }

  return [...items].sort(
    (left, right) =>
      Date.parse(right.updated_at) - Date.parse(left.updated_at) ||
      left.reference.localeCompare(right.reference),
  )
}

function App() {
  const apiPort = new URL(API_URL).port || '8000'
  const webPort = window.location.port || '5173'
  const [health, setHealth] = useState<HealthResponse | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [attempt, setAttempt] = useState(0)
  const [shipments, setShipments] = useState<ShipmentListResponse | null>(null)
  const [shipmentsError, setShipmentsError] = useState<string | null>(null)
  const [shipmentsAttempt, setShipmentsAttempt] = useState(0)
  const [shipmentSort, setShipmentSort] = useState<ShipmentSort>('reference')
  const [updatingStatuses, setUpdatingStatuses] = useState<Record<string, ShipmentStatus>>({})
  const [rowErrors, setRowErrors] = useState<Record<string, string>>({})
  const [isResetDialogOpen, setIsResetDialogOpen] = useState(false)
  const [isResetting, setIsResetting] = useState(false)
  const [resetMessage, setResetMessage] = useState<string | null>(null)

  useEffect(() => {
    const controller = new AbortController()

    setHealth(null)
    setError(null)
    getHealth(controller.signal)
      .then(setHealth)
      .catch((requestError: unknown) => {
        if (requestError instanceof DOMException && requestError.name === 'AbortError') {
          return
        }

        setError(requestError instanceof Error ? requestError.message : 'Unable to reach API')
      })

    return () => controller.abort()
  }, [attempt])

  useEffect(() => {
    const controller = new AbortController()

    setShipments(null)
    setShipmentsError(null)
    getShipments(shipmentSort, controller.signal)
      .then(setShipments)
      .catch((requestError: unknown) => {
        if (requestError instanceof DOMException && requestError.name === 'AbortError') {
          return
        }

        setShipmentsError(
          requestError instanceof Error ? requestError.message : 'Unable to load shipments',
        )
      })

    return () => controller.abort()
  }, [shipmentsAttempt, shipmentSort])

  const isChecking = health === null && error === null
  const overallState = error
    ? 'offline'
    : health?.status === 'ok'
      ? 'ready'
      : health
        ? 'degraded'
        : 'checking'

  async function handleStatusUpdate(shipment: Shipment, requestedStatus: ShipmentStatus) {
    setResetMessage(null)
    setUpdatingStatuses((current) => ({
      ...current,
      [shipment.reference]: requestedStatus,
    }))
    setRowErrors((current) => {
      const next = { ...current }
      delete next[shipment.reference]
      return next
    })

    try {
      const updatedShipment = await updateShipmentStatus(shipment.reference, requestedStatus)
      setShipments((current) =>
        current
          ? {
              ...current,
              items: orderShipments(
                current.items.map((item) =>
                  item.reference === updatedShipment.reference ? updatedShipment : item,
                ),
                shipmentSort,
              ),
            }
          : current,
      )
    } catch (requestError) {
      setRowErrors((current) => ({
        ...current,
        [shipment.reference]:
          requestError instanceof Error ? requestError.message : 'Unable to update shipment',
      }))
    } finally {
      setUpdatingStatuses((current) => {
        const next = { ...current }
        delete next[shipment.reference]
        return next
      })
    }
  }

  async function handleResetStatuses() {
    setIsResetting(true)
    setShipmentsError(null)
    setResetMessage(null)

    try {
      const result = await resetShipmentStatuses(shipmentSort)
      setShipments({ items: result.items, total: result.total })
      setRowErrors({})
      setResetMessage(
        result.reset_count === 0
          ? 'All shipment statuses already match the initial data.'
          : `Restored ${result.reset_count} shipment ${result.reset_count === 1 ? 'status' : 'statuses'}.`,
      )
      setIsResetDialogOpen(false)
    } catch (requestError) {
      setShipmentsError(
        requestError instanceof Error ? requestError.message : 'Unable to reset shipment statuses',
      )
      setIsResetDialogOpen(false)
    } finally {
      setIsResetting(false)
    }
  }

  return (
    <div className="app-shell">
      <header className="topbar">
        <div className="brand">
          <span className="brand-mark" aria-hidden="true">
            <PackageCheck size={22} strokeWidth={1.8} />
          </span>
          <div>
            <p className="eyebrow">Operations console</p>
            <h1>Delivery Status Tracker</h1>
          </div>
        </div>
        <div className="environment-badge">
          <span aria-hidden="true" />
          Local
        </div>
      </header>

      <main>
        <section className="readiness" aria-labelledby="readiness-title">
          <header className="section-header">
            <div>
              <p className="eyebrow">System readiness</p>
              <h2 id="readiness-title">Local services</h2>
            </div>
            <button
              className="retry-button"
              type="button"
              onClick={() => setAttempt((current) => current + 1)}
              disabled={isChecking}
            >
              <RefreshCw size={16} aria-hidden="true" />
              Check again
            </button>
          </header>

          <div className="status-grid" aria-live="polite">
            <article className={`status-item status-${overallState}`}>
              <Server size={20} aria-hidden="true" />
              <div>
                <p>FastAPI</p>
                <strong>{error ? 'Unreachable' : health ? 'Connected' : 'Checking'}</strong>
                <span>localhost:{apiPort}</span>
              </div>
            </article>
            <article className={`status-item status-${overallState}`}>
              <Database size={20} aria-hidden="true" />
              <div>
                <p>PostgreSQL 16</p>
                <strong>
                  {error ? 'Unknown' : health?.database === 'up' ? 'Ready' : health ? 'Unavailable' : 'Checking'}
                </strong>
                <span>localhost:5432</span>
              </div>
            </article>
          </div>

          {error && <p className="connection-error">{error}</p>}
        </section>

        <section className="workspace" aria-labelledby="shipments-title">
          <header className="section-header">
            <div>
              <p className="eyebrow">Shipment workspace</p>
              <h2 id="shipments-title">Shipments</h2>
            </div>
            <div className="workspace-summary">
              <span className="phase-label" aria-live="polite">
                {shipments ? `${shipments.total} total` : 'Loading'}
              </span>
              <button
                className="icon-button"
                type="button"
                onClick={() => setShipmentsAttempt((current) => current + 1)}
                disabled={shipments === null && shipmentsError === null}
                aria-label="Refresh shipments"
                title="Refresh shipments"
              >
                <RefreshCw size={16} aria-hidden="true" />
              </button>
            </div>
          </header>

          <div className="workspace-toolbar">
            <div className="sort-control" aria-label="Sort shipments">
              <span>Sort by</span>
              <div className="segmented-control">
                <button
                  type="button"
                  className={shipmentSort === 'reference' ? 'is-active' : ''}
                  onClick={() => setShipmentSort('reference')}
                  aria-pressed={shipmentSort === 'reference'}
                >
                  <ArrowDownAZ size={15} aria-hidden="true" />
                  Reference
                </button>
                <button
                  type="button"
                  className={shipmentSort === 'last_updated' ? 'is-active' : ''}
                  onClick={() => setShipmentSort('last_updated')}
                  aria-pressed={shipmentSort === 'last_updated'}
                >
                  <Clock3 size={15} aria-hidden="true" />
                  Last updated
                </button>
              </div>
            </div>
            <button
              className="reset-button"
              type="button"
              onClick={() => setIsResetDialogOpen(true)}
              disabled={
                shipments === null || isResetting || Object.keys(updatingStatuses).length > 0
              }
            >
              <RotateCcw size={15} aria-hidden="true" />
              Reset statuses
            </button>
          </div>

          {resetMessage && (
            <p className="reset-message" role="status">
              {resetMessage}
            </p>
          )}

          <div className="table-frame">
            {shipmentsError ? (
              <div className="empty-state" role="alert">
                <AlertCircle size={24} aria-hidden="true" />
                <div>
                  <strong>Shipments could not be loaded</strong>
                  <p>{shipmentsError}</p>
                  <button
                    className="inline-button"
                    type="button"
                    onClick={() => setShipmentsAttempt((current) => current + 1)}
                  >
                    <RefreshCw size={15} aria-hidden="true" />
                    Retry
                  </button>
                </div>
              </div>
            ) : shipments === null ? (
              <div className="loading-table" aria-label="Loading shipments" aria-live="polite">
                {[0, 1, 2, 3].map((row) => (
                  <span key={row} className="loading-row" />
                ))}
              </div>
            ) : shipments.items.length === 0 ? (
              <div className="empty-state">
                <Database size={24} aria-hidden="true" />
                <div>
                  <strong>No shipments found</strong>
                  <p>The shipment workspace is ready for data.</p>
                </div>
              </div>
            ) : (
              <div className="table-scroll">
                <table>
                  <thead>
                    <tr>
                      <th scope="col">Reference</th>
                      <th scope="col">Customer</th>
                      <th scope="col">Status</th>
                      <th scope="col">Last updated</th>
                      <th scope="col">Next status</th>
                    </tr>
                  </thead>
                  <tbody>
                    {shipments.items.map((shipment) => {
                      const updatingStatus = updatingStatuses[shipment.reference]

                      return (
                        <tr key={shipment.reference}>
                        <td className="reference-cell">{shipment.reference}</td>
                        <td>{shipment.customer_name}</td>
                        <td>
                          <span className={`status-badge status-badge-${shipment.status}`}>
                            {statusLabels[shipment.status]}
                          </span>
                        </td>
                        <td className="updated-cell">
                          {updatedAtFormatter.format(new Date(shipment.updated_at))}
                        </td>
                        <td>
                          {shipment.allowed_next_statuses.length === 0 ? (
                            <span className="final-status">Final status</span>
                          ) : (
                            <div className="status-action">
                              <div className="action-controls">
                                {shipment.allowed_next_statuses.map((status) => (
                                  <button
                                    className={`update-button ${
                                      status === 'failed' ? 'update-button-danger' : ''
                                    }`}
                                    key={status}
                                    type="button"
                                    onClick={() => void handleStatusUpdate(shipment, status)}
                                    disabled={updatingStatus !== undefined}
                                    aria-describedby={
                                      rowErrors[shipment.reference]
                                        ? `error-${shipment.reference}`
                                        : undefined
                                    }
                                  >
                                    {updatingStatus === status ? (
                                      <LoaderCircle size={15} aria-hidden="true" />
                                    ) : status === 'failed' ? (
                                      <AlertCircle size={15} aria-hidden="true" />
                                    ) : (
                                      <ArrowRight size={15} aria-hidden="true" />
                                    )}
                                    {updatingStatus === status ? 'Updating' : statusLabels[status]}
                                  </button>
                                ))}
                              </div>
                              {rowErrors[shipment.reference] && (
                                <p
                                  className="row-error"
                                  id={`error-${shipment.reference}`}
                                  role="alert"
                                >
                                  {rowErrors[shipment.reference]}
                                </p>
                              )}
                            </div>
                          )}
                        </td>
                        </tr>
                      )
                    })}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </section>
      </main>

      {isResetDialogOpen && (
        <div className="dialog-backdrop" role="presentation">
          <div
            className="confirm-dialog"
            role="dialog"
            aria-modal="true"
            aria-labelledby="reset-dialog-title"
            aria-describedby="reset-dialog-description"
          >
            <span className="dialog-icon" aria-hidden="true">
              <RotateCcw size={20} />
            </span>
            <h2 id="reset-dialog-title">Reset shipment statuses?</h2>
            <p id="reset-dialog-description">
              This restores status values from the initial CSV. References and customer data stay
              unchanged.
            </p>
            <div className="dialog-actions">
              <button
                className="dialog-cancel"
                type="button"
                onClick={() => setIsResetDialogOpen(false)}
                disabled={isResetting}
              >
                Cancel
              </button>
              <button
                className="dialog-confirm"
                type="button"
                onClick={() => void handleResetStatuses()}
                disabled={isResetting}
              >
                {isResetting ? <LoaderCircle size={15} aria-hidden="true" /> : <RotateCcw size={15} aria-hidden="true" />}
                {isResetting ? 'Resetting' : 'Reset statuses'}
              </button>
            </div>
          </div>
        </div>
      )}

      <footer>
        <span>API :{apiPort}</span>
        <span>PostgreSQL :5432</span>
        <span>Web :{webPort}</span>
      </footer>
    </div>
  )
}

export default App

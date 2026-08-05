export type HealthResponse = {
  status: 'ok' | 'unavailable'
  database: 'up' | 'down'
}

export type ShipmentStatus = 'created' | 'picked_up' | 'in_transit' | 'delivered' | 'failed'

export type Shipment = {
  reference: string
  customer_name: string
  status: ShipmentStatus
  allowed_next_statuses: ShipmentStatus[]
  updated_at: string
}

export type ShipmentListResponse = {
  items: Shipment[]
  total: number
}

export type ShipmentResetResponse = ShipmentListResponse & {
  reset_count: number
}

export type ShipmentSort = 'reference' | 'last_updated'

export type ShipmentStatusConflictDetail = {
  code: 'invalid_status_transition'
  message: string
  current_status: ShipmentStatus
  requested_status: ShipmentStatus
  allowed_statuses: ShipmentStatus[]
}

export class ApiError extends Error {
  readonly status: number
  readonly detail: unknown

  constructor(status: number, message: string, detail: unknown = null) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.detail = detail
  }
}

export const API_URL = import.meta.env.VITE_API_URL ?? 'http://localhost:8000'

function isHealthResponse(value: unknown): value is HealthResponse {
  if (typeof value !== 'object' || value === null) {
    return false
  }

  const candidate = value as Record<string, unknown>
  return (
    (candidate.status === 'ok' || candidate.status === 'unavailable') &&
    (candidate.database === 'up' || candidate.database === 'down')
  )
}

export async function getHealth(signal: AbortSignal): Promise<HealthResponse> {
  const response = await fetch(`${API_URL}/api/health`, { signal })

  if (!response.ok && response.status !== 503) {
    throw new Error(`API returned HTTP ${response.status}`)
  }

  const payload: unknown = await response.json()
  if (!isHealthResponse(payload)) {
    throw new Error('API returned an unexpected health response')
  }

  return payload
}

const shipmentStatuses: ShipmentStatus[] = [
  'created',
  'picked_up',
  'in_transit',
  'delivered',
  'failed',
]

function isShipmentStatus(value: unknown): value is ShipmentStatus {
  return typeof value === 'string' && shipmentStatuses.includes(value as ShipmentStatus)
}

function isShipmentStatusConflictDetail(value: unknown): value is ShipmentStatusConflictDetail {
  if (typeof value !== 'object' || value === null) {
    return false
  }

  const candidate = value as Record<string, unknown>
  return (
    candidate.code === 'invalid_status_transition' &&
    typeof candidate.message === 'string' &&
    isShipmentStatus(candidate.current_status) &&
    isShipmentStatus(candidate.requested_status) &&
    Array.isArray(candidate.allowed_statuses) &&
    candidate.allowed_statuses.every(isShipmentStatus)
  )
}

export function isShipmentStatusConflict(
  error: unknown,
): error is ApiError & { detail: ShipmentStatusConflictDetail } {
  return (
    error instanceof ApiError &&
    error.status === 409 &&
    isShipmentStatusConflictDetail(error.detail)
  )
}

function isShipment(value: unknown): value is Shipment {
  if (typeof value !== 'object' || value === null) {
    return false
  }

  const candidate = value as Record<string, unknown>
  return (
    typeof candidate.reference === 'string' &&
    typeof candidate.customer_name === 'string' &&
    isShipmentStatus(candidate.status) &&
    Array.isArray(candidate.allowed_next_statuses) &&
    candidate.allowed_next_statuses.every(isShipmentStatus) &&
    typeof candidate.updated_at === 'string'
  )
}

function isShipmentListResponse(value: unknown): value is ShipmentListResponse {
  if (typeof value !== 'object' || value === null) {
    return false
  }

  const candidate = value as Record<string, unknown>
  return (
    Array.isArray(candidate.items) &&
    candidate.items.every(isShipment) &&
    typeof candidate.total === 'number' &&
    candidate.total === candidate.items.length
  )
}

export async function getShipments(
  sort: ShipmentSort,
  signal?: AbortSignal,
): Promise<ShipmentListResponse> {
  const response = await fetch(`${API_URL}/api/shipments?sort=${sort}`, { signal })

  if (!response.ok) {
    throw new Error(`Unable to load shipments (HTTP ${response.status})`)
  }

  const payload: unknown = await response.json()
  if (!isShipmentListResponse(payload)) {
    throw new Error('API returned an unexpected shipment response')
  }

  return payload
}

function isShipmentResetResponse(value: unknown): value is ShipmentResetResponse {
  return (
    isShipmentListResponse(value) &&
    typeof (value as Record<string, unknown>).reset_count === 'number'
  )
}

async function responseError(response: Response, fallback: string): Promise<ApiError> {
  try {
    const payload: unknown = await response.json()
    if (typeof payload === 'object' && payload !== null) {
      const detail = (payload as Record<string, unknown>).detail
      if (typeof detail === 'object' && detail !== null) {
        const message = (detail as Record<string, unknown>).message
        if (typeof message === 'string') {
          return new ApiError(response.status, message, detail)
        }
      }
    }
  } catch {
    // Fall back to the HTTP status when the response has no readable JSON body.
  }

  return new ApiError(response.status, `${fallback} (HTTP ${response.status})`)
}

export async function updateShipmentStatus(
  reference: string,
  status: ShipmentStatus,
): Promise<Shipment> {
  const response = await fetch(
    `${API_URL}/api/shipments/${encodeURIComponent(reference)}/status`,
    {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ status }),
    },
  )

  if (!response.ok) {
    throw await responseError(response, 'Unable to update shipment')
  }

  const payload: unknown = await response.json()
  if (!isShipment(payload)) {
    throw new Error('API returned an unexpected shipment response')
  }

  return payload
}

export async function resetShipmentStatuses(sort: ShipmentSort): Promise<ShipmentResetResponse> {
  const response = await fetch(`${API_URL}/api/shipments/reset?sort=${sort}`, {
    method: 'POST',
  })

  if (!response.ok) {
    throw await responseError(response, 'Unable to reset shipment statuses')
  }

  const payload: unknown = await response.json()
  if (!isShipmentResetResponse(payload)) {
    throw new Error('API returned an unexpected reset response')
  }

  return payload
}
import { initEventService } from './event'
import { initStatsService } from './stats'
import { initAuthService } from './auth'

export const initServices = (volunteersClass) => ({
  auth: initAuthService(volunteersClass),
  event: initEventService(volunteersClass),
  stats: initStatsService(volunteersClass),
})

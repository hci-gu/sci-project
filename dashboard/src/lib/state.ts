import { atom } from 'jotai'
import {
  format,
  subDays,
  eachMonthOfInterval,
  parse,
  startOfMonth,
  endOfMonth,
  eachDayOfInterval,
} from 'date-fns'

const API_KEY = import.meta.env.VITE_API_KEY || ''

export const usersAtom = atom(async (_) => {
  const response = await fetch('https://sci-api.prod.appadem.in/users', {
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': API_KEY,
    },
  })
  const users = await response.json()

  return users
})

export const userIdAtom = atom<string | null>(null)

export const currentUserAtom = atom(async (get) => {
  const userId = get(userIdAtom)
  if (!userId) {
    return null
  }
  const response = await fetch(
    `https://sci-api.prod.appadem.in/users/${userId}`,
    {
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': API_KEY,
      },
    }
  )
  const user = await response.json()

  return user
})

export const fromDateAtom = atom<Date>(subDays(new Date(), 365 * 5))
export const toDateAtom = atom<Date>(new Date())

export const userEnergyAtom = atom(async (get) => {
  const userId = get(userIdAtom)
  const from = get(fromDateAtom)
  const to = get(toDateAtom)

  if (!userId) {
    return null
  }

  const fromVar = from.toISOString()
  const toVar = to.toISOString()

  const response = await fetch(
    `https://sci-api.prod.appadem.in/energy/${userId}?to=${toVar}&from=${fromVar}&group=month`,
    {
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': API_KEY,
      },
    }
  )
  const energy: { t: string; kcal: number }[] = await response.json()

  if (!Array.isArray(energy)) {
    return []
  }

  const allMonths = eachMonthOfInterval({
    start: from,
    end: to,
  })

  const monthlyEnergy = allMonths.reduce((acc, month) => {
    const monthKey = format(month, 'yyyy-MM')
    acc[monthKey] = 0
    return acc
  }, {} as Record<string, number>)

  energy.forEach((item) => {
    const monthKey = format(new Date(item.t), 'yyyy-MM')
    if (monthKey in monthlyEnergy) {
      monthlyEnergy[monthKey] += item.kcal
    }
  })

  const chartData = Object.entries(monthlyEnergy).map(([month, energy]) => ({
    month,
    energy: Math.round(energy),
  }))

  return chartData
})

export const selectedMonthAtom = atom<string | null>(null)

export const selectedDayAtom = atom<string | null>(null)

export const userDailyEnergyAtom = atom(async (get) => {
  const userId = get(userIdAtom)
  const selectedMonthString = get(selectedMonthAtom)

  if (!userId || !selectedMonthString) {
    return null
  }

  const selectedMonthDate = parse(selectedMonthString, 'yyyy-MM', new Date())
  const from = startOfMonth(selectedMonthDate)
  const to = endOfMonth(selectedMonthDate)

  const fromVar = from.toISOString()
  const toVar = to.toISOString()

  const response = await fetch(
    `https://sci-api.prod.appadem.in/energy/${userId}?to=${toVar}&from=${fromVar}&group=day`,
    {
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': API_KEY,
      },
    }
  )
  const energy: { t: string; kcal: number }[] = await response.json()

  if (!Array.isArray(energy)) {
    return []
  }

  const allDays = eachDayOfInterval({
    start: from,
    end: to,
  })

  const dailyEnergy = allDays.reduce((acc, day) => {
    const dayKey = format(day, 'yyyy-MM-dd')
    acc[dayKey] = 0
    return acc
  }, {} as Record<string, number>)

  energy.forEach((item) => {
    const dayKey = format(new Date(item.t), 'yyyy-MM-dd')
    if (dayKey in dailyEnergy) {
      dailyEnergy[dayKey] += item.kcal
    }
  })

  const chartData = Object.entries(dailyEnergy).map(([day, energy]) => ({
    day,
    energy: Math.round(energy),
  }))

  return chartData
})

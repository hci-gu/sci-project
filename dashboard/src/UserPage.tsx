import { useAtom, useAtomValue, useSetAtom } from 'jotai'
import { useEffect } from 'react'
import { useParams } from 'react-router'
import { DailyEnergyChart } from './components/DailyEnergyChart'
import { EnergyChart } from './components/EnergyChart'
import { DatePicker } from './components/ui/date-picker'
import {
  fromDateAtom,
  selectedMonthAtom,
  toDateAtom,
  userDailyEnergyAtom,
  userEnergyAtom,
  userIdAtom,
} from './lib/state'
import Phone from './components/Phone'

const UserPage = () => {
  const { userId } = useParams()
  const setUserid = useSetAtom(userIdAtom)
  const userEnergy = useAtomValue(userEnergyAtom)
  const [fromDate, setFromDate] = useAtom(fromDateAtom)
  const [toDate, setToDate] = useAtom(toDateAtom)
  const selectedMonth = useAtomValue(selectedMonthAtom)
  const dailyEnergy = useAtomValue(userDailyEnergyAtom)

  useEffect(() => {
    if (userId) {
      setUserid(userId)
    }
  }, [userId, setUserid])

  return (
    <div className="flex flex-col h-screen">
      <div className="flex items-center justify-end gap-4 p-4 border-b">
        <DatePicker date={fromDate} onSelect={(d) => d && setFromDate(d)} />
        <DatePicker date={toDate} onSelect={(d) => d && setToDate(d)} />
      </div>
      <div className="flex flex-1">
        <div className="w-1/2 flex flex-col items-center justify-center p-4">
          <div className="w-full max-w-2xl">
            {userEnergy ? <EnergyChart data={userEnergy} /> : <p>Loading...</p>}
          </div>
          <div className="w-full max-w-2xl">
            <p>Selected month: {selectedMonth}</p>
            {selectedMonth && dailyEnergy ? (
              <DailyEnergyChart data={dailyEnergy} />
            ) : (
              <p>Select a month to see daily data</p>
            )}
          </div>
        </div>
        <div className="w-1/2 flex items-center justify-center">
          <div className="flex-col">
            <Phone selectedMonth={selectedMonth ?? ''} userId={userId} />
          </div>
        </div>
      </div>
    </div>
  )
}

export default UserPage

import { useSetAtom } from 'jotai'
import { Bar, BarChart, CartesianGrid, XAxis } from 'recharts'
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
} from '@/components/ui/chart'
import { selectedMonthAtom } from '@/lib/state'

const chartConfig = {
  energy: {
    label: 'Energy',
    color: 'hsl(var(--chart-1))',
  },
}

export function EnergyChart({
  data,
}: {
  data: { month: string; energy: number }[]
}) {
  const setSelectedMonth = useSetAtom(selectedMonthAtom)

  return (
    <ChartContainer config={chartConfig} className="min-h-64 w-full">
      <BarChart
        accessibilityLayer
        data={data}
        onClick={(d) => d && setSelectedMonth(d.activeLabel as string)}
      >
        <CartesianGrid vertical={false} />
        <XAxis
          dataKey="month"
          tickLine={false}
          tickMargin={10}
          axisLine={false}
        />
        <ChartTooltip content={<ChartTooltipContent />} />
        <Bar dataKey="energy" fill="var(--color-energy)" radius={4} />
      </BarChart>
    </ChartContainer>
  )
}

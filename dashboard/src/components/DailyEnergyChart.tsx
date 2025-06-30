import { Bar, BarChart, CartesianGrid, XAxis } from 'recharts'
import {
  ChartContainer,
  ChartTooltip,
  ChartTooltipContent,
} from '@/components/ui/chart'

const chartConfig = {
  energy: {
    label: 'Energy',
    color: 'hsl(var(--chart-1))',
  },
}

export function DailyEnergyChart({
  data,
}: {
  data: { day: string; energy: number }[]
}) {
  return (
    <ChartContainer config={chartConfig} className="min-h-64 w-full">
      <BarChart accessibilityLayer data={data}>
        <CartesianGrid vertical={false} />
        <XAxis
          dataKey="day"
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

import { Button } from '@/components/ui/button'
import { useAtomValue } from 'jotai'
import { usersAtom } from './lib/state'
import {
  Card,
  CardAction,
  CardFooter,
  CardHeader,
  CardTitle,
} from '@/components/ui/card'
import { Link } from 'react-router'

const User = ({ user }: any) => {
  return (
    <Card className="w-full max-w-sm">
      <CardHeader>
        <CardTitle>{user.email}</CardTitle>
      </CardHeader>
      <CardFooter>
        <CardAction>
          <Link to={`/users/${user.id}`}>
            <Button>Go to user</Button>
          </Link>
        </CardAction>
      </CardFooter>
    </Card>
  )
}

function App() {
  const users = useAtomValue(usersAtom)
  return (
    <div className="flex min-h-svh flex-col items-center justify-center m-16">
      <h1 className="text-2xl font-bold mb-4">Users</h1>
      <div className="w-full grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {users.map((user: any) => (
          <User key={user.id} user={user} />
        ))}
      </div>
    </div>
  )
}

export default App

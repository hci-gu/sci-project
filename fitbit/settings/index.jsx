// const API_URL = 'https://sci-api.prod.appadem.in'
const API_URL = 'http://192.168.0.33:4000'

function mySettings(props) {
  const userId = props.settings.userId

  return (
    <Page>
      <Section
        title={
          <Text bold align="center">
            App settings
          </Text>
        }
      >
        {userId && <TextInput label="User ID" settingsKey="userId" />}
        {userId && (
          <Link
            source={`scimovement://scimovement.appadem.in/auto-login/${userId}`}
          >
            Login to app
          </Link>
        )}
        {userId && (
          <Button
            list
            label="Sign out"
            onClick={() => props.settingsStorage.clear()}
          />
        )}
        {!userId && (
          <Oauth
            settingsKey="auth"
            title="Signin"
            status="Login"
            authorizeUrl={`${API_URL}/users/register`}
            requestTokenUrl={`${API_URL}/auth/token`}
            clientId="11111"
            clientSecret="supersecret"
            scope="profile"
            onAccessToken={async (data) => {
              console.log('onAccessToken', JSON.stringify(data, null, 2))
            }}
            onReturn={async (data) => {
              console.log('onReturn', JSON.stringify(data, null, 2))
              const { userId } = data
              props.settingsStorage.setItem('userId', userId)
            }}
          />
        )}
        {!userId && (
          <TextInput label="Input User ID manually" settingsKey="userId" />
        )}
      </Section>
      <Section
        title={
          <Text bold align="center">
            Watch settings
          </Text>
        }
      >
        <ColorSelect
          label="Background"
          settingsKey="background"
          colors={[
            { color: 'white' },
            { color: 'tomato' },
            { color: 'sandybrown' },
            { color: '#FFD700' },
            { color: '#ADFF2F' },
            { color: 'deepskyblue' },
            { color: 'black' },
          ]}
        />
        <ColorSelect
          label="Text"
          settingsKey="text"
          colors={[
            { color: 'white' },
            { color: 'black' },
            { color: '#d5454f' },
          ]}
        />
      </Section>
      {props.settings.error && (
        <Section>
          <Text>{props.settings.error}</Text>
        </Section>
      )}
    </Page>
  )
}

registerSettingsPage(mySettings)

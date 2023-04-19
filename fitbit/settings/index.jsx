const API_URL = 'https://sci-api.prod.appadem.in'
const APP_URL = 'scimovement://scimovement.appadem.in'
// const API_URL = 'http://192.168.0.33:4000'

function mySettings(props) {
  const userId = props.settings.userId
  
  return (
    <Page>
      <Section
        title={<Text bold align="center">App settings</Text>}>
        {userId && <TextInput
          label="User ID"
          settingsKey="userId" />}
        {userId && <Button
          list
          label="Sign out"
          onClick={() => props.settingsStorage.clear()} />}
        {!userId && <Oauth
          settingsKey="auth"
          title="Signin"
          status="Login"
          authorizeUrl={`${APP_URL}/watch-login`}
          // requestTokenUrl={`${API_URL}/auth/token`}
          clientId="11111"
          clientSecret="supersecret"
          scope="profile"
          onAccessToken={async (data) => {
            console.log('onAccessToken', JSON.stringify(data, null, 2))
          }}
          onReturn={async (data) => {
            console.log('onReturn', JSON.stringify(data, null, 2))
            const { userId } = data
            props.settingsStorage.setItem('userId', userId);
          }}
        />}
        {!userId && <TextInput
          label="Input User ID manually"
          settingsKey="userId" />}
      </Section>
      <Section
        title={<Text bold align="center">Watch settings</Text>}>
        <Select
          label={"Color scheme"}
          settingsKey="colorScheme"
          options={[
            {name:"Dark"},
            {name:"Light"},
            {name:"Dark mono"},
            {name:"Light mono"}
          ]}
        />
      </Section>
      {props.settings.error && <Section>
        <Text>
          {props.settings.error}
        </Text>
      </Section>}
    </Page>
  );
}

registerSettingsPage(mySettings);

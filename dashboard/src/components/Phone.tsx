import frame from '../assets/frame.svg'

const API_KEY = import.meta.env.VITE_API_KEY

function Phone({ userId = '', selectedDay = '' }) {
  const src = `https://hci-gu.github.io/sci-web-deployment/#/forced-login?userId=${userId}&apiKey=${API_KEY}&date=${selectedDay}T00:00:00.000Z`

  console.log(
    `/forced-login?userId=${userId}&apiKey=${API_KEY}&date=${selectedDay}T00:00:00.000Z`
  )

  return (
    <div className="relative min-h-screen">
      {/* Mobile iframe: shown on small screens */}
      <iframe
        className="block md:hidden w-screen h-screen border-none"
        title="App preview"
        src={src}
      ></iframe>

      {/* Desktop phone frame */}
      <div className="hidden md:flex flex-col items-center justify-center min-h-screen">
        <div className="relative w-[360px] h-[756px] mt-24">
          <div className="absolute inset-0 rounded-[51px] overflow-hidden shadow-2xl z-10">
            <iframe
              className="w-full h-full border-none"
              title="App preview"
              src={src}
            ></iframe>
          </div>
          <img
            src={frame}
            alt="Phone frame"
            className="absolute top-0 left-0 z-0"
            style={{
              scale: '1.075 1.03', // Scale width by 1.05 and height by 1.1
            }}
          />
        </div>
      </div>
    </div>
  )
}

export default Phone

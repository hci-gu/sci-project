import express from 'express'
import fs from 'fs'
import { promises as fsp } from 'fs'
import path from 'path'
import { type Request, type Response, type NextFunction } from 'express'

const router = express.Router()

type DfuRelease = {
  version: string
  filename: string
  sizeBytes?: number
  notes?: string
  releasedAt?: string
  downloadUrl?: string
}

const DFU_DIR = process.env.DFU_DIR ?? path.join(process.cwd(), 'dfu')
const DFU_MANIFEST =
  process.env.DFU_MANIFEST ?? path.join(DFU_DIR, 'manifest.json')

const apiKeyMiddleware = (req: Request, res: Response, next: NextFunction) => {
  const apiKey =
    typeof req.headers['x-api-key'] === 'string'
      ? req.headers['x-api-key']
      : undefined
  if (apiKey !== process.env.API_KEY) {
    res.status(403).send('Forbidden')
    return
  }
  next()
}

const parseVersion = (input: string): number[] =>
  input
    .replace(/^v/i, '')
    .split('.')
    .map((part) => Number(part.replace(/[^0-9]/g, '')) || 0)

const compareVersions = (a: string, b: string): number => {
  const aParts = parseVersion(a)
  const bParts = parseVersion(b)
  const maxLen = Math.max(aParts.length, bParts.length)
  for (let i = 0; i < maxLen; i += 1) {
    const aVal = aParts[i] ?? 0
    const bVal = bParts[i] ?? 0
    if (aVal !== bVal) return aVal - bVal
  }
  return 0
}

const loadManifest = async (): Promise<DfuRelease[]> => {
  const raw = await fsp.readFile(DFU_MANIFEST, 'utf8')
  const parsed = JSON.parse(raw)
  if (!Array.isArray(parsed)) return []
  return parsed.filter(
    (item) => item && typeof item.version === 'string'
  ) as DfuRelease[]
}

router.get('/latest', async (_req, res: any) => {
  try {
    const releases = await loadManifest()
    if (releases.length === 0) {
      return res.status(404).json({ error: 'no_release' })
    }

    const sorted = [...releases].sort((a, b) => {
      if (a.releasedAt && b.releasedAt) {
        return (
          new Date(a.releasedAt).getTime() - new Date(b.releasedAt).getTime()
        )
      }
      return compareVersions(a.version, b.version)
    })

    const latest = sorted[sorted.length - 1]
    return res.json({
      version: latest.version,
      sizeBytes: latest.sizeBytes,
      notes: latest.notes,
      releasedAt: latest.releasedAt,
      downloadUrl: latest.downloadUrl,
    })
  } catch (e) {
    console.log('GET /dfu/latest', e)
    return res.sendStatus(500)
  }
})

router.post(
  '/upload',
  apiKeyMiddleware,
  express.raw({
    type: ['application/zip', 'application/octet-stream'],
    limit: '200mb',
  }),
  async (req, res: any) => {
    const version = req.query?.version?.toString()
    if (!version) {
      return res.status(400).json({ error: 'missing_version' })
    }

    const buffer = req.body
    if (!Buffer.isBuffer(buffer) || buffer.length === 0) {
      return res.status(400).json({ error: 'missing_zip_body' })
    }

    const filename =
      req.query?.filename?.toString() ??
      `pinetime-mcuboot-app-dfu-${version}.zip`

    try {
      await fsp.mkdir(DFU_DIR, { recursive: true })
      const safeName = path.basename(filename)
      const filePath = path.join(DFU_DIR, safeName)
      await fsp.writeFile(filePath, buffer)

      let releases: DfuRelease[] = []
      try {
        releases = await loadManifest()
      } catch (_) {
        releases = []
      }

      const existingIndex = releases.findIndex((r) => r.version === version)
      const entry: DfuRelease = {
        version,
        filename: safeName,
        sizeBytes: buffer.length,
        releasedAt: new Date().toISOString(),
      }

      if (existingIndex >= 0) {
        releases[existingIndex] = {
          ...releases[existingIndex],
          ...entry,
        }
      } else {
        releases.push(entry)
      }

      await fsp.writeFile(DFU_MANIFEST, JSON.stringify(releases, null, 2))

      return res.json({ ok: true, version, filename: safeName })
    } catch (e) {
      console.log('POST /dfu/upload', e)
      return res.sendStatus(500)
    }
  }
)

router.get('/download', async (req, res: any) => {
  const version = req.query?.version?.toString()
  if (!version) {
    return res.status(400).json({ error: 'missing_version' })
  }

  try {
    const releases = await loadManifest()
    const match = releases.find((r) => r.version === version)
    if (!match) {
      return res.status(404).json({ error: 'release_not_found' })
    }

    const safeName = path.basename(match.filename)
    const filePath = path.join(DFU_DIR, safeName)

    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ error: 'file_not_found' })
    }

    const stat = await fsp.stat(filePath)
    res.setHeader('Content-Type', 'application/zip')
    res.setHeader('Content-Disposition', `attachment; filename="${safeName}"`)
    res.setHeader('Content-Length', stat.size.toString())

    const stream = fs.createReadStream(filePath)
    stream.on('error', (err) => {
      console.log('GET /dfu/download stream', err)
      res.sendStatus(500)
    })
    stream.pipe(res)
  } catch (e) {
    console.log('GET /dfu/download', e)
    return res.sendStatus(500)
  }
})

export default router

const express = require('express')
const { User, Accel, AccelCount, HeartRate } = require('../../db/models')

const { getEnergy } = require('../../adapters/energy')
const { calculateCounts } = require('../../adapters/counts')

const checkAndSaveCounts = async (userId) => {
  const now = new Date()
  const from = new Date(
    now.getFullYear(),
    now.getMonth(),
    now.getDate(),
    now.getHours(),
    now.getMinutes() - 1
  )
  const to = new Date(
    now.getFullYear(),
    now.getMonth(),
    now.getDate(),
    now.getHours(),
    now.getMinutes() - 1,
    59
  )

  const accelCounts = await AccelCount.find({
    userId,
    from,
    to,
  })

  if (!!accelCounts.length) {
    return
  }

  const [accel, hr] = await Promise.all([
    Accel.find({ userId, from, to }),
    HeartRate.find({ userId, from, to }),
  ])

  if (accel.length < 1800) {
    return
  }
  const counts = await calculateCounts({ accel, hr })
  await AccelCount.save(counts, userId)
}

module.exports = {
  checkAndSaveCounts,
}

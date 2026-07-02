#!/usr/bin/env python3

from __future__ import annotations

import json
import math
import struct
import zipfile
from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path


DOTNET_TICKS_AT_UNIX_EPOCH = 621355968000000000


@dataclass
class SecondSummary:
    offset: int
    recorded: int
    vm_avg_mg: int
    vm_peak_mg: int


def dotnet_ticks_to_iso(value: int) -> str:
    unix_seconds = (value - DOTNET_TICKS_AT_UNIX_EPOCH) / 10_000_000
    return datetime.fromtimestamp(unix_seconds, tz=timezone.utc).isoformat()


def parse_info_text(value: str) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in value.splitlines():
        if ": " not in line:
            continue
        key, parsed = line.split(": ", 1)
        result[key.strip()] = parsed.strip()
    return result


def sign_extend_12bit(value: int) -> int:
    return value - 4096 if value & 0x800 else value


def unpack_activity_payload(payload: bytes) -> list[int]:
    values: list[int] = []
    for index in range(0, len(payload), 3):
        byte1, byte2, byte3 = payload[index : index + 3]
        first = byte1 | ((byte2 & 0x0F) << 8)
        second = ((byte2 >> 4) & 0x0F) | (byte3 << 4)
        values.append(sign_extend_12bit(first))
        values.append(sign_extend_12bit(second))
    return values


def decode_gt3x(source_path: Path) -> dict:
    with zipfile.ZipFile(source_path) as archive:
        info = parse_info_text(archive.read("info.txt").decode("utf-8"))
        calibration = json.loads(archive.read("calibration.json").decode("utf-8"))
        log_data = archive.read("log.bin")

    sample_rate_hz = int(info["Sample Rate"])
    scale_counts_per_g = float(info["Acceleration Scale"])
    start_dt = datetime.fromisoformat(dotnet_ticks_to_iso(int(info["Start Date"])))
    stop_dt = datetime.fromisoformat(dotnet_ticks_to_iso(int(info["Stop Date"])))
    duration_seconds = int((stop_dt - start_dt).total_seconds())

    seconds: dict[int, SecondSummary] = {}
    packet_counts_by_type: dict[int, int] = defaultdict(int)

    offset = 0
    while offset + 9 <= len(log_data) and log_data[offset] == 0x1E:
        packet_type = log_data[offset + 1]
        timestamp = struct.unpack_from("<I", log_data, offset + 2)[0]
        payload_length = struct.unpack_from("<H", log_data, offset + 6)[0]
        payload_start = offset + 8
        payload_end = payload_start + payload_length
        payload = log_data[payload_start:payload_end]
        packet_counts_by_type[packet_type] += 1

        if packet_type == 0 and payload_length == 225:
            values = unpack_activity_payload(payload)
            x_values = values[0::3]
            y_values = values[1::3]
            z_values = values[2::3]

            vm_values_g = [
                max(
                    0.0,
                    math.sqrt(
                        (x / scale_counts_per_g) ** 2
                        + (y / scale_counts_per_g) ** 2
                        + (z / scale_counts_per_g) ** 2
                    )
                    - 1.0,
                )
                for x, y, z in zip(x_values, y_values, z_values)
            ]
            second_offset = timestamp - int(start_dt.timestamp())
            seconds[second_offset] = SecondSummary(
                offset=second_offset,
                recorded=1,
                vm_avg_mg=round(sum(vm_values_g) / len(vm_values_g) * 1000),
                vm_peak_mg=round(max(vm_values_g) * 1000),
            )

        offset = payload_end + 1

    second_rows: list[list[int]] = []
    minute_rows: list[list[int]] = []
    all_vm_avg_mg: list[int] = []
    all_vm_peak_mg: list[int] = []

    for second_offset in range(duration_seconds):
        second = seconds.get(
            second_offset,
            SecondSummary(
                offset=second_offset,
                recorded=0,
                vm_avg_mg=0,
                vm_peak_mg=0,
            ),
        )
        second_rows.append(
            [second.offset, second.recorded, second.vm_avg_mg, second.vm_peak_mg]
        )
        if second.recorded:
            all_vm_avg_mg.append(second.vm_avg_mg)
            all_vm_peak_mg.append(second.vm_peak_mg)

    for minute_offset in range(math.ceil(duration_seconds / 60)):
        chunk = second_rows[minute_offset * 60 : (minute_offset + 1) * 60]
        recorded_seconds = sum(row[1] for row in chunk)
        avg_vm = round(sum(row[2] for row in chunk) / max(len(chunk), 1))
        peak_vm = max((row[3] for row in chunk), default=0)
        minute_rows.append([minute_offset, recorded_seconds, avg_vm, peak_vm])

    return {
        "metadata": {
            "fileName": source_path.name,
            "subjectName": info.get("Subject Name", ""),
            "deviceType": info.get("Device Type", ""),
            "serialNumber": info.get("Serial Number", ""),
            "firmware": info.get("Firmware", ""),
            "sampleRateHz": sample_rate_hz,
            "scaleCountsPerG": scale_counts_per_g,
            "timeZone": info.get("TimeZone", ""),
            "startIso": start_dt.isoformat(),
            "stopIso": stop_dt.isoformat(),
            "durationSeconds": duration_seconds,
            "recordedSeconds": len(seconds),
            "packetCountsByType": packet_counts_by_type,
            "calibration": calibration,
        },
        "overview": {
            "averageVmMg": round(sum(all_vm_avg_mg) / max(len(all_vm_avg_mg), 1)),
            "peakVmMg": max(all_vm_peak_mg, default=0),
            "activeMinutes": sum(1 for row in minute_rows if row[2] > 100),
            "gapMinutes": sum(1 for row in minute_rows if row[1] == 0),
        },
        "minutes": minute_rows,
        "seconds": second_rows,
    }


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    source = root / "data" / "2026-02-24.gt3x"
    destination = root / "src" / "data" / "actigraph_2026_02_24.json"
    destination.parent.mkdir(parents=True, exist_ok=True)
    decoded = decode_gt3x(source)
    destination.write_text(json.dumps(decoded, separators=(",", ":")))
    print(f"Wrote {destination}")


if __name__ == "__main__":
    main()

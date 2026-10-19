<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: sans-serif; font-size: 11px; }
        h1 { font-size: 16px; margin-bottom: 2px; }
        p { margin-top: 0; color: #555; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #ccc; padding: 4px; text-align: left; }
        th { background: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Rekap Absensi</h1>
    <p>Periode {{ $from->format('d M Y') }} – {{ $to->format('d M Y') }}</p>

    <table>
        <thead>
            <tr>
                <th>Nama</th><th>NIP</th><th>Department</th><th>Lokasi</th>
                <th>Hadir</th><th>Telat</th><th>Menit Telat</th><th>Alfa</th>
                <th>Cuti</th><th>Sakit</th><th>Izin</th><th>Dinas</th>
            </tr>
        </thead>
        <tbody>
            @forelse ($employees as $employee)
                <tr>
                    <td>{{ $employee->name }}</td>
                    <td>{{ $employee->nip }}</td>
                    <td>{{ $employee->department?->name }}</td>
                    <td>{{ $employee->workLocation?->name }}</td>
                    <td>{{ $employee->stats['hadir'] }}</td>
                    <td>{{ $employee->stats['telat'] }}</td>
                    <td>{{ $employee->stats['total_menit_telat'] }}</td>
                    <td>{{ $employee->stats['alfa'] }}</td>
                    <td>{{ $employee->stats['cuti'] }}</td>
                    <td>{{ $employee->stats['sakit'] }}</td>
                    <td>{{ $employee->stats['izin'] }}</td>
                    <td>{{ $employee->stats['dinas'] }}</td>
                </tr>
            @empty
                <tr><td colspan="12">Tidak ada data.</td></tr>
            @endforelse
        </tbody>
    </table>
</body>
</html>

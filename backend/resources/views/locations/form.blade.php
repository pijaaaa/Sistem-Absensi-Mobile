@extends('layouts.admin')

@section('title', $location->exists ? 'Ubah Lokasi' : 'Tambah Lokasi')

@push('head')
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
    <link rel="stylesheet" href="https://unpkg.com/leaflet-draw@1.0.4/dist/leaflet.draw.css">
    <style>#map { height: 360px; }</style>
@endpush

@section('content')
<form method="POST"
    action="{{ $location->exists ? route('locations.update', $location) : route('locations.store') }}"
    class="max-w-2xl rounded-xl border bg-white p-6"
    x-data="locationForm({
        mode: '{{ old('mode', $location->mode ?? 'point') }}',
        lat: {{ old('lat', $location->lat ?? -6.2) }},
        lng: {{ old('lng', $location->lng ?? 106.8) }},
        radius: {{ old('radius_m', $location->radius_m ?? 100) }},
        polygon: @js(old('polygon_json', $location->polygon_json ?? []))
    })">
    @csrf
    @if ($location->exists) @method('PUT') @endif

    <x-form-field name="name" label="Nama Lokasi" :value="$location->name" />

    <div class="mb-4">
        <label class="mb-1 block text-sm font-medium">Mode Lokasi</label>
        <select name="mode" x-model="mode" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
            <option value="point">Point + Radius</option>
            <option value="polygon">Polygon</option>
            <option value="off">Tanpa Lokasi (off)</option>
        </select>
        @error('mode') <p class="mt-1 text-xs text-red-500">{{ $message }}</p> @enderror
    </div>

    <div x-show="mode === 'point'" class="grid grid-cols-3 gap-3">
        <div class="mb-4">
            <label class="mb-1 block text-sm font-medium">Latitude</label>
            <input type="number" step="any" name="lat" x-model.number="lat"
                class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
            @error('lat') <p class="mt-1 text-xs text-red-500">{{ $message }}</p> @enderror
        </div>
        <div class="mb-4">
            <label class="mb-1 block text-sm font-medium">Longitude</label>
            <input type="number" step="any" name="lng" x-model.number="lng"
                class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
            @error('lng') <p class="mt-1 text-xs text-red-500">{{ $message }}</p> @enderror
        </div>
        <div class="mb-4">
            <label class="mb-1 block text-sm font-medium">Radius (m)</label>
            <input type="number" name="radius_m" x-model.number="radius"
                class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
            @error('radius_m') <p class="mt-1 text-xs text-red-500">{{ $message }}</p> @enderror
        </div>
    </div>

    <div x-show="mode === 'polygon'" class="mb-4">
        <input type="hidden" name="polygon_json" x-model="polygonJson">
        <p class="mb-1 text-sm text-gray-500">Gambar polygon minimal 3 titik di peta.</p>
        @error('polygon_json') <p class="mb-1 text-xs text-red-500">{{ $message }}</p> @enderror
    </div>

    <div id="map" x-show="mode !== 'off'" class="mb-4 rounded-lg border"></div>

    <div class="flex gap-2">
        <button type="submit" class="rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800">Simpan</button>
        <a href="{{ route('locations.index') }}" class="rounded-lg border px-4 py-2 text-sm">Batal</a>
    </div>
</form>
@endsection

@push('scripts')
    <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
    <script src="https://unpkg.com/leaflet-draw@1.0.4/dist/leaflet.draw.js"></script>
    <script>
        function locationForm(config) {
            return {
                mode: config.mode,
                lat: config.lat,
                lng: config.lng,
                radius: config.radius,
                polygon: config.polygon,
                get polygonJson() { return JSON.stringify(this.polygon || []); },
                init() {
                    const self = this;
                    const map = L.map('map').setView([this.lat, this.lng], 13);
                    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
                        attribution: '&copy; OpenStreetMap'
                    }).addTo(map);

                    let marker = null;
                    let circle = null;
                    const drawLayer = new L.FeatureGroup().addTo(map);
                    const drawControl = new L.Control.Draw({
                        edit: { featureGroup: drawLayer },
                        draw: { polygon: {}, marker: false, polyline: false, circle: false, rectangle: false, circlemarker: false }
                    });
                    map.addControl(drawControl);

                    function redrawPoint() {
                        if (marker) map.removeLayer(marker);
                        if (circle) map.removeLayer(circle);
                        marker = L.marker([self.lat, self.lng]).addTo(map);
                        circle = L.circle([self.lat, self.lng], { radius: self.radius }).addTo(map);
                    }

                    if (self.mode === 'point') {
                        redrawPoint();
                        map.on('click', e => {
                            self.lat = +e.latlng.lat.toFixed(6);
                            self.lng = +e.latlng.lng.toFixed(6);
                            redrawPoint();
                        });
                    }

                    this.$watch('mode', (m) => {
                        if (m === 'point') { drawLayer.clearLayers(); redrawPoint(); }
                        if (m !== 'point') { if (marker) map.removeLayer(marker); if (circle) map.removeLayer(circle); }
                        setTimeout(() => map.invalidateSize(), 100);
                    });
                    this.$watch('lat', redrawPoint);
                    this.$watch('lng', redrawPoint);
                    this.$watch('radius', redrawPoint);

                    map.on(L.Draw.Event.CREATED, e => {
                        drawLayer.clearLayers();
                        drawLayer.addLayer(e.layer);
                        self.polygon = e.layer.getLatLngs()[0].map(p => [+p.lat.toFixed(6), +p.lng.toFixed(6)]);
                    });

                    if (self.mode === 'polygon' && self.polygon.length >= 3) {
                        const poly = L.polygon(self.polygon.map(p => [p[0], p[1]])).addTo(drawLayer);
                        map.fitBounds(poly.getBounds());
                    }
                }
            }
        }
    </script>
@endpush

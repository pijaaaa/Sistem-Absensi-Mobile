@extends('layouts.admin')

@section('title', $location->exists ? 'Ubah Lokasi' : 'Tambah Lokasi')

@push('head')
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css">
     <link rel="stylesheet" href="https://unpkg.com/leaflet-draw@1.0.4/dist/leaflet.draw.css">
     <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
     <script src="https://unpkg.com/leaflet-draw@1.0.4/dist/leaflet.draw.js"></script>
     <style>
         #map { width: 100%; min-height: 360px; height: 360px; position: relative; overflow: hidden; }
         #map.leaflet-container { background: #dbeafe; font: 12px/1.5 sans-serif; }
         #map .leaflet-pane, #map .leaflet-control { position: absolute; }
     </style>
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
            <label for="mode" class="mb-1 block text-sm font-medium">Mode Lokasi</label>
        <select id="mode" name="mode" autocomplete="off" x-model="mode" class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
            <option value="point">Point + Radius</option>
            <option value="polygon">Polygon</option>
            <option value="off">Tanpa Lokasi (off)</option>
        </select>
        @error('mode') <p class="mt-1 text-xs text-red-500">{{ $message }}</p> @enderror
    </div>

    <div x-show="mode === 'point'" class="grid grid-cols-3 gap-3">
        <div class="mb-4">
            <label for="lat" class="mb-1 block text-sm font-medium">Latitude</label>
            <input id="lat" type="number" step="any" name="lat" autocomplete="off" x-model.number="lat"
                class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
            @error('lat') <p class="mt-1 text-xs text-red-500">{{ $message }}</p> @enderror
        </div>
        <div class="mb-4">
            <label for="lng" class="mb-1 block text-sm font-medium">Longitude</label>
            <input id="lng" type="number" step="any" name="lng" autocomplete="off" x-model.number="lng"
                class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
            @error('lng') <p class="mt-1 text-xs text-red-500">{{ $message }}</p> @enderror
        </div>
        <div class="mb-4">
            <label for="radius_m" class="mb-1 block text-sm font-medium">Radius (m)</label>
            <input id="radius_m" type="number" name="radius_m" autocomplete="off" x-model.number="radius"
                class="w-full rounded-lg border border-gray-300 px-3 py-2 text-sm">
            @error('radius_m') <p class="mt-1 text-xs text-red-500">{{ $message }}</p> @enderror
        </div>
    </div>

    <div x-show="mode === 'polygon'" class="mb-4">
        <input type="hidden" name="polygon_json" x-model="polygonJson">
        <p class="mb-1 text-sm text-gray-500">Gambar polygon minimal 3 titik di peta.</p>
        @error('polygon_json') <p class="mb-1 text-xs text-red-500">{{ $message }}</p> @enderror
    </div>

     <div id="map" class="mb-4 rounded-lg border {{ old('mode', $location->mode ?? 'point') === 'off' ? 'hidden' : '' }}" :class="mode === 'off' ? 'hidden' : ''"></div>

    <div class="flex gap-2">
        <button type="submit" class="rounded-lg bg-gray-900 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800">Simpan</button>
        <a href="{{ route('locations.index') }}" class="rounded-lg border px-4 py-2 text-sm">Batal</a>
    </div>
</form>
@endsection

@push('scripts')
     <script>
         document.addEventListener('DOMContentLoaded', () => {
             const form = document.querySelector('[name="polygon_json"]')?.closest('form');
             const element = document.getElementById('map');
             if (!form || !element || typeof L === 'undefined' || element.dataset.initialized === 'true') return;
             element.dataset.initialized = 'true';
             const lat = Number(form.querySelector('[name="lat"]')?.value || -6.2);
             const lng = Number(form.querySelector('[name="lng"]')?.value || 106.8);
             const mode = form.querySelector('[name="mode"]');
             const polygonInput = form.querySelector('[name="polygon_json"]');
             const map = L.map(element).setView([lat, lng], 13);
             L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
                 attribution: '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noopener">OpenStreetMap contributors</a>',
                 maxZoom: 19
             }).addTo(map);
             const layers = new L.FeatureGroup().addTo(map);
             map.addControl(new L.Control.Draw({
                 edit: { featureGroup: layers },
                 draw: { polygon: {}, marker: false, polyline: false, circle: false, rectangle: false, circlemarker: false }
             }));
             map.on(L.Draw.Event.CREATED, event => {
                 layers.clearLayers();
                 layers.addLayer(event.layer);
                 polygonInput.value = JSON.stringify(event.layer.getLatLngs()[0].map(point => [Number(point.lat.toFixed(6)), Number(point.lng.toFixed(6))]));
             });
             setTimeout(() => map.invalidateSize(), 300);
         });

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
                     if (typeof L === 'undefined') {
                         if (!document.getElementById('map').dataset.waiting) {
                             document.getElementById('map').dataset.waiting = 'true';
                             setTimeout(() => this.init(), 1000);
                         }
                         return;
                     }
                     const mapElement = document.getElementById('map');
                     if (!mapElement || mapElement.dataset.initialized === 'true') return;
                     mapElement.dataset.initialized = 'true';
                     const map = L.map(mapElement).setView([this.lat, this.lng], 13);
                     L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
                         attribution: '&copy; <a href="https://www.openstreetmap.org/copyright" target="_blank" rel="noopener">OpenStreetMap contributors</a>',
                         maxZoom: 19,
                         crossOrigin: true
                     }).addTo(map);
                     setTimeout(() => map.invalidateSize(), 150);

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

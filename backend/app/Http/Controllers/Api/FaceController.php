<?php

namespace App\Http\Controllers\Api;

use App\Exceptions\FaceException;
use App\Http\Controllers\Controller;
use App\Models\FaceTemplate;
use App\Services\Face\FaceServiceClient;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FaceController extends Controller
{
    public function __construct(private FaceServiceClient $face) {}

    public function enroll(Request $request): JsonResponse
    {
        $data = $request->validate([
            'photos' => ['nullable', 'array', 'min:1'],
            'photos.*' => ['image', 'max:5120'],
            'embeddings' => ['nullable', 'string', 'max:8000'],
            'model_version' => ['nullable', 'string', 'max:100'],
        ]);

        $employee = $request->user()->employee;

        if (! $employee) {
            return $this->error('Profil karyawan tidak ditemukan.', 422);
        }

        $embeddings = [];
        $modelVersion = $data['model_version'] ?? null;

        if (! empty($data['embeddings'])) {
            $decoded = json_decode($data['embeddings'], true);
            if (is_array($decoded)) {
                foreach ($decoded as $embedding) {
                    if (is_array($embedding) && count($embedding) >= 16) {
                        $embeddings[] = array_map('floatval', $embedding);
                    }
                }
            }
        }

        if (empty($embeddings)) {
            foreach ($request->file('photos', []) as $photo) {
                $result = $this->face->embed($photo->get(), $photo->getClientOriginalName());
                $embeddings[] = $result['embedding'];
                $modelVersion = $result['model_version'];
            }
        }

        if (empty($embeddings)) {
            return $this->error('Tidak ada sampel wajah.', 422);
        }

        DB::transaction(function () use ($employee, $embeddings, $modelVersion) {
            FaceTemplate::where('employee_id', $employee->id)->delete();

            foreach ($embeddings as $embedding) {
                FaceTemplate::create([
                    'employee_id' => $employee->id,
                    'embedding' => $embedding,
                    'model_version' => $modelVersion ?? config('services.face.model_version', 'sface-2021dec+yunet-2023mar'),
                ]);
            }
        });

        return response()->json([
            'success' => true,
            'message' => 'Wajah berhasil didaftarkan.',
            'data' => [
                'count' => count($embeddings),
                'model_version' => $modelVersion,
            ],
        ]);
    }

    public function show(Request $request): JsonResponse
    {
        $templates = $request->user()->employee?->faceTemplates()->get() ?? collect();

        return response()->json([
            'success' => true,
            'message' => 'OK',
            'data' => [
                'model_version' => $templates->first()?->model_version,
                'embeddings' => $templates->pluck('embedding')->values(),
            ],
        ]);
    }

    public function verify(Request $request): JsonResponse
    {
        $request->validate(['photo' => ['required', 'image', 'max:5120']]);

        $employee = $request->user()->employee;

        if (! $employee) {
            return $this->error('Profil karyawan tidak ditemukan.', 422);
        }

        $templates = $employee->faceTemplates()->get();

        if ($templates->isEmpty()) {
            throw new FaceException('no_template', 'Wajah belum terdaftar.', 422);
        }

        $photo = $request->file('photo');
        $bytes = $photo->get();
        $name = $photo->getClientOriginalName();

        $best = null;

        foreach ($templates as $template) {
            $result = $this->face->verify($bytes, $template->embedding, $name);

            if ($best === null || $result['score'] > $best['score']) {
                $best = $result;
            }
        }

        return response()->json([
            'success' => true,
            'message' => 'OK',
            'data' => [
                'score' => $best['score'],
                'threshold' => $best['threshold'],
                'match' => $best['match'],
                'model_version' => $best['model_version'],
            ],
        ]);
    }

    private function error(string $message, int $status): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $message,
            'errors' => (object) [],
        ], $status);
    }
}

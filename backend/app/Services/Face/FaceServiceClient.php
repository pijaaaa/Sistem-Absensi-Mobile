<?php

namespace App\Services\Face;

use App\Exceptions\FaceException;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Http;

class FaceServiceClient
{
    public function __construct(
        private string $url,
        private string $secret,
    ) {}

    /**
     * @return array{model_version: string, embedding: array<int, float>, dimension: int}
     */
    public function embed(string $imageBytes, string $filename = 'photo.jpg'): array
    {
        $response = Http::withHeaders(['x-face-secret' => $this->secret])
            ->timeout(20)
            ->attach('image', $imageBytes, $filename)
            ->post("$this->url/embed");

        return $this->handle($response);
    }

    /**
     * @param  array<int, float>  $embedding
     * @return array{model_version: string, score: float, threshold: float, match: bool}
     */
    public function verify(string $imageBytes, array $embedding, string $filename = 'photo.jpg'): array
    {
        $response = Http::withHeaders(['x-face-secret' => $this->secret])
            ->timeout(20)
            ->attach('image', $imageBytes, $filename)
            ->post("$this->url/verify", [
                'embedding' => json_encode($embedding),
            ]);

        return $this->handle($response);
    }

    /**
     * @return array<string, mixed>
     */
    private function handle(Response $response): array
    {
        if ($response->successful()) {
            return $response->json();
        }

        $detail = $response->json('detail');

        if (in_array($detail, ['no_face', 'multiple_faces'], true)) {
            throw new FaceException($detail, status: 422);
        }

        throw new FaceException('face_service_error', "Face-service error (HTTP {$response->status()}).", 502);
    }
}
